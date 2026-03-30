import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Заглушка тарифа (позже — ЮKassa).
class SubscriptionState {
  const SubscriptionState({
    // TODO: убрать перед релизом — вернуть isSubscribed: false
    this.isSubscribed = true,
    this.selectedPlan = 'ultra',
  });

  final bool isSubscribed;
  /// `'echo'`, `'voice'` или `'ultra'`.
  final String selectedPlan;

  SubscriptionState copyWith({
    bool? isSubscribed,
    String? selectedPlan,
  }) {
    return SubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      selectedPlan: selectedPlan ?? this.selectedPlan,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  void selectPlan(String plan) {
    if (plan != 'echo' && plan != 'voice' && plan != 'ultra') return;
    state = state.copyWith(selectedPlan: plan);
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});
