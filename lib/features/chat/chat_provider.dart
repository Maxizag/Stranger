import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neznakomets/features/home/home_provider.dart';
import 'package:neznakomets/models/message.dart';
import 'package:neznakomets/services/counter_service.dart';
import 'package:neznakomets/services/gigachat_service.dart';

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
    this._counter, {
    ChatState? initialState,
  }) : super(initialState ?? ChatState.initial()) {
    Future<void>.microtask(_bumpSessionCounter);
  }

  final GigachatService _gigachat;
  final CounterService _counter;

  Future<void> _bumpSessionCounter() async {
    try {
      await _counter.incrementCount();
    } catch (e, st) {
      debugPrint('CounterService.incrementCount: $e\n$st');
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
  final history = ref.read(historyProvider);
  if (history.isNotEmpty) {
    final copy = List<Message>.from(history);
    // Riverpod запрещает синхронно менять другие провайдеры во время
    // инициализации. Очистим историю асинхронно (после текущего build).
    Future.microtask(() {
      ref.read(historyProvider.notifier).state = [];
    });
    return ChatNotifier(
      GigachatService(),
      ref.read(counterServiceProvider),
      initialState: ChatState.fromResumeHistory(copy),
    );
  }
  return ChatNotifier(
    GigachatService(),
    ref.read(counterServiceProvider),
  );
});
