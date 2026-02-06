import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customer_order_repo.dart';
import 'order_tracking_providers.dart';
import 'order_draft_controller.dart';

final orderSubmitProvider =
    AutoDisposeAsyncNotifierProvider<OrderSubmitController, int?>(
        OrderSubmitController.new);

class OrderSubmitController
    extends AutoDisposeAsyncNotifier<int?> {
  @override
  Future<int?> build() async => null;

  Future<int> submit() async {
    state = const AsyncLoading();

    final draft = ref.read(orderDraftProvider);

    final payload = {
      'search_lat': 1.3001,
      'search_lng': 103.8001,
      'radius_km': 3,

      'pickup_mode': 'tomorrow',
      'pickup_window_start': null,
      'pickup_window_end': null,

      'delivery_mode': 'pickup_deliver',

      'pickup_address_id': 10,
      'delivery_address_id': 10,

      'pickup_address_snapshot': null,
      'delivery_address_snapshot': null,

      'notes': null,

      'items': draft.toItemsPayload(),
    };

    final repo = ref.read(customerOrderRepoProvider);

    await repo.createQuote(payload);
    final created = await repo.createOrder(payload);

    final orderId = created['id'] as int;

    ref.read(currentOrderIdProvider.notifier).state =
        orderId;

    state = AsyncData(orderId);
    return orderId;
  }
}
