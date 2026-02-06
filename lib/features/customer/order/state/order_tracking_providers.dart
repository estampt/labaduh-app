import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customer_order_repo.dart';
import '../data/dtos/customer_order_show_dto.dart';

/// ✅ single source of truth for current order being tracked
final currentOrderIdProvider = StateProvider<int?>((_) => null);

/// Change polling here (battery vs responsiveness)
const matchingPollInterval = Duration(seconds: 8);
const trackingPollInterval = Duration(minutes: 1);

/// Polling stream provider (autoDispose)
final orderPollingProvider = StreamProvider.autoDispose.family<CustomerOrderShowDto, ({int orderId, Duration interval})>(
  (ref, args) async* {
    while (true) {
      yield await ref.read(customerOrderRepoProvider).getOrder(args.orderId);
      await Future.delayed(args.interval);
    }
  },
);

/// Pricing decision command (approve/reject)
final pricingDecisionProvider = AutoDisposeAsyncNotifierProvider<PricingDecisionController, void>(
  PricingDecisionController.new,
);

class PricingDecisionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> approve(int orderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(customerOrderRepoProvider).approveFinal(orderId);
    });
  }

  Future<void> reject(int orderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(customerOrderRepoProvider).rejectFinal(orderId);
    });
  }
}
