import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/app/theme.dart';
import 'package:neznakomets/features/vault/vault_provider.dart';

class VaultLockScreen extends ConsumerStatefulWidget {
  const VaultLockScreen({super.key});

  @override
  ConsumerState<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends ConsumerState<VaultLockScreen> {
  String _pin = '';
  String? _firstPinSetup;
  int _setupStep = 0;

  void _addDigit(String d) {
    final s = ref.read(vaultProvider);
    if (s.isLocked) return;
    if (s.vaultState == VaultState.biometricPrompt) return;
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
          const SnackBar(content: Text('PIN не совпадает. Попробуй снова.')),
        );
      }
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
    } else if (mounted) {
      setState(() => _pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('неверный PIN')),
      );
    }
  }

  Future<void> _onBiometric() async {
    await ref.read(vaultProvider.notifier).authenticateWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(vaultProvider);
    final isSetup = s.vaultState == VaultState.pinSetup;
    final biometricFuture = ref.watch(_biometricAvailableProvider);

    return Scaffold(
      backgroundColor: NeznakometsColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: NeznakometsColors.textPrimary),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.lock_outline,
                size: 56,
                color: NeznakometsColors.accent,
              ),
              const SizedBox(height: 20),
              Text(
                'твой сейф',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: NeznakometsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSetup
                    ? (_setupStep == 0
                        ? 'придумай PIN из 6 цифр'
                        : 'повтори PIN')
                    : 'только ты видишь это',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: NeznakometsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              if (s.isLocked) ...[
                Text(
                  'попробуй через ${s.lockRemainingSeconds} с',
                  style: const TextStyle(
                    fontSize: 15,
                    color: NeznakometsColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (s.vaultState == VaultState.biometricPrompt)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: NeznakometsColors.accent),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? NeznakometsColors.accent
                          : NeznakometsColors.textSecondary.withValues(alpha: 0.35),
                    ),
                  );
                }),
              ),
              const Spacer(),
              _Keypad(
                onDigit: _addDigit,
                onBackspace: _backspace,
                enabled: !s.isLocked && s.vaultState != VaultState.biometricPrompt,
              ),
              const SizedBox(height: 12),
              biometricFuture.when(
                data: (available) {
                  if (!available || isSetup) return const SizedBox(height: 48);
                  return SizedBox(
                    height: 48,
                    child: TextButton.icon(
                      onPressed: s.isLocked || s.vaultState == VaultState.biometricPrompt
                          ? null
                          : _onBiometric,
                      icon: const Icon(Icons.fingerprint, color: NeznakometsColors.accent),
                      label: const Text(
                        'биометрия',
                        style: TextStyle(
                          fontSize: 15,
                          color: NeznakometsColors.accent,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(height: 48),
                error: (Object? e, StackTrace? st) =>
                    const SizedBox(height: 48),
              ),
              if (isSetup)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: (_pin.length == 6 && !s.isLocked)
                          ? _submitSetup
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: NeznakometsColors.accent,
                        foregroundColor: const Color(0xFF1A1040),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _setupStep == 0 ? 'далее' : 'сохранить',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: (_pin.length == 6 && !s.isLocked)
                          ? _submitUnlock
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: NeznakometsColors.accent,
                        foregroundColor: const Color(0xFF1A1040),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'войти',
                        style: TextStyle(fontSize: 15),
                      ),
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
    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((k) {
              if (k.isEmpty) {
                return const SizedBox(width: 72, height: 52);
              }
              if (k == '⌫') {
                return _KeyCell(
                  label: k,
                  onTap: enabled ? onBackspace : null,
                );
              }
              return _KeyCell(
                label: k,
                onTap: enabled ? () => onDigit(k) : null,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: onTap == null
                  ? NeznakometsColors.textSecondary.withValues(alpha: 0.4)
                  : NeznakometsColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

final _biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(vaultServiceProvider).isBiometricAvailable();
});
