import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';
import 'package:neznakomets/core/widgets/plum_ui.dart';
import 'package:neznakomets/features/subscription/subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  late final PageController _pageController;
  int _currentPage = 1;

  static const _plans = ['echo', 'voice', 'ultra'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage, viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: kPlumScreenDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: SizedBox(
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
              ),
              const SizedBox(height: 4),
              Text(
                'Выбери своё пространство',
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingBody.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    ref.read(subscriptionProvider.notifier).selectPlan(_plans[i]);
                  },
                  children: const [
                    _EchoCard(),
                    _VoiceCard(),
                    _UltraCard(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.dotActive
                          : AppColors.dotInactive,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Карточки планов
// ──────────────────────────────────────────

class _EchoCard extends StatelessWidget {
  const _EchoCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      badgeLabel: 'Эхо',
      priceLine: '99 ₽',
      features: const [
        _Feature(
          icon: Icons.format_list_numbered_rounded,
          label: '10 сообщений в день',
          sublabel: 'стандартный AI · познакомься',
        ),
      ],
      buttonLabel: 'ПОПРОБОВАТЬ',
      buttonGhost: true,
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      badgeLabel: 'Голос',
      priceLine: '249 ₽',
      features: const [
        _Feature(
          icon: Icons.format_list_numbered_rounded,
          label: '40 сообщений в день',
          sublabel: 'в 4× больше чем на Эхо',
        ),
        _Feature(
          icon: Icons.lock_outline_rounded,
          label: 'Личный сейф — 60 разговоров',
          sublabel: 'сохраняй лучшие беседы',
        ),
        _Feature(
          icon: Icons.smart_toy_outlined,
          label: 'Стандартный AI',
          sublabel: 'надёжный, быстрый',
        ),
      ],
      buttonLabel: 'ПОДКЛЮЧИТЬ',
      buttonGhost: false,
      footer: 'Влюбишься — всегда можно уйти глубже',
    );
  }
}

class _UltraCard extends StatelessWidget {
  const _UltraCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      badgeLabel: 'Бездна',
      priceLine: '499 ₽',
      features: const [
        _Feature(
          icon: Icons.bolt_rounded,
          label: 'Улучшенный AI',
          sublabel: 'более глубокие, живые ответы',
        ),
        _Feature(
          icon: Icons.person_outline_rounded,
          label: 'Незнакомец помнит тебя',
          sublabel: 'долгосрочная память между сессиями',
        ),
        _Feature(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Дай ему имя',
          sublabel: 'только на Бездне — твой незнакомец',
        ),
        _Feature(
          icon: Icons.format_list_numbered_rounded,
          label: '80 сообщений в день · сейф без лимита',
        ),
        _Feature(
          icon: Icons.check_rounded,
          label: 'Новые функции первым',
          sublabel: 'ранний доступ',
        ),
      ],
      buttonLabel: 'ПОДКЛЮЧИТЬ',
      buttonGhost: false,
      footer: 'Незнакомец запомнит тебя навсегда',
    );
  }
}

// ──────────────────────────────────────────
// Общая оболочка карточки
// ──────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.badgeLabel,
    required this.priceLine,
    required this.features,
    required this.buttonLabel,
    required this.buttonGhost,
    this.footer,
  });

  final String badgeLabel;
  final String priceLine;
  final List<_Feature> features;
  final String buttonLabel;
  final bool buttonGhost;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.btnGhostBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.borderRing1,
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priceLine,
                      style: AppTextStyles.numerals.copyWith(
                        fontSize: 36,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'в месяц',
                      style: AppTextStyles.onboardingBody.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentFaint.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTextStyles.eyebrow.copyWith(
                        fontSize: 18,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(
              color: AppColors.borderRing1.withValues(alpha: 0.6),
              thickness: 0.5,
            ),
            const SizedBox(height: 12),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        f.icon,
                        size: 16,
                        color: AppColors.accentDim,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.label,
                            style: AppTextStyles.onboardingBody.copyWith(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          if (f.sublabel != null)
                            Text(
                              f.sublabel!,
                              style: AppTextStyles.onboardingBody.copyWith(
                                fontSize: 12,
                                color: AppColors.textBody,
                                height: 1.4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (footer != null) ...[
              Text(
                footer!,
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingBody.copyWith(
                  fontSize: 15,
                  color: AppColors.textBody,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (buttonGhost)
              _GhostButton(label: buttonLabel)
            else
              _SolidButton(label: buttonLabel),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Фича
// ──────────────────────────────────────────

class _Feature {
  const _Feature({required this.icon, required this.label, this.sublabel});
  final IconData icon;
  final String label;
  final String? sublabel;
}

// ──────────────────────────────────────────
// Кнопки
// ──────────────────────────────────────────

class _SolidButton extends StatelessWidget {
  const _SolidButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.btnSolidStart,
            AppColors.btnSolidMid,
            AppColors.btnSolidEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(
          fontSize: 15,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w500,
          color: AppColors.btnSolidText,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentFaint.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(
          fontSize: 15,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w300,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
