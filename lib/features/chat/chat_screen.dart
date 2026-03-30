import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';
import 'package:neznakomets/core/widgets/plum_ui.dart';
import 'package:neznakomets/features/chat/chat_provider.dart';
import 'package:neznakomets/features/chat/models/chat_message.dart';
import 'package:neznakomets/features/subscription/subscription_provider.dart';
import 'package:neznakomets/features/vault/vault_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    _onAppPaused();
  }

  /// Сохранять только если есть реальный диалог (не одно стартовое приветствие).
  static bool _shouldPersistChatOnPause(ChatState s) {
    final msgs = s.messages;
    if (msgs.isEmpty) return false;
    if (msgs.length == 1 && msgs.single.id == 'welcome') return false;
    return true;
  }

  Future<void> _onAppPaused() async {
    final chatState = ref.read(chatProvider);
    final isSubscribed = ref.read(subscriptionProvider).isSubscribed;
    final pin = ref.read(vaultProvider.notifier).cachedPin;

    if (isSubscribed &&
        pin != null &&
        _shouldPersistChatOnPause(chatState)) {
      try {
        await ref.read(vaultProvider.notifier).saveChatSession(
              chatState.messages,
              pin,
            );
      } catch (_) {}
    }

    if (!mounted) return;
    // Сначала уходим с маршрута — иначе после invalidate autoDispose сразу создаст
    // новый ChatNotifier, пока экран чата ещё в дереве.
    context.go('/');
    ref.invalidate(chatProvider);
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<Object> _displaySequence(ChatState state) {
    final out = <Object>[];
    for (final m in state.messages) {
      out.add(ChatMessage.fromMessage(m));
      if (state.crisisCardAfterMessageId == m.id) {
        out.add(_CrisisListToken.instance);
      }
    }
    if (state.isLoading) {
      out.add(_TypingListToken.instance);
    }
    return out;
  }

  void _endSession() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.chatDialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'завершить сессию?',
          style: AppTextStyles.onboardingTitle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Переписка будет удалена навсегда.',
          style: AppTextStyles.onboardingBody.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('отмена', style: AppTextStyles.skip),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: Text(
              'удалить',
              style: AppTextStyles.button.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isLoading != next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final seq = _displaySequence(state);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop && context.mounted) context.go('/');
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: kPlumScreenDecoration,
          child: SafeArea(
          child: Column(
            children: [
              _ChatHeader(onEnd: _endSession),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: seq.length,
                  itemBuilder: (ctx, i) {
                    final item = seq[i];
                    if (identical(item, _TypingListToken.instance)) {
                      return const _TypingBubble();
                    }
                    if (identical(item, _CrisisListToken.instance)) {
                      return const _CrisisCard();
                    }
                    if (item is ChatMessage) {
                      return _MessageBubble(message: item);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              if (state.isAtLimit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                  child: Column(
                    children: [
                      Text(
                        'сессия завершена. начать новую?',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingBody.copyWith(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.go('/chat'),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.btnSolidStart,
                                AppColors.btnSolidMid,
                                AppColors.btnSolidEnd,
                              ],
                              stops: [0.0, 0.55, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: AppColors.accent.a * 0.22),
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'НАЧАТЬ НОВУЮ',
                            style: AppTextStyles.button,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _ChatInputArea(
                  state: state,
                  onSaveVault: () => _onSaveToVault(),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _onSaveToVault() async {
    final vault = ref.read(vaultProvider.notifier);
    final msgs = ref.read(chatProvider).messages;
    if (msgs.length < 3) return;

    if (!await vault.hasPIN()) {
      if (mounted) context.push('/vault');
      return;
    }

    if (!mounted) return;
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.chatDialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: const _SaveVaultPinSheet(),
        );
      },
    );

    if (pin == null || pin.length != 6) return;
    if (!await vault.pinMatches(pin)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('неверный PIN')),
        );
      }
      return;
    }

    try {
      await vault.saveChatSession(msgs, pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('сохранено в сейф')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('не удалось сохранить')),
        );
      }
    }
  }
}

class _CrisisListToken {
  const _CrisisListToken._();
  static const instance = _CrisisListToken._();
}

class _TypingListToken {
  const _TypingListToken._();
  static const instance = _TypingListToken._();
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onEnd});

  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.chatHeaderBorderBottom,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.btnGhostBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderRing1, width: 0.5),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.chatBackIcon,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'сессия · анонимно',
                  style: AppTextStyles.slideTag.copyWith(
                    fontSize: 13,
                    letterSpacing: 0.15,
                    color: AppColors.textEyebrow.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: AppColors.accentDim.withValues(alpha: 0.18),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.chatEndSessionBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentDim.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.stop_circle_outlined,
                color: AppColors.accentDim.withValues(alpha: 0.75),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  bool get isUser => message.role == MessageRole.user;

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.chatBubbleUserFill
                        : AppColors.chatBubbleAiFill,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 18),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.accent.withValues(alpha: AppColors.accent.a * 0.18)
                          : AppColors.borderRing1,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.onboardingBody.copyWith(
                      fontSize: 14,
                      height: 1.55,
                      letterSpacing: 0.1,
                      color: isUser
                          ? AppColors.chatBubbleUserText
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!isUser)
                  Positioned(
                    left: 0,
                    top: 6,
                    bottom: 10,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.accentDim.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _formatTime(message.timestamp),
                style: AppTextStyles.onboardingBody.copyWith(
                  fontSize: 11,
                  color: AppColors.chatTimestamp,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(),
    );
    _anims = List.generate(3, (i) {
      final start = i * 0.2;
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.3, end: 1.0),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.3),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(0.3),
          weight: 40,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _ctrls[i],
          curve: Interval(
            start,
            (start + 0.6).clamp(0.0, 1.0),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.chatTypingBubbleBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.borderRing1, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5.0 : 0),
              child: FadeTransition(
                opacity: _anims[i],
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.chatTypingDot,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ChatInputArea extends ConsumerStatefulWidget {
  const _ChatInputArea({
    required this.state,
    required this.onSaveVault,
  });

  final ChatState state;
  final VoidCallback onSaveVault;

  @override
  ConsumerState<_ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends ConsumerState<_ChatInputArea> {
  final _controller = TextEditingController();
  var _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final next = _controller.text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.state.isLoading || widget.state.isAtLimit) {
      return;
    }
    _controller.clear();
    setState(() => _hasText = false);
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    const int messageLimit = 20;
    const int counterThreshold = 15;
    final int msgCount = state.messages.length;
    final int remaining = messageLimit - msgCount;
    final bool showCounter = msgCount >= counterThreshold && !state.isAtLimit;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCounter)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'осталось сообщений: $remaining',
              style: AppTextStyles.onboardingBody.copyWith(
                fontSize: 12,
                color: remaining <= 3
                    ? AppColors.crisisCardText.withValues(alpha: 0.8)
                    : AppColors.textBody,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (state.canSaveToVault)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: widget.onSaveVault,
                borderRadius: BorderRadius.circular(10),
                splashColor: AppColors.accent.withValues(alpha: 0.1),
                highlightColor: AppColors.accent.withValues(alpha: 0.06),
                child: Ink(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentFaint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.22),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: AppColors.accent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'сохранить в сейф',
                          style: AppTextStyles.onboardingBody.copyWith(
                            fontSize: 13,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        _ChatInputBar(
          controller: _controller,
          hasText: _hasText,
          isLoading: state.isLoading,
          onSubmit: _submit,
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.hasText,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool hasText;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.chatInputTopBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 42,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.btnGhostBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: hasText
                          ? AppColors.chatFieldBorderActive
                          : AppColors.chatFieldBorderIdle,
                      width: hasText ? 1.0 : 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    enabled: !isLoading,
                    style: AppTextStyles.onboardingBody.copyWith(
                      fontSize: 14,
                      color: AppColors.chatInputText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'напиши что-нибудь...',
                      hintStyle: AppTextStyles.onboardingBody.copyWith(
                        fontSize: 14,
                        color: AppColors.chatInputHint,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: (hasText && !isLoading) ? onSubmit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasText
                          ? const [
                              AppColors.btnSolidStart,
                              AppColors.btnSolidMid,
                            ]
                          : const [
                              AppColors.chatSendInactiveStart,
                              AppColors.chatSendInactiveEnd,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(
                        alpha: AppColors.accent.a * (hasText ? 0.22 : 0.08),
                      ),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.accent.withValues(
                      alpha: AppColors.accent.a * (hasText ? 0.85 : 0.25),
                    ),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'переписка исчезнет · сохрани в сейф',
            style: AppTextStyles.onboardingBody.copyWith(
              fontSize: 12,
              color: AppColors.textBody.withValues(alpha: 0.6),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  const _CrisisCard();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.crisisCardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.crisisCardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'если тебе очень плохо — позвони: 8-800-2000-122',
                style: AppTextStyles.onboardingBody.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.crisisCardText,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: '88002000122');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.crisisCardText,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: const Size(80, 44),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.crisisCardBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    'позвонить',
                    style: AppTextStyles.onboardingBody.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      color: AppColors.crisisCardText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveVaultPinSheet extends StatefulWidget {
  const _SaveVaultPinSheet();

  @override
  State<_SaveVaultPinSheet> createState() => _SaveVaultPinSheetState();
}

class _SaveVaultPinSheetState extends State<_SaveVaultPinSheet> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'введи PIN сейфа',
            style: AppTextStyles.onboardingTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.onboardingBody.copyWith(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.btnGhostBg,
              hintText: '6 цифр',
              hintStyle: AppTextStyles.onboardingBody.copyWith(
                fontSize: 15,
                color: AppColors.textBody,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onSubmitted: (v) {
              if (v.trim().length == 6) Navigator.pop(context, v.trim());
            },
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              final p = _pinController.text.trim();
              if (p.length == 6) Navigator.pop(context, p);
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.btnSolidStart,
                    AppColors.btnSolidMid,
                    AppColors.btnSolidEnd,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent
                      .withValues(alpha: AppColors.accent.a * 0.22),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text('сохранить', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}
