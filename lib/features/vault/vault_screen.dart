import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';
import 'package:neznakomets/core/widgets/plum_ui.dart';
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
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: kPlumScreenDecoration,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PlumBackButton(
                          onTap: () {
                            ref.read(vaultProvider.notifier).lock();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                        ),
                      ),
                      Text(
                        'сейф',
                        style: AppTextStyles.onboardingTitle.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: AppColors.borderRing1,
                  thickness: 0.5,
                  height: 1,
                ),
                Expanded(
                  child: sessions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_open_rounded,
                                  size: 48,
                                  color: AppColors.accentFaint,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'здесь будут твои сохранённые разговоры',
                                  textAlign: TextAlign.center,
                                  style:
                                      AppTextStyles.onboardingBody.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.btnGhostBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderRing1,
                                    width: 0.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatDate(s.savedAt),
                                                style: AppTextStyles
                                                    .onboardingBody
                                                    .copyWith(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textEyebrow,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                s.title,
                                                style: AppTextStyles
                                                    .onboardingBody
                                                    .copyWith(
                                                  fontSize: 13,
                                                  color: AppColors.textBody,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.textMuted,
                                          ),
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor:
                                                    AppColors.chatDialogBg,
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20),
                                                  side: BorderSide(
                                                    color:
                                                        AppColors.borderRing1,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                title: Text(
                                                  'удалить?',
                                                  style: AppTextStyles
                                                      .onboardingTitle
                                                      .copyWith(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: Text(
                                                      'нет',
                                                      style: AppTextStyles
                                                          .skip,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child: Text(
                                                      'да',
                                                      style: AppTextStyles
                                                          .button
                                                          .copyWith(
                                                        color:
                                                            AppColors.accent,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true &&
                                                context.mounted) {
                                              await ref
                                                  .read(vaultProvider
                                                      .notifier)
                                                  .deleteSession(s.id);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: PlumGhostButton(
                                            label: 'открыть',
                                            minHeight: 40,
                                            fontSize: 11,
                                            onTap: () => context.push(
                                              '/vault/session/${s.id}',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
