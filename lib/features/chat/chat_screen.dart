import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/features/chat/chat_provider.dart';
import 'package:neznakomets/features/vault/vault_provider.dart';
import 'package:neznakomets/models/message.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF161616);
  static const Color _accent = Color(0xFFC8B8FF);
  static const Color _textPrimary = Color(0xFFE8E8E8);
  static const Color _muted = Color(0xFF555555);
  static const Color _divider = Color(0xFF2A2A2A);
  static const Color _fieldBg = Color(0xFF1A1A1A);

  final _controller = TextEditingController();
  var _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final next = _controller.text.trim().isNotEmpty;
    if (next != _canSend) setState(() => _canSend = next);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  List<Object> _sequence(ChatState state) {
    final seq = <Object>[];
    for (final m in state.messages) {
      seq.add(m);
      if (state.crisisCardAfterMessageId == m.id) {
        seq.add(_CrisisListToken.instance);
      }
    }
    if (state.isLoading) seq.add(_TypingListToken.instance);
    return seq;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final maxBubbleW = MediaQuery.sizeOf(context).width * 0.75;
    final seq = _sequence(state);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop && context.mounted) context.go('/');
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 4, right: 16, top: 4, bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: _muted,
                      ),
                      tooltip: 'назад',
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'анонимная сессия · исчезнет после закрытия',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: _muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '${state.messages.length} / 20',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, thickness: 1, color: _divider),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: seq.length,
                itemBuilder: (context, index) {
                  final item = seq[seq.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildItem(
                      context,
                      item,
                      maxBubbleW,
                    ),
                  );
                },
              ),
            ),
            if (state.isAtLimit)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Text(
                      'сессия завершена. начать новую?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: _textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => context.go('/'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: const Color(0xFF1A1040),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'начать новую',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                color: _card,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.canSaveToVault)
                      SizedBox(
                        height: 36,
                        width: double.infinity,
                        child: InkWell(
                          onTap: () => _onSaveToVault(),
                          child: const Center(
                            child: Text(
                              'сохранить в сейф',
                              style: TextStyle(
                                fontSize: 13,
                                color: _accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 5,
                              style: const TextStyle(
                                fontSize: 15,
                                color: _textPrimary,
                              ),
                              cursorColor: _accent,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: _fieldBg,
                                hintText: 'напиши что-нибудь...',
                                hintStyle: const TextStyle(
                                  fontSize: 15,
                                  color: _muted,
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
                              onSubmitted: state.isLoading
                                  ? null
                                  : (_) => _submit(state),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            onPressed: (!state.isLoading && _canSend)
                                ? () => _submit(state)
                                : null,
                            icon: Icon(
                              Icons.send_rounded,
                              size: 22,
                              color: (!state.isLoading && _canSend)
                                  ? _accent
                                  : _muted.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  void _submit(ChatState state) {
    if (!_canSend || state.isLoading || state.isAtLimit) return;
    final t = _controller.text;
    _controller.clear();
    setState(() => _canSend = false);
    ref.read(chatProvider.notifier).sendMessage(t);
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
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: _SaveVaultPinSheet(
            accent: _accent,
            textPrimary: _textPrimary,
            muted: _muted,
            fieldBg: _fieldBg,
          ),
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

  Widget _buildItem(
    BuildContext context,
    Object item,
    double maxBubbleW,
  ) {
    if (item is Message) {
      return _MessageBubble(
        message: item,
        maxWidth: maxBubbleW,
      );
    }
    if (identical(item, _CrisisListToken.instance)) {
      return const _CrisisCard();
    }
    if (identical(item, _TypingListToken.instance)) {
      return _TypingBubble(maxWidth: maxBubbleW);
    }
    return const SizedBox.shrink();
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.maxWidth,
  });

  final Message message;
  final double maxWidth;

  static const Color _textPrimary = Color(0xFFE8E8E8);
  static const Color _muted = Color(0xFF555555);
  static const Color _bubbleAi = Color(0xFF1A1A1A);
  static const Color _bubbleUser = Color(0xFF2A1F4A);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(4),
          );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? _bubbleUser : _bubbleAi,
        borderRadius: radius,
      ),
      child: Text(
        message.text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.35,
          color: _textPrimary,
        ),
      ),
    );

    final column = Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        if (!isUser) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Thumb(text: '👍'),
              const SizedBox(width: 8),
              _Thumb(text: '👎'),
            ],
          ),
        ],
      ],
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: column,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1,
        color: _MessageBubble._muted,
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.maxWidth});

  final double maxWidth;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  static const Color _bubbleAi = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFFC8B8FF);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _bubbleAi,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _ac,
          builder: (context, _) {
            final t = _ac.value * math.pi * 2;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = i * 0.5;
                final o = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t + phase));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: o.clamp(0.35, 1.0),
                    child: const Text(
                      '·',
                      style: TextStyle(
                        fontSize: 28,
                        height: 0.85,
                        color: _accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  const _CrisisCard();

  static const Color _bg = Color(0xFF1A0F0F);
  static const Color _border = Color(0xFFFF6B6B);
  static const Color _text = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'если тебе очень плохо — позвони: 8-800-2000-122',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: _text,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: '88002000122');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: _text,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'позвонить',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveVaultPinSheet extends StatefulWidget {
  const _SaveVaultPinSheet({
    required this.accent,
    required this.textPrimary,
    required this.muted,
    required this.fieldBg,
  });

  final Color accent;
  final Color textPrimary;
  final Color muted;
  final Color fieldBg;

  @override
  State<_SaveVaultPinSheet> createState() => _SaveVaultPinSheetState();
}

class _SaveVaultPinSheetState extends State<_SaveVaultPinSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: widget.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 15, color: widget.textPrimary),
            cursorColor: widget.accent,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: widget.fieldBg,
              hintText: '6 цифр',
              hintStyle: TextStyle(fontSize: 15, color: widget.muted),
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
          FilledButton(
            onPressed: () {
              final p = _controller.text.trim();
              if (p.length == 6) Navigator.pop(context, p);
            },
            style: FilledButton.styleFrom(
              backgroundColor: widget.accent,
              foregroundColor: const Color(0xFF1A1040),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('сохранить', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
