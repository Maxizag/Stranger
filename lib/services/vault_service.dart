import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:neznakomets/models/message.dart';
import 'package:neznakomets/models/vault_session.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

/// Сейф: PIN (SHA-256), PBKDF2 → AES-256-GCM, flutter_secure_storage.
class VaultService {
  VaultService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ?? _defaultStorage,
        _localAuth = localAuth ?? LocalAuthentication();

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _pinHashKey = 'vault_pin_hash';
  static const String _sessionsIndexKey = 'vault_sessions_index';
  static const String _sessionKeyPrefix = 'vault_session_';

  static const int _pbkdf2Iterations = 100000;
  static const String _pbkdf2Salt = 'neznakomets_salt_v1';
  static const int _gcmIvLength = 12;
  static const int _gcmMacBits = 128;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final Uuid _uuid = const Uuid();

  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  static String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Uint8List _deriveAesKey(String pin) {
    final salt = Uint8List.fromList(utf8.encode(_pbkdf2Salt));
    final pinBytes = Uint8List.fromList(utf8.encode(pin));
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, _pbkdf2Iterations, 32));
    return derivator.process(pinBytes);
  }

  Uint8List _aesGcmEncrypt(Uint8List key, Uint8List iv, Uint8List plain) {
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(key), _gcmMacBits, iv, Uint8List(0));
    cipher.init(true, params);
    return cipher.process(plain);
  }

  Uint8List _aesGcmDecrypt(Uint8List key, Uint8List iv, Uint8List cipherPlusMac) {
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(key), _gcmMacBits, iv, Uint8List(0));
    cipher.init(false, params);
    return cipher.process(cipherPlusMac);
  }

  void _randomBytes(Uint8List out) {
    final r = Random.secure();
    for (var i = 0; i < out.length; i++) {
      out[i] = r.nextInt(256);
    }
  }

  bool isLocked() {
    final until = _lockedUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _lockedUntil = null;
    return false;
  }

  int lockRemainingSeconds() {
    if (!isLocked()) return 0;
    final until = _lockedUntil!;
    final s = until.difference(DateTime.now()).inSeconds;
    return s > 0 ? s : 0;
  }

  int get failedAttempts => _failedAttempts;

  Future<bool> hasPIN() async {
    final h = await _storage.read(key: _pinHashKey);
    return h != null && h.isNotEmpty;
  }

  Future<void> setPIN(String pin) async {
    await _storage.write(key: _pinHashKey, value: _sha256Hex(pin));
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  Future<bool> verifyPIN(String pin) async {
    if (isLocked()) return false;
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null || stored.isEmpty) return false;
    final ok = stored == _sha256Hex(pin);
    if (ok) {
      _failedAttempts = 0;
      _lockedUntil = null;
      return true;
    }
    _failedAttempts++;
    if (_failedAttempts >= 10) {
      _lockedUntil = DateTime.now().add(const Duration(hours: 24));
    } else if (_failedAttempts >= 5) {
      _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
    }
    return false;
  }

  /// Проверка PIN без учёта счётчика (сохранение в сейф из чата).
  Future<bool> pinMatches(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null || stored.isEmpty) return false;
    return stored == _sha256Hex(pin);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final can = await _localAuth.canCheckBiometrics;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return can && enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return _localAuth.authenticate(
        localizedReason: 'Войдите в сейф',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<List<VaultSession>> loadSessionsMetadata() async {
    final raw = await _storage.read(key: _sessionsIndexKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => VaultSession.fromIndexJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  /// После проверки PIN — загрузить метаданные (то же, что индекс).
  Future<List<VaultSession>> loadSessions(String pin) async {
    if (!await pinMatches(pin)) {
      throw StateError('Неверный PIN');
    }
    return loadSessionsMetadata();
  }

  String _titleFromMessages(List<Message> messages) {
    for (final m in messages) {
      final t = m.text.trim();
      if (t.isEmpty) continue;
      if (t.length <= 48) return t;
      return '${t.substring(0, 45)}...';
    }
    return 'разговор';
  }

  Future<void> saveSession(List<Message> messages, String pin) async {
    if (!await pinMatches(pin)) {
      throw StateError('Неверный PIN');
    }
    final id = _uuid.v4();
    final title = _titleFromMessages(messages);
    final savedAt = DateTime.now();
    final payload = jsonEncode(messages.map((m) => m.toJson()).toList());
    final plain = Uint8List.fromList(utf8.encode(payload));

    final key = _deriveAesKey(pin);
    final iv = Uint8List(_gcmIvLength);
    _randomBytes(iv);
    final sealed = _aesGcmEncrypt(key, iv, plain);

    final packet = Uint8List(iv.length + sealed.length);
    packet.setAll(0, iv);
    packet.setAll(iv.length, sealed);

    await _storage.write(
      key: '$_sessionKeyPrefix$id',
      value: base64Encode(packet),
    );

    final sessions = await loadSessionsMetadata();
    final next = [
      VaultSession(id: id, title: title, savedAt: savedAt).toIndexJson(),
      ...sessions.map((s) => s.toIndexJson()),
    ];
    await _storage.write(
      key: _sessionsIndexKey,
      value: jsonEncode(next),
    );
  }

  Future<List<Message>> loadSessionMessages(String sessionId, String pin) async {
    if (!await pinMatches(pin)) {
      throw StateError('Неверный PIN');
    }
    final b64 = await _storage.read(key: '$_sessionKeyPrefix$sessionId');
    if (b64 == null || b64.isEmpty) {
      throw StateError('Сессия не найдена');
    }
    final packet = base64Decode(b64);
    if (packet.length < _gcmIvLength + 16) {
      throw StateError('Повреждённые данные');
    }
    final iv = Uint8List.sublistView(packet, 0, _gcmIvLength);
    final sealed = Uint8List.sublistView(packet, _gcmIvLength);
    final key = _deriveAesKey(pin);
    final plain = _aesGcmDecrypt(key, iv, sealed);
    final str = utf8.decode(plain);
    final list = jsonDecode(str) as List<dynamic>;
    return list
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> deleteSession(String sessionId) async {
    await _storage.delete(key: '$_sessionKeyPrefix$sessionId');
    final sessions = await loadSessionsMetadata();
    final next = sessions.where((s) => s.id != sessionId).map((s) => s.toIndexJson()).toList();
    await _storage.write(key: _sessionsIndexKey, value: jsonEncode(next));
  }

  /// Сброс счётчика блокировки (например, после успешной биометрии к списку).
  void resetLockCounters() {
    _failedAttempts = 0;
    _lockedUntil = null;
  }
}
