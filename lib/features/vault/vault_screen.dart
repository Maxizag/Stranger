import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/app/theme.dart';
import 'package:neznakomets/features/vault/vault_provider.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year} $hh:$min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(vaultProvider).sessions;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) ref.read(vaultProvider.notifier).lock();
      },
      child: Scaffold(
        backgroundColor: NeznakometsColors.background,
        appBar: AppBar(
          backgroundColor: NeznakometsColors.card,
          foregroundColor: NeznakometsColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(vaultProvider.notifier).lock();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text(
            'сейф',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        body: sessions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'здесь будут твои сохранённые разговоры',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: NeznakometsColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, i) {
                  final s = sessions[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: NeznakometsColors.card,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/vault/session/${s.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(s.savedAt),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: NeznakometsColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.35,
                                        color: NeznakometsColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: NeznakometsColors.textSecondary,
                                ),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: NeznakometsColors.card,
                                      title: const Text(
                                        'удалить?',
                                        style: TextStyle(
                                          color: NeznakometsColors.textPrimary,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('нет'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('да'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    await ref
                                        .read(vaultProvider.notifier)
                                        .deleteSession(s.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
