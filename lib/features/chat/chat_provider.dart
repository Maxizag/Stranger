import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neznakomets/features/home/home_provider.dart';
import 'package:neznakomets/features/subscription/subscription_provider.dart';
import 'package:neznakomets/models/message.dart';
import 'package:neznakomets/services/counter_service.dart';
import 'package:neznakomets/services/gigachat_service.dart';
import 'package:neznakomets/services/limit_service.dart';
import 'package:neznakomets/services/memory_service.dart';

const List<String> kCrisisTriggers = [
  'не хочу жить',
  'покончить с собой',
  'нет смысла',
  'всё кончено',
  'хочу умереть',
  'лучше бы меня не было',
];

/// Перед `go('/chat')` из сейфа: записать копию, `ref.invalidate(chatProvider)`, затем переход.
/// Фабрика [chatProvider] читает историю, синхронно очищает этот провайдер и передаёт копию в [ChatNotifier].
final historyProvider = StateProvider<List<Message>>((ref) => []);

/// ID сессии сейфа из которой был открыт текущий чат. null — новый чат.
final resumedVaultSessionIdProvider = StateProvider<String?>((ref) => null);

class ChatState {
  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.crisisCardShown = false,
    this.crisisCardAfterMessageId,
  });

  final List<Message> messages;
  final bool isLoading;
  final bool crisisCardShown;
  final String? crisisCardAfterMessageId;

  bool get canSaveToVault => messages.length >= 3;
  bool get isAtLimit => messages.length >= 20;

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? crisisCardShown,
    String? crisisCardAfterMessageId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      crisisCardShown: crisisCardShown ?? this.crisisCardShown,
      crisisCardAfterMessageId:
          crisisCardAfterMessageId ?? this.crisisCardAfterMessageId,
    );
  }

  factory ChatState.initial() {
    return ChatState(
      messages: [
        Message(
          id: 'welcome',
          text:
              'Я незнакомец. Именно поэтому тебе не нужно ничего скрывать. О чём не хочешь никому говорить?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Восстановление из сейфа: карточка кризиса, если триггер уже был в истории.
  factory ChatState.fromResumeHistory(List<Message> messages) {
    String? crisisAfter;
    var crisisShown = false;
    for (final m in messages) {
      if (!m.isUser) continue;
      final lower = m.text.toLowerCase();
      for (final t in kCrisisTriggers) {
        if (lower.contains(t)) {
          crisisShown = true;
          crisisAfter = m.id;
          break;
        }
      }
      if (crisisShown) break;
    }
    return ChatState(
      messages: messages,
      crisisCardShown: crisisShown,
      crisisCardAfterMessageId: crisisAfter,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(
    this._gigachat,
    this._counter,
    this._memory,
    this._limit, {
    ChatState? initialState,
    this.isUltraPlan = false,
    this.plan = 'free',
  }) : super(initialState ?? ChatState.initial()) {
    Future<void>.microtask(_init);
  }

  final GigachatService _gigachat;
  final CounterService _counter;
  final MemoryService _memory;
  final LimitService _limit;
  final bool isUltraPlan;
  final String plan;
  String? _userMemory;

  Future<void> _init() async {
    await _bumpSessionCounter();
    if (isUltraPlan) {
      _userMemory = await _memory.getMemory();
      debugPrint('ChatNotifier: память загружена: $_userMemory');
    }
  }

  Future<void> _bumpSessionCounter() async {
    try {
      await _counter.incrementCount();
    } catch (e, st) {
      debugPrint('CounterService.incrementCount: $e\n$st');
    }
  }

  /// Вызывается при завершении сессии (пауза приложения или лимит 20 сообщений).
  /// Запускает экстракцию фактов о пользователе и сохраняет в память.
  Future<void> maybeExtractMemory() async {
    if (!isUltraPlan) return;
    final meaningful = state.messages.where((m) => m.id != 'welcome').length;
    if (meaningful < 5) return;
    final facts = await _gigachat.extractMemory(state.messages);
    if (facts != null) {
      await _memory.saveMemory(facts);
      debugPrint('ChatNotifier: память обновлена: $facts');
    }
  }

  static bool _containsCrisisTrigger(String text) {
    final lower = text.toLowerCase();
    for (final t in kCrisisTriggers) {
      if (lower.contains(t)) return true;
    }
    return false;
  }

  Future<void> sendMessage(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.isLoading || state.isAtLimit) return;
    if (state.messages.length >= 20) return;

    // Проверяем лимит сообщений перед отправкой
    final canSend = await _limit.canStartSession(plan: plan);
    if (!canSend) {
      final limitMsg = Message(
        id: 'limit_${DateTime.now().microsecondsSinceEpoch}',
        text: 'лимит сообщений на сегодня исчерпан. возвращайся завтра.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, limitMsg]);
      return;
    }
    await _limit.recordSession(plan: plan);

    final userMsg = Message(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    var messages = [...state.messages, userMsg];
    String? crisisAfter = state.crisisCardAfterMessageId;
    var crisisShown = state.crisisCardShown;
    if (!state.crisisCardShown && _containsCrisisTrigger(text)) {
      crisisAfter = userMsg.id;
      crisisShown = true;
    }

    state = state.copyWith(
      messages: messages,
      isLoading: true,
      crisisCardAfterMessageId: crisisAfter,
      crisisCardShown: crisisShown,
    );

    if (messages.length >= 20) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final reply = await _gigachat.sendMessage(
        history: messages,
        userText: text,
        userMemory: isUltraPlan ? _userMemory : null,
      );
      final aiMsg = Message(
        id: 'a_${DateTime.now().microsecondsSinceEpoch}',
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages = [...messages, aiMsg];
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('ChatNotifier.sendMessage: $e\n$st');
      final aiMsg = Message(
        id: 'a_${DateTime.now().microsecondsSinceEpoch}',
        text: kGigachatFallbackReply,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...messages, aiMsg],
        isLoading: false,
      );
    }
  }
}

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  final sub = ref.read(subscriptionProvider);
  final currentPlan = sub.isSubscribed ? sub.selectedPlan : 'free';
  final isUltra = currentPlan == 'ultra';
  final memory = ref.read(memoryServiceProvider);
  final limit = ref.read(limitServiceProvider);
  final history = ref.read(historyProvider);
  if (history.isNotEmpty) {
    final copy = List<Message>.from(history);
    Future.microtask(() {
      ref.read(historyProvider.notifier).state = [];
    });
    return ChatNotifier(
      GigachatService(),
      ref.read(counterServiceProvider),
      memory,
      limit,
      initialState: ChatState.fromResumeHistory(copy),
      isUltraPlan: isUltra,
      plan: currentPlan,
    );
  }
  return ChatNotifier(
    GigachatService(),
    ref.read(counterServiceProvider),
    memory,
    limit,
    isUltraPlan: isUltra,
    plan: currentPlan,
  );
});
