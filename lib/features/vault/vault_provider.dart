import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neznakomets/models/message.dart';
import 'package:neznakomets/models/vault_session.dart';
import 'package:neznakomets/services/vault_service.dart';

enum VaultState { locked, unlocked, pinSetup }

final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService();
});

class VaultUiState {
  const VaultUiState({
    required this.vaultState,
    this.sessions = const [],
    this.failedAttempts = 0,
    this.isLocked = false,
    this.lockRemainingSeconds = 0,
  });

  final VaultState vaultState;
  final List<VaultSession> sessions;
  final int failedAttempts;
  final bool isLocked;
  final int lockRemainingSeconds;

  VaultUiState copyWith({
    VaultState? vaultState,
    List<VaultSession>? sessions,
    int? failedAttempts,
    bool? isLocked,
    int? lockRemainingSeconds,
  }) {
    return VaultUiState(
      vaultState: vaultState ?? this.vaultState,
      sessions: sessions ?? this.sessions,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
      lockRemainingSeconds: lockRemainingSeconds ?? this.lockRemainingSeconds,
    );
  }
}

class VaultNotifier extends StateNotifier<VaultUiState> {
  VaultNotifier(this._vault) : super(const VaultUiState(vaultState: VaultState.locked)) {
    _bootstrap();
  }

  final VaultService _vault;
  String? _cachedPin;

  Future<void> _bootstrap() async {
    final has = await _vault.hasPIN();
    state = _syncLockFromService().copyWith(
      vaultState: has ? VaultState.locked : VaultState.pinSetup,
    );
  }

  VaultUiState _syncLockFromService() {
    return state.copyWith(
      failedAttempts: _vault.failedAttempts,
      isLocked: _vault.isLocked(),
      lockRemainingSeconds: _vault.lockRemainingSeconds(),
    );
  }

  void tickLockTimer() {
    if (!_vault.isLocked()) {
      if (state.isLocked || state.lockRemainingSeconds > 0) {
        state = _syncLockFromService();
      }
      return;
    }
    state = _syncLockFromService();
  }

  /// PIN в памяти для расшифровки без повторного ввода после успешного входа по PIN.
  String? get cachedPin => _cachedPin;

  /// После успешного `loadMessagesForSession` по PIN из диалога — для автосохранения чата при паузе.
  void cachePinAfterSuccessfulDecrypt(String pin) {
    if (pin.length == 6 && RegExp(r'^\d{6}$').hasMatch(pin)) {
      _cachedPin = pin;
    }
  }

  Future<bool> submitPIN(String pin) async {
    if (pin.length != 6) return false;
    if (_vault.isLocked()) {
      state = _syncLockFromService();
      return false;
    }
    final ok = await _vault.verifyPIN(pin);
    if (ok) {
      _cachedPin = pin;
      final sessions = await _vault.loadSessionsMetadata();
      state = VaultUiState(
        vaultState: VaultState.unlocked,
        sessions: sessions,
        failedAttempts: 0,
        isLocked: false,
        lockRemainingSeconds: 0,
      );
      return true;
    }
    state = _syncLockFromService();
    return false;
  }

  Future<void> setupPIN(String pin) async {
    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) return;
    await _vault.setPIN(pin);
    _cachedPin = pin;
    final sessions = await _vault.loadSessionsMetadata();
    state = VaultUiState(
      vaultState: VaultState.unlocked,
      sessions: sessions,
      failedAttempts: 0,
      isLocked: false,
      lockRemainingSeconds: 0,
    );
  }

  Future<void> deleteSession(String id) async {
    await _vault.deleteSession(id);
    final sessions = await _vault.loadSessionsMetadata();
    state = state.copyWith(sessions: sessions);
  }

  void lock() {
    _cachedPin = null;
    state = VaultUiState(
      vaultState: VaultState.locked,
      sessions: const [],
      failedAttempts: _vault.failedAttempts,
      isLocked: _vault.isLocked(),
      lockRemainingSeconds: _vault.lockRemainingSeconds(),
    );
  }

  Future<List<Message>> loadMessagesForSession(String sessionId, String pin) {
    return _vault.loadSessionMessages(sessionId, pin);
  }

  Future<void> saveChatSession(List<Message> messages, String pin) async {
    await _vault.saveSession(messages, pin);
    final sessions = await _vault.loadSessionsMetadata();
    state = state.copyWith(sessions: sessions);
  }

  Future<bool> hasPIN() => _vault.hasPIN();

  Future<bool> pinMatches(String pin) => _vault.pinMatches(pin);
}

final vaultProvider =
    StateNotifierProvider<VaultNotifier, VaultUiState>((ref) {
  return VaultNotifier(ref.watch(vaultServiceProvider));
});
