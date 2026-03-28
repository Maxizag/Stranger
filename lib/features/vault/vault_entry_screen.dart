import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neznakomets/features/vault/vault_lock_screen.dart';
import 'package:neznakomets/features/vault/vault_provider.dart';
import 'package:neznakomets/features/vault/vault_screen.dart';

/// Оболочка сейфа: экран блокировки / список сессий.
class VaultEntryScreen extends ConsumerStatefulWidget {
  const VaultEntryScreen({super.key});

  @override
  ConsumerState<VaultEntryScreen> createState() => _VaultEntryScreenState();
}

class _VaultEntryScreenState extends ConsumerState<VaultEntryScreen> {
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(vaultProvider.notifier).tickLockTimer();
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(vaultProvider);
    if (s.vaultState == VaultState.unlocked) {
      return const VaultScreen();
    }
    return const VaultLockScreen();
  }
}
