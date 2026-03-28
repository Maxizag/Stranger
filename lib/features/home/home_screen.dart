import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/features/home/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF161616);
  static const Color _accent = Color(0xFFC8B8FF);
  static const Color _textPrimary = Color(0xFFE8E8E8);
  static const Color _textMuted = Color(0xFF555555);
  static const Color _btnPrimaryFg = Color(0xFF1A1040);
  static const Color _ghostBorder = Color(0xFF2A2A2A);

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
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'бесплатно доступно 3 сессии в день',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'осталось сессий сегодня: $remainingToday',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _btnPrimaryFg,
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('понятно'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push('/subscription');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textMuted,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      side: const BorderSide(color: _ghostBorder, width: 0.5),
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

    final countLabel = asyncCount.when(
      data: (n) => _formatThousands(n),
      loading: () => '...',
      error: (Object? e, StackTrace? st) => '—',
    );

    final remainingLabel = _remainingSessions;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (offline) const _OfflineBanner(),
              const SizedBox(height: 8),
              Text(
                'незнакомец',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'скажи то, что не скажешь никому',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        countLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: _accent,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'сегодня сказали то, что не могли сказать никому',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onStartSpeaking,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _btnPrimaryFg,
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('начать говорить'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                remainingLabel == null
                    ? 'осталось сессий сегодня: …'
                    : 'осталось сессий сегодня: $remainingLabel',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () async {
                          await context.push('/subscription');
                          if (mounted) _refreshRemaining();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textMuted,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          side: const BorderSide(
                            color: _ghostBorder,
                            width: 0.5,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('подписка'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () async {
                          await context.push('/vault');
                          if (mounted) _refreshRemaining();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textMuted,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          side: const BorderSide(
                            color: _ghostBorder,
                            width: 0.5,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('мой сейф'),
                      ),
                    ),
                  ),
                ],
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  static const Color _bg = Color(0xFF161616);
  static const Color _fg = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _bg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 18, color: _fg),
            const SizedBox(width: 8),
            Text(
              'нет соединения',
              style: TextStyle(
                fontSize: 14,
                color: _fg,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
