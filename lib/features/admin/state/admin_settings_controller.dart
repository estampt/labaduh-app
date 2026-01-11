import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSettingsState {
  const AdminSettingsState({
    this.platformFeePct = 5,
    this.matchingEnabled = true,
    this.vendorSubscriptionEnabled = true,
  });

  final int platformFeePct;
  final bool matchingEnabled;
  final bool vendorSubscriptionEnabled;

  AdminSettingsState copyWith({int? platformFeePct, bool? matchingEnabled, bool? vendorSubscriptionEnabled}) {
    return AdminSettingsState(
      platformFeePct: platformFeePct ?? this.platformFeePct,
      matchingEnabled: matchingEnabled ?? this.matchingEnabled,
      vendorSubscriptionEnabled: vendorSubscriptionEnabled ?? this.vendorSubscriptionEnabled,
    );
  }
}

final adminSettingsProvider = StateNotifierProvider<AdminSettingsController, AdminSettingsState>((ref) {
  return AdminSettingsController();
});

class AdminSettingsController extends StateNotifier<AdminSettingsState> {
  AdminSettingsController() : super(const AdminSettingsState());

  void setFeePct(int v) => state = state.copyWith(platformFeePct: v.clamp(0, 30));
  void setMatching(bool v) => state = state.copyWith(matchingEnabled: v);
  void setSubscription(bool v) => state = state.copyWith(vendorSubscriptionEnabled: v);
}
