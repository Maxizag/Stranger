import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neznakomets/services/counter_service.dart';
import 'package:neznakomets/services/limit_service.dart';

final counterServiceProvider = Provider<CounterService>((ref) {
  return CounterService();
});

final limitServiceProvider = Provider<LimitService>((ref) => LimitService());

/// Счётчик «сегодня» из Firebase RTDB (начальное состояние — загрузка, затем данные).
final counterProvider = StreamProvider<int>((ref) {
  return ref.watch(counterServiceProvider).getTodayCount();
});

final isOfflineProvider = StateProvider<bool>((ref) => false);
