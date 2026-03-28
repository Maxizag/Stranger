import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _accent = Color(0xFFC8B8FF);
  static const Color _body = Color(0xFF555555);
  static const Color _dotInactive = Color(0xFF2A2A2A);
  static const Color _btnPrimaryFg = Color(0xFF1A1040);

  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_page < 2)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            OnboardingScreen.completeAndGoHome(context),
                        child: const Text(
                          'пропустить',
                          style: TextStyle(
                            fontSize: 15,
                            color: _body,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _OnboardingPage(
                    icon: Icons.lock_outline,
                    title: 'здесь нет твоего имени',
                    body:
                        'Никакой регистрации, никакого email. Только ты и разговор.',
                  ),
                  _OnboardingPage(
                    icon: Icons.hourglass_empty,
                    title: 'разговор исчезнет',
                    body:
                        'После закрытия приложения переписка удаляется навсегда. Хочешь сохранить — есть личный сейф.',
                  ),
                  _OnboardingPage(
                    icon: Icons.info_outline,
                    title: 'как работает AI',
                    body:
                        'Твои сообщения обрабатывает GigaChat от Сбера по их политике конфиденциальности. Мы не храним переписку, но Сбер видит запросы.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _page;
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? _accent : _dotInactive,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _page < 2
                  ? SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _next,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _body,
                          side: const BorderSide(color: _dotInactive, width: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'далее',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () =>
                            OnboardingScreen.completeAndGoHome(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _btnPrimaryFg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'понятно, начать',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  static const Color _accent = Color(0xFFC8B8FF);
  static const Color _title = Color(0xFFE8E8E8);
  static const Color _body = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(icon, size: 64, color: _accent),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: _title,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: _body,
            ),
          ),
        ],
      ),
    );
  }
}
