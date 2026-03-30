import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';
import 'package:neznakomets/core/widgets/plum_ui.dart';
import 'package:neznakomets/features/home/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int? _remainingSessions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshRemaining();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshRemaining();
  }

  Future<void> _refreshRemaining() async {
    final n = await ref.read(limitServiceProvider).remainingToday();
    if (mounted) setState(() => _remainingSessions = n);
  }

  Future<void> _onStartSpeaking() async {
    final limit = ref.read(limitServiceProvider);
    final ok = await limit.canStartSession();
    if (!mounted) return;
    if (!ok) {
      final remaining = await limit.remainingToday();
      if (!mounted) return;
      _showLimitSheet(remaining);
      return;
    }
    await limit.recordSession();
    if (!mounted) return;
    await context.push('/chat');
    if (mounted) _refreshRemaining();
  }

  void _showLimitSheet(int remainingToday) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.homeLimitSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'лимит на сегодня исчерпан',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.onboardingTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'бесплатно доступно 3 сессии в день',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.onboardingBody.copyWith(
                    fontSize: 14,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'осталось сессий сегодня: $remainingToday',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.onboardingBody.copyWith(
                    fontSize: 16,
                    color: AppColors.homeSessionsFooter,
                  ),
                ),
                const SizedBox(height: 20),
                PlumButton(
                  label: 'понятно',
                  onTap: () => Navigator.of(ctx).pop(),
                ),
                const SizedBox(height: 10),
                PlumGhostButton(
                  label: 'оформить подписку',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/subscription');
                  },
                  minHeight: 48,
                  fontSize: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncCount = ref.watch(counterProvider);
    final offline = ref.watch(isOfflineProvider);

    final rawCount = asyncCount.valueOrNull ?? 0;
    final countLabel = asyncCount.when(
      data: (n) => _formatThousands(n),
      loading: () => '...',
      error: (Object? e, StackTrace? st) => '—',
    );

    final remainingLabel = _remainingSessions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: kPlumScreenDecoration,
        child: SafeArea(
          child: Column(
            children: [
              if (offline) const _OfflineBanner(),
              Expanded(
                child: Column(
                  children: [
                    _TitleBlock(),
                    Expanded(
                      child: _CounterBlock(countLabel: countLabel, count: rawCount),
                    ),
                    _FooterBlock(
                      remainingLabel: remainingLabel,
                      onStartSpeaking: _onStartSpeaking,
                      onSubscription: () async {
                        await context.push('/subscription');
                        if (mounted) _refreshRemaining();
                      },
                      onVault: () async {
                        await context.push('/vault');
                        if (mounted) _refreshRemaining();
                      },
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

  static String _formatThousands(int n) {
    final negative = n < 0;
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(' ');
      }
      buf.write(s[i]);
    }
    return negative ? '-$buf' : buf.toString();
  }
}

class _TitleBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
      child: Column(
        children: [
          Text(
            'Незнакомец',
            style: AppTextStyles.onboardingTitle.copyWith(
              fontSize: 24,
              // На темном фоне лучше смотрится Plum Rose акцент, а не белый.
              color: AppColors.accent.withValues(alpha: 0.95),
              shadows: [
                Shadow(
                  color: AppColors.homeAmbientGlow.withValues(alpha: 0.28),
                  blurRadius: 26,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          Text(
            'Скажи то, что держишь в себе',
            style: AppTextStyles.onboardingBody.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: AppColors.accentDim.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CounterBlock extends StatelessWidget {
  const _CounterBlock({required this.countLabel, required this.count});

  final String countLabel;
  final int count;

  /// Нормализованное значение 0.0–1.0, насыщается при 2000+ сессиях.
  double get _t => (count / 2000).clamp(0.0, 1.0);

  double _lerp(double a, double b) => a + (b - a) * _t;

  /// Размер центрального круга: 86px (тихо) → 150px (активно).
  double get _coreSize => _lerp(86, 150);

  /// Яркость ambient glow: 0.05 → 0.18.
  double get _glowAlpha => _lerp(0.05, 0.18);

  /// Скорость дыхания: 6с (тихо) → 2.8с (активно).
  Duration get _breathDuration =>
      Duration(milliseconds: _lerp(6000, 2800).round());

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -30,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.homeAmbientGlow.withValues(alpha: _glowAlpha),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderRing1
                            .withValues(alpha: AppColors.borderRing1.a * 0.03),
                        width: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 188,
                    height: 188,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderRing1
                            .withValues(alpha: AppColors.borderRing1.a * 0.06),
                        width: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderRing1,
                        width: 0.5,
                      ),
                    ),
                  ),
                  _BreathingCore(
                    size: _coreSize,
                    breathDuration: _breathDuration,
                    child: Text(
                      countLabel,
                      style: AppTextStyles.numerals.copyWith(
                        fontSize: 38,
                        color: AppColors.homeCounterNumber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Доверились незнакомцу сегодня',
              style: AppTextStyles.onboardingBody.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.textBody,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: AppColors.accentDim.withValues(alpha: 0.16),
                    blurRadius: 18,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

class _BreathingCore extends StatefulWidget {
  const _BreathingCore({
    required this.child,
    required this.size,
    this.breathDuration = const Duration(seconds: 5),
  });

  final Widget child;
  final double size;
  final Duration breathDuration;

  @override
  State<_BreathingCore> createState() => _BreathingCoreState();
}

class _BreathingCoreState extends State<_BreathingCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.breathDuration,
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _BreathingCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breathDuration != widget.breathDuration) {
      _ctrl
        ..stop()
        ..duration = widget.breathDuration
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentFaint
              .withValues(alpha: AppColors.accentFaint.a * 0.40),
          border: Border.all(color: AppColors.borderIcon, width: 0.5),
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

class _FooterBlock extends StatelessWidget {
  const _FooterBlock({
    required this.remainingLabel,
    required this.onStartSpeaking,
    required this.onSubscription,
    required this.onVault,
  });

  final int? remainingLabel;
  final VoidCallback onStartSpeaking;
  final VoidCallback onSubscription;
  final VoidCallback onVault;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        children: [
          Text(
            remainingLabel == null
                ? 'Осталось сессий сегодня: …'
                : 'Осталось сессий сегодня: $remainingLabel',
            style: AppTextStyles.onboardingBody.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.92),
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: AppColors.accentDim.withValues(alpha: 0.2),
                  blurRadius: 18,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          PlumButton(
            label: 'начать говорить',
            onTap: onStartSpeaking,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PlumGhostButton(
                  label: 'Тарифы',
                  onTap: onSubscription,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PlumGhostButton(
                  label: 'Мой сейф',
                  onTap: onVault,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            AppColors.surfaceMid2.withValues(alpha: AppColors.surfaceMid2.a * 0.9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 18, color: AppColors.textBody),
            const SizedBox(width: 8),
            Text(
              'нет соединения',
              style: AppTextStyles.onboardingBody.copyWith(
                fontSize: 14,
                color: AppColors.textBody,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
