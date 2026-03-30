import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';
import 'package:neznakomets/core/widgets/plum_ui.dart';
import 'package:neznakomets/features/chat/chat_provider.dart';
import 'package:neznakomets/features/vault/vault_provider.dart';
import 'package:neznakomets/models/message.dart';

class VaultSessionDetailScreen extends ConsumerStatefulWidget {
  const VaultSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<VaultSessionDetailScreen> createState() =>
      _VaultSessionDetailScreenState();
}

class _VaultSessionDetailScreenState
    extends ConsumerState<VaultSessionDetailScreen> {
  List<Message>? _messages;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final pin = ref.read(vaultProvider.notifier).cachedPin;
    if (pin != null) {
      try {
        final m = await ref
            .read(vaultProvider.notifier)
            .loadMessagesForSession(widget.sessionId, pin);
        if (mounted) {
          setState(() {
            _messages = m;
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'не удалось открыть';
          });
        }
      }
      return;
    }

    if (mounted) setState(() => _loading = false);
    if (mounted) await _askPinAndLoad();
  }

  Future<void> _askPinAndLoad() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.chatDialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.borderRing1, width: 0.5),
          ),
          title: Text(
            'PIN сейфа',
            style: AppTextStyles.onboardingBody.copyWith(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: c,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.onboardingBody.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '6 цифр',
              hintStyle: AppTextStyles.onboardingBody.copyWith(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.borderRing1,
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.accentFaint,
                  width: 0.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'отмена',
                style: AppTextStyles.skip,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: Text(
                'ок',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (pin == null || pin.length != 6 || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final m = await ref
          .read(vaultProvider.notifier)
          .loadMessagesForSession(widget.sessionId, pin);
      if (mounted) {
        ref.read(vaultProvider.notifier).cachePinAfterSuccessfulDecrypt(pin);
        setState(() {
          _messages = m;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'неверный PIN или повреждённые данные';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.75;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: kPlumScreenDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PlumBackButton(
                          onTap: () => context.pop(),
                        ),
                      ),
                      Text(
                        'разговор',
                        style: AppTextStyles.onboardingTitle.copyWith(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.onboardingBody
                                          .copyWith(
                                        fontSize: 15,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: PlumButton(
                                        label: 'ещё раз',
                                        onTap: () {
                                          setState(() {
                                            _error = null;
                                            _loading = true;
                                          });
                                          _askPinAndLoad();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages!.length,
                                    itemBuilder: (context, i) {
                                      final m = _messages![i];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: _VaultReadBubble(
                                          message: m,
                                          maxWidth: maxW,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SafeArea(
                                  top: false,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      16,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: PlumButton(
                                        label: 'продолжить разговор',
                                        onTap: () {
                                          ref
                                              .read(historyProvider.notifier)
                                              .state = List<Message>.from(
                                            _messages!,
                                          );
                                          ref.invalidate(chatProvider);
                                          context.go('/chat');
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VaultReadBubble extends StatelessWidget {
  const _VaultReadBubble({required this.message, required this.maxWidth});

  final Message message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.chatBubbleUserFill
              : AppColors.chatBubbleAiFill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.accent.withValues(
                    alpha: AppColors.accent.a * 0.18,
                  )
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
                : AppColors.chatBubbleAiText,
          ),
        ),
      ),
    );
  }
}
