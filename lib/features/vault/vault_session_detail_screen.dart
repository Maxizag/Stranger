import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/app/theme.dart';
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
          backgroundColor: NeznakometsColors.card,
          title: const Text(
            'PIN сейфа',
            style: TextStyle(color: NeznakometsColors.textPrimary),
          ),
          content: TextField(
            controller: c,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: NeznakometsColors.textPrimary),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '6 цифр',
              hintStyle: TextStyle(color: NeznakometsColors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('ок'),
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
      backgroundColor: NeznakometsColors.background,
      appBar: AppBar(
        backgroundColor: NeznakometsColors.card,
        foregroundColor: NeznakometsColors.textPrimary,
        elevation: 0,
        title: const Text(
          'разговор',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: NeznakometsColors.accent),
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
                          style: const TextStyle(
                            fontSize: 15,
                            color: NeznakometsColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _loading = true;
                            });
                            _askPinAndLoad();
                          },
                          child: const Text('ещё раз'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages?.length ?? 0,
                  itemBuilder: (context, i) {
                    final m = _messages![i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VaultReadBubble(message: m, maxWidth: maxW),
                    );
                  },
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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? NeznakometsColors.bubbleUser
              : NeznakometsColors.bubbleAi,
          borderRadius: radius,
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
            color: NeznakometsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
