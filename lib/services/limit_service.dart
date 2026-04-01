import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:neznakomets/services/counter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SHA-256 от строки (hex).
String sha256Hash(String input) {
  final digest = sha256.convert(utf8.encode(input));
  return digest.toString();
}

/// Лимит бесплатных сессий в день: Firebase `user_limits/{hashedAndroidId}`,
/// при ошибке сети — SharedPreferences (ключи как раньше).
class LimitService {
  LimitService({FirebaseDatabase? database}) : _dbOverride = database;

  static const String _databaseUrl =
      'https://stranger-522bb-default-rtdb.europe-west1.firebasedatabase.app';

  final FirebaseDatabase? _dbOverride;

  /// Без обращения к Firebase в конструкторе (удобно для тестов без [Firebase.initializeApp]).
  FirebaseDatabase? _databaseOrNull() {
    if (_dbOverride != null) return _dbOverride;
    try {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _databaseUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static const String prefsDateKey = 'daily_sessions_date';
  static const String prefsCountKey = 'daily_sessions_count';

  /// Лимит сессий по тарифу.
  static int limitForPlan(String plan) {
    switch (plan) {
      case 'echo':
        return 10;
      case 'voice':
        return 40;
      case 'ultra':
        return 80;
      default:
        return 3; // free (без подписки)
    }
  }

  // TODO: убрать перед релизом — временно отключает лимит сессий для тестов.
  static const bool _limitBypassForTesting = false;

  String? _cachedHashedId;

  /// Дата YYYY-MM-DD по UTC+3 (Москва).
  String moscowDateKey([DateTime? utcNow]) =>
      CounterService.moscowDateKey(utcNow);

  /// Хеш идентификатора устройства для узла Firebase (только Android).
  Future<String?> _hashedDeviceId() async {
    if (_cachedHashedId != null) return _cachedHashedId;
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android) return null;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final rawId = androidInfo.id;
      _cachedHashedId = sha256Hash(rawId);
      return _cachedHashedId;
    } catch (_) {
      return null;
    }
  }

  DatabaseReference _userLimitRef(FirebaseDatabase db, String hashedId) =>
      db.ref('user_limits/$hashedId');

  static Map<String, Object?> _normalizeMap(Object? raw) {
    if (raw == null || raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }

  static int _readCount(Map<String, Object?> m) {
    final c = m['count'];
    if (c is int) return c;
    if (c is num) return c.toInt();
    return int.tryParse(c?.toString() ?? '') ?? 0;
  }

  static String? _readDate(Map<String, Object?> m) => m['date']?.toString();

  /// Сегодняшний эффективный счётчик по полям [date] / [count] с узла.
  static int _effectiveCountForToday(
    String today,
    String? storedDate,
    int storedCount,
  ) {
    if (storedDate != today) return 0;
    return storedCount;
  }

  // --- Локальный fallback (SharedPreferences) ---

  Future<void> _localEnsureToday(SharedPreferences prefs) async {
    final today = moscowDateKey();
    final stored = prefs.getString(prefsDateKey);
    if (stored != today) {
      await prefs.setString(prefsDateKey, today);
      await prefs.setInt(prefsCountKey, 0);
    }
  }

  Future<bool> _localCanStartSession(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await _localEnsureToday(prefs);
    final count = prefs.getInt(prefsCountKey) ?? 0;
    return count < limit;
  }

  Future<void> _localRecordSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _localEnsureToday(prefs);
    final count = prefs.getInt(prefsCountKey) ?? 0;
    await prefs.setInt(prefsCountKey, count + 1);
  }

  Future<int> _localRemainingToday(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await _localEnsureToday(prefs);
    final count = prefs.getInt(prefsCountKey) ?? 0;
    return (limit - count).clamp(0, limit);
  }

  // --- Firebase ---

  Future<bool> _firebaseCanStartSession(
    FirebaseDatabase db,
    String hashedId,
    int limit,
  ) async {
    final ref = _userLimitRef(db, hashedId);
    final snap = await ref.get();
    final today = moscowDateKey();
    final m = _normalizeMap(snap.value);
    final storedDate = _readDate(m);
    final storedCount = _readCount(m);
    final eff = _effectiveCountForToday(today, storedDate, storedCount);
    return eff < limit;
  }

  Future<void> _firebaseRecordSession(
    FirebaseDatabase db,
    String hashedId,
    int limit,
  ) async {
    final ref = _userLimitRef(db, hashedId);
    await ref.runTransaction((Object? current) {
      final today = moscowDateKey();
      final m = _normalizeMap(current);
      var count = _readCount(m);
      final storedDate = _readDate(m);

      if (storedDate != today) {
        return Transaction.success(<String, Object?>{
          'date': today,
          'count': 1,
        });
      }
      if (count >= limit) {
        return Transaction.success(<String, Object?>{
          'date': today,
          'count': count,
        });
      }
      count += 1;
      return Transaction.success(<String, Object?>{
        'date': today,
        'count': count,
      });
    });
  }

  Future<int> _firebaseRemainingToday(
    FirebaseDatabase db,
    String hashedId,
    int limit,
  ) async {
    final ref = _userLimitRef(db, hashedId);
    final snap = await ref.get();
    final today = moscowDateKey();
    final m = _normalizeMap(snap.value);
    final storedDate = _readDate(m);
    final storedCount = _readCount(m);
    final eff = _effectiveCountForToday(today, storedDate, storedCount);
    return (limit - eff).clamp(0, limit);
  }

  /// Можно ли начать новую сессию по тарифу [plan].
  Future<bool> canStartSession({String plan = 'free'}) async {
    if (_limitBypassForTesting) return true;
    final limit = limitForPlan(plan);
    try {
      final db = _databaseOrNull();
      final hid = await _hashedDeviceId();
      if (db == null || hid == null) return _localCanStartSession(limit);
      return await _firebaseCanStartSession(db, hid, limit);
    } catch (_) {
      return _localCanStartSession(limit);
    }
  }

  /// Учесть одну сессию (после успешной проверки лимита).
  Future<void> recordSession({String plan = 'free'}) async {
    final limit = limitForPlan(plan);
    try {
      final db = _databaseOrNull();
      final hid = await _hashedDeviceId();
      if (db == null || hid == null) {
        await _localRecordSession();
        return;
      }
      await _firebaseRecordSession(db, hid, limit);
    } catch (_) {
      await _localRecordSession();
    }
  }

  /// Сколько сессий осталось сегодня по тарифу [plan].
  Future<int> remainingToday({String plan = 'free'}) async {
    if (_limitBypassForTesting) return 99;
    final limit = limitForPlan(plan);
    try {
      final db = _databaseOrNull();
      final hid = await _hashedDeviceId();
      if (db == null || hid == null) return _localRemainingToday(limit);
      return await _firebaseRemainingToday(db, hid, limit);
    } catch (_) {
      return _localRemainingToday(limit);
    }
  }
}
