import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Заглушка подписки (позже — ЮKassa).
class SubscriptionState {
  const SubscriptionState({
    this.isSubscribed = false,
    this.selectedPlan = 'month',
  });

  final bool isSubscribed;
  /// `'month'` или `'year'`.
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
    if (plan != 'month' && plan != 'year') return;
    state = state.copyWith(selectedPlan: plan);
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});
