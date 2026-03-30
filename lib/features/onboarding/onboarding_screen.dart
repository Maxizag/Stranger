import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String onboardingCompleteKey = 'onboarding_complete';

  static Future<void> completeAndGoHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompleteKey, true);
    if (context.mounted) context.go('/');
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _SlideConfig {
  const _SlideConfig({
    required this.tag,
    required this.eyebrow,
    required this.titleBefore,
    required this.titleAccent,
    required this.body,
    required this.svgAsset,
  });

  final String tag;
  final String eyebrow;
  final String titleBefore;
  final String titleAccent;
  final String body;
  final String svgAsset;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_SlideConfig> _slides = [
    _SlideConfig(
      tag: '01',
      eyebrow: 'АНОНИМНОСТЬ',
      titleBefore: 'здесь нет\n',
      titleAccent: 'твоего имени',
      body:
          'Никакой регистрации, аккаунта или номера телефона. Ты просто приходишь и говоришь. Никто не знает, кто ты — и это даёт настоящую свободу.',
      svgAsset: 'assets/icons/lock.svg',
    ),
    _SlideConfig(
      tag: '02',
      eyebrow: 'СВОБОДА',
      titleBefore: 'закрыл и ',
      titleAccent: 'исчезло',
      body:
          'Как только сворачиваешь приложение — переписка удаляется навсегда. Ничего не сохраняется, ничего не передаётся. Только ты знаешь, что здесь было.',
      svgAsset: 'assets/icons/clock.svg',
    ),
    _SlideConfig(
      tag: '03',
      eyebrow: 'ЛИЧНЫЙ СЕЙФ',
      titleBefore: 'сохрани ',
      titleAccent: 'важное',
      body:
          'Если разговор оказался важным — сохрани его в личный сейф. Он защищён PIN-кодом и хранится только на твоём телефоне. Никто, кроме тебя, не имеет доступа.',
      svgAsset: 'assets/icons/lock.svg',
    ),
    _SlideConfig(
      tag: '04',
      eyebrow: 'НЕЗНАКОМЕЦ',
      titleBefore: 'легче говорить ',
      titleAccent: 'чужому',
      body:
          'Иногда проще сказать правду тому, кто тебя не знает. Без осуждения, без последствий, без памяти о прошлом. Просто говори.',
      svgAsset: 'assets/icons/info.svg',
    ),
  ];

  static const List<Color> _glowColors = [
    AppColors.glowSlide0,
    AppColors.glowSlide1,
    AppColors.glowSlide2,
    AppColors.glowSlide0,
  ];

  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageTick);
  }

  void _onPageTick() {
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageTick);
    _pageController.dispose();
    super.dispose();
  }

  double get _pageFloat {
    if (!_pageController.hasClients) return _page.toDouble();
    return _pageController.page ?? _page.toDouble();
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(155 * math.pi / 180),
          colors: const [
            AppColors.bgGradStart,
            AppColors.bgGradMid1,
            AppColors.bgGradMid2,
            AppColors.bgGradEnd,
          ],
          stops: const [0.0, 0.20, 0.55, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_page < 3)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              OnboardingScreen.completeAndGoHome(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            'пропустить',
                            style: AppTextStyles.skip,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final page = _pageFloat;
                    final delta = page - index;
                    final opacity = (1.0 - delta.abs()).clamp(0.0, 1.0);
                    final translate = delta * 56.0;
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(translate, 0),
                        child: _PlumOnboardingSlide(
                          glowColor: _glowColors[index],
                          config: _slides[index],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isActive = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(right: 7),
                    width: isActive ? 26.0 : 6.0,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.dotActive
                          : AppColors.dotInactive,
                      borderRadius:
                          BorderRadius.circular(isActive ? 3 : 50),
                      border: isActive
                          ? null
                          : Border.all(
                              color: AppColors.borderRing1,
                              width: 0.5,
                            ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _page < 3 ? _ghostButton() : _solidButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ghostButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.btnGhostBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentFaint.withValues(alpha: 0.16),
          width: 0.5,
        ),
      ),
      child: TextButton(
        onPressed: _next,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.btnGhostText,
          minimumSize: const Size(double.infinity, 58),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          'далее',
          style: AppTextStyles.button.copyWith(
            color: AppColors.btnGhostText,
          ),
        ),
      ),
    );
  }

  Widget _solidButton(BuildContext context) {
    return Container(
      height: 58,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF501E32).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () => OnboardingScreen.completeAndGoHome(context),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.btnSolidText,
          minimumSize: const Size(double.infinity, 58),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text('понятно, начать', style: AppTextStyles.button),
      ),
    );
  }
}

class _PlumOnboardingSlide extends StatefulWidget {
  const _PlumOnboardingSlide({
    required this.glowColor,
    required this.config,
  });

  final Color glowColor;
  final _SlideConfig config;

  @override
  State<_PlumOnboardingSlide> createState() => _PlumOnboardingSlideState();
}

class _PlumOnboardingSlideState extends State<_PlumOnboardingSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.glowColor.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  c.tag,
                  style: AppTextStyles.slideTag,
                ),
              ),
              const SizedBox(height: 8),
              const Spacer(flex: 1),
              Center(
                child: Text(
                  c.eyebrow,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.eyebrow,
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.onboardingTitle.copyWith(
                    fontSize: 24,
                    color: AppColors.textBody.withValues(alpha: 0.5),
                  ),
                  children: [
                    TextSpan(text: c.titleBefore),
                    TextSpan(
                      text: c.titleAccent,
                      style: AppTextStyles.onboardingTitleAccent.copyWith(
                        fontSize: 24,
                        color: AppColors.accentDim.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(child: _iconRings()),
              const SizedBox(height: 12),
              Text(
                c.body,
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingBody.copyWith(fontSize: 18),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconRings() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.glowColor.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.borderRing1.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.glowColor.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.borderRing1.withValues(alpha: 0.18),
                width: 0.5,
              ),
            ),
          ),
          Container(
            width: 164,
            height: 164,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.glowColor.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.borderRing1.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
          ),
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.glowColor.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.borderRing1.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
          ),
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.035).animate(
              CurvedAnimation(parent: _breathe, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentFaint.withValues(alpha: 0.55),
                border: Border.all(
                  color: AppColors.borderIcon,
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                widget.config.svgAsset,
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  AppColors.accent,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
