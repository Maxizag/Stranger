import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// Счётчик сессий в Firebase Realtime Database (дата по московскому времени UTC+3).
class CounterService {
  CounterService({FirebaseDatabase? database})
      : _db = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL:
                  'https://stranger-522bb-default-rtdb.europe-west1.firebasedatabase.app',
            );

  final FirebaseDatabase _db;

  static const Duration _moscowOffset = Duration(hours: 3);

  /// Ключ дня YYYY-MM-DD по московскому времени (Россия без DST).
  static String moscowDateKey([DateTime? utcNow]) {
    final utc = (utcNow ?? DateTime.now()).toUtc();
    final moscow = utc.add(_moscowOffset);
    final y = moscow.year;
    final m = moscow.month.toString().padLeft(2, '0');
    final d = moscow.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DatabaseReference _todayCountRef() {
    final key = moscowDateKey();
    return _db.ref('sessions/$key/count');
  }

  /// Реалтайм-значение `sessions/{today}/count`.
  Stream<int> getTodayCount() {
    return _todayCountRef().onValue.map((event) {
      final v = event.snapshot.value;
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    });
  }

  /// Атомарно +1 к счётчику за сегодня (московская дата).
  Future<void> incrementCount() async {
    final ref = _todayCountRef();
    await ref.runTransaction((Object? current) {
      var n = 0;
      if (current is int) {
        n = current;
      } else if (current is num) {
        n = current.toInt();
      } else if (current != null) {
        n = int.tryParse(current.toString()) ?? 0;
      }
      return Transaction.success(n + 1);
    });
  }
}
