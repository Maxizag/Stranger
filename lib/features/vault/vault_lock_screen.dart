import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';
import 'package:neznakomets/core/widgets/plum_ui.dart';
import 'package:neznakomets/features/vault/vault_provider.dart';

class VaultLockScreen extends ConsumerStatefulWidget {
  const VaultLockScreen({super.key});

  @override
  ConsumerState<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends ConsumerState<VaultLockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _firstPinSetup;
  int _setupStep = 0;

  bool _pinError = false;

  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _shakeX = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.0, end: -10.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: -10.0, end: 10.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 10.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
  ]).animate(_shakeCtrl);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _shakePinError() async {
    if (!mounted) return;
    setState(() => _pinError = true);
    _shakeCtrl.reset();
    await _shakeCtrl.forward();
    if (!mounted) return;
    setState(() => _pinError = false);
  }

  void _addDigit(String d) {
    final s = ref.read(vaultProvider);
    if (s.isLocked) return;
    if (_pin.length >= 6) return;
    setState(() => _pin += d);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submitSetup() async {
    if (_pin.length != 6) return;
    final vs = ref.read(vaultProvider);
    if (vs.vaultState != VaultState.pinSetup) return;

    if (_setupStep == 0) {
      setState(() {
        _firstPinSetup = _pin;
        _pin = '';
        _setupStep = 1;
      });
      return;
    }

    if (_pin != _firstPinSetup) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PIN не совпадает. Попробуй снова.',
              style: AppTextStyles.onboardingBody.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }
      await _shakePinError();
      if (!mounted) return;
      setState(() {
        _pin = '';
        _firstPinSetup = null;
        _setupStep = 0;
      });
      return;
    }

    await ref.read(vaultProvider.notifier).setupPIN(_pin);
    if (mounted) {
      setState(() {
        _pin = '';
        _firstPinSetup = null;
        _setupStep = 0;
      });
    }
  }

  Future<void> _submitUnlock() async {
    if (_pin.length != 6) return;
    final ok = await ref.read(vaultProvider.notifier).submitPIN(_pin);
    if (ok) {
      setState(() => _pin = '');
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'неверный PIN',
          style: AppTextStyles.onboardingBody.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
    await _shakePinError();
    if (!mounted) return;
    setState(() => _pin = '');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(vaultProvider);
    final isSetup = s.vaultState == VaultState.pinSetup;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1.0),
            end: Alignment(0.8, 1.0),
            colors: [
              AppColors.surfaceStart,
              AppColors.surfaceMid1,
              AppColors.surfaceMid2,
              AppColors.surfaceEnd,
            ],
            stops: [0.0, 0.30, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PlumBackButton(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.glowSlide0
                                      .withValues(alpha: 0.08),
                                  AppColors.glowSlide0
                                      .withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentFaint
                                  .withValues(alpha: 0.35),
                              border: Border.all(
                                color: AppColors.borderIcon,
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.accent,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Твой сейф',
                        style: AppTextStyles.onboardingTitle.copyWith(
                          fontSize: 24,
                          color: AppColors.accent.withValues(alpha: 0.95),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      Text(
                        isSetup
                            ? (_setupStep == 0
                                ? 'придумай PIN из 6 цифр'
                                : 'повтори PIN')
                            : 'Здесь хранится только твоё',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingBody.copyWith(
                          fontSize: 20,
                          color: AppColors.textBody,
                        ),
                      ),
                      const SizedBox(height: 36),
                      if (s.isLocked) ...[
                        Text(
                          'попробуй через ${s.lockRemainingSeconds} с',
                          style: AppTextStyles.onboardingBody.copyWith(
                            fontSize: 15,
                            color: AppColors.accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Если биометрия уже запущена (только по явному действию пользователя),
                      // системный диалог перекрывает экран — отдельный индикатор не нужен.
                      AnimatedBuilder(
                        animation: _shakeX,
                        builder: (ctx, child) {
                          return Transform.translate(
                            offset: Offset(_shakeX.value, 0),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            final filled = i < _pin.length;
                            final double size = filled ? 14.0 : 12.0;
                            final bool errorDot = filled && _pinError;
                            return AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled
                                    ? (errorDot
                                        ? AppColors.crisisCardBorder
                                        : AppColors.accent)
                                    : AppColors.btnGhostBg.withValues(
                                        alpha: 0.0,
                                      ),
                                border: Border.all(
                                  color: filled
                                      ? (errorDot
                                          ? AppColors.crisisCardBorder
                                          : AppColors.accent)
                                      : AppColors.borderRing1
                                          .withValues(alpha: 0.6),
                                  width: filled ? 0 : 1.0,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _Keypad(
                        onDigit: _addDigit,
                        onBackspace: _backspace,
                        enabled: !s.isLocked,
                      ),
                      const SizedBox(height: 8),
                      _PinCta(
                        isSetup: isSetup,
                        setupStep: _setupStep,
                        pinLength: _pin.length,
                        isLocked: s.isLocked,
                        onTap: isSetup
                            ? _submitSetup
                            : _submitUnlock,
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

class _PinCta extends StatelessWidget {
  const _PinCta({
    required this.isSetup,
    required this.setupStep,
    required this.pinLength,
    required this.isLocked,
    required this.onTap,
  });

  final bool isSetup;
  final int setupStep;
  final int pinLength;
  final bool isLocked;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isReady = pinLength == 6 && !isLocked;
    final label = isSetup
        ? (setupStep == 0 ? 'далее' : 'сохранить')
        : 'войти';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      child: GestureDetector(
        onTap: isReady
            ? () {
                onTap();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 54,
          decoration: BoxDecoration(
            gradient: isReady
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.btnSolidStart,
                      AppColors.btnSolidMid,
                      AppColors.btnSolidEnd,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  )
                : null,
            color: isReady ? null : AppColors.btnGhostBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isReady
                  ? AppColors.accent.withValues(alpha: 0.22)
                  : AppColors.borderRing1,
              width: 0.5,
            ),
            boxShadow: isReady
                ? [
                    BoxShadow(
                      color:
                          AppColors.btnSolidShadow.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              fontSize: 18,
              color: isReady ? AppColors.btnSolidText : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.enabled,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: row.asMap().entries.map((e) {
                final i = e.key;
                final k = e.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 0 : 5,
                      right: i == 2 ? 0 : 5,
                    ),
                    child: k.isEmpty
                        ? const SizedBox(height: 68)
                        : _KeyCell(
                            label: k,
                            onTap: k == '⌫'
                                ? (enabled ? onBackspace : null)
                                : (enabled ? () => onDigit(k) : null),
                          ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.accent.withValues(alpha: 0.12),
        highlightColor: AppColors.accent.withValues(alpha: 0.07),
        child: Ink(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceEnd.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.borderRing1.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: label == '⌫'
                ? Icon(
                    Icons.backspace_outlined,
                    color: enabled
                        ? AppColors.textBody
                        : AppColors.textMuted.withValues(alpha: 0.4),
                    size: 22,
                  )
                : Text(
                    label,
                    style: AppTextStyles.numerals.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// MVP: биометрия отключена.
