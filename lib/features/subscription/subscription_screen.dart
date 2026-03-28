import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/features/subscription/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _accent = Color(0xFFC8B8FF);
  static const Color _accentFg = Color(0xFF1A1040);
  static const Color _textPrimary = Color(0xFFE8E8E8);
  static const Color _textMuted = Color(0xFF555555);
  static const Color _badgeYearBg = Color(0xFF2A1F4A);

  static const List<String> _features = [
    'безлимитные сессии',
    'личный сейф',
    'приоритетный ответ AI',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(subscriptionProvider).selectedPlan;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      child: IconButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: _textPrimary,
                          size: 24,
                        ),
                        tooltip: 'назад',
                      ),
                    ),
                    const Text(
                      'подписка',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'безлимит + личный сейф',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PlanCard(
                          selected: selected == 'month',
                          badgeLabel: 'популярный',
                          badgeBg: _accent,
                          badgeFg: _accentFg,
                          priceLine: '199 ₽',
                          subtitle: 'в месяц',
                          features: _features,
                          onTap: () => ref
                              .read(subscriptionProvider.notifier)
                              .selectPlan('month'),
                        ),
                        const SizedBox(height: 16),
                        _PlanCard(
                          selected: selected == 'year',
                          badgeLabel: 'выгоднее на 58%',
                          badgeBg: _badgeYearBg,
                          badgeFg: _accent,
                          priceLine: '999 ₽',
                          subtitle: 'в год · 83 ₽/мес',
                          features: _features,
                          onTap: () => ref
                              .read(subscriptionProvider.notifier)
                              .selectPlan('year'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Text(
                'бесплатно: 3 сессии в день',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('скоро будет доступно'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _accentFg,
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('оформить подписку'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeFg,
    required this.priceLine,
    required this.subtitle,
    required this.features,
    required this.onTap,
  });

  final bool selected;
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeFg;
  final String priceLine;
  final String subtitle;
  final List<String> features;
  final VoidCallback onTap;

  static const Color _card = Color(0xFF161616);
  static const Color _accent = Color(0xFFC8B8FF);
  static const Color _textPrimary = Color(0xFFE8E8E8);
  static const Color _textMuted = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: badgeFg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                priceLine,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: _accent,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              ...features.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: _accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textPrimary,
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
