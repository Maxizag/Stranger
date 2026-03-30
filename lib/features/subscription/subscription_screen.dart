import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';
import 'package:neznakomets/core/widgets/plum_ui.dart';
import 'package:neznakomets/features/subscription/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(subscriptionProvider).selectedPlan;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: kPlumScreenDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
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
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/'),
                        ),
                      ),
                      Text(
                        'Тарифы',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingTitle.copyWith(
                          fontSize: 22,
                          color: AppColors.accent.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Выбери своё пространство',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.onboardingBody.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PlanCard(
                            planId: 'echo',
                            selected: selected == 'echo',
                            badgeLabel: 'Эхо',
                            isHighlighted: false,
                            priceLine: '99 ₽',
                            subtitle: 'в месяц',
                            features: const [
                              _Feature(
                                icon: Icons.format_list_numbered_rounded,
                                label: '10 сессий в день',
                              ),
                              _Feature(
                                icon: Icons.smart_toy_outlined,
                                label: 'стандартный AI',
                              ),
                            ],
                            onTap: () => ref
                                .read(subscriptionProvider.notifier)
                                .selectPlan('echo'),
                          ),
                          const SizedBox(height: 12),
                          _PlanCard(
                            planId: 'voice',
                            selected: selected == 'voice',
                            badgeLabel: 'Голос',
                            isHighlighted: false,
                            priceLine: '249 ₽',
                            subtitle: 'в месяц',
                            features: const [
                              _Feature(
                                icon: Icons.format_list_numbered_rounded,
                                label: '30 сессий в день',
                              ),
                              _Feature(
                                icon: Icons.lock_outline_rounded,
                                label: 'личный сейф до 30 разговоров',
                              ),
                              _Feature(
                                icon: Icons.smart_toy_outlined,
                                label: 'стандартный AI',
                              ),
                            ],
                            onTap: () => ref
                                .read(subscriptionProvider.notifier)
                                .selectPlan('voice'),
                          ),
                          const SizedBox(height: 12),
                          _PlanCard(
                            planId: 'ultra',
                            selected: selected == 'ultra',
                            badgeLabel: 'Бездна',
                            isHighlighted: false,
                            priceLine: '499 ₽',
                            subtitle: 'в месяц',
                            features: const [
                              _Feature(
                                icon: Icons.all_inclusive_rounded,
                                label: 'безлимитные сессии',
                              ),
                              _Feature(
                                icon: Icons.lock_rounded,
                                label: 'безлимитный сейф',
                              ),
                              _Feature(
                                icon: Icons.bolt_rounded,
                                label: 'улучшенный AI — более продвинутые ответы',
                              ),
                              _Feature(
                                icon: Icons.auto_awesome_rounded,
                                label: 'новые функции первым',
                              ),
                            ],
                            onTap: () => ref
                                .read(subscriptionProvider.notifier)
                                .selectPlan('ultra'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _ConnectButton(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.planId,
    required this.selected,
    required this.badgeLabel,
    required this.isHighlighted,
    required this.priceLine,
    required this.subtitle,
    required this.features,
    required this.onTap,
  });

  final String planId;
  final bool selected;
  final String badgeLabel;
  final bool isHighlighted;
  final String priceLine;
  final String subtitle;
  final List<_Feature> features;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.accent.withValues(alpha: isHighlighted ? 0.7 : 0.35)
        : isHighlighted
            ? AppColors.accent.withValues(alpha: 0.25)
            : AppColors.borderRing1;
    final borderWidth = isHighlighted ? 1.5 : (selected ? 1.0 : 0.5);
    final bgColor = isHighlighted
        ? AppColors.accentFaint.withValues(alpha: 0.18)
        : AppColors.btnGhostBg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isHighlighted ? 22 : 18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceLine,
                          style: AppTextStyles.numerals.copyWith(
                            fontSize: isHighlighted ? 34 : 28,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.onboardingBody.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textBody,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? AppColors.accent.withValues(alpha: 0.18)
                          : AppColors.accentFaint.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accent.withValues(
                          alpha: isHighlighted ? 0.6 : 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTextStyles.eyebrow.copyWith(
                          fontSize: 18,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                          color: isHighlighted
                              ? AppColors.textPrimary
                              : AppColors.textBody,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        f.icon,
                        size: 16,
                        color: isHighlighted
                            ? AppColors.accent
                            : AppColors.accentDim,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.label,
                          style: AppTextStyles.onboardingBody.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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

class _ConnectButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.btnGhostBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderRing1,
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ПОДКЛЮЧИТЬ',
            style: AppTextStyles.button.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '· скоро',
            style: AppTextStyles.onboardingBody.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
