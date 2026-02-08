import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_models.dart';
import 'order_draft_controller.dart';
import 'order_providers.dart';

class OrderSubmitController extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order> submit() async {
    final draft = ref.read(orderDraftControllerProvider);
    final api = ref.read(customerOrdersApiProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return api.createOrder(draft.toCreatePayload());
    });

    return state.value!;
  }
}

final orderSubmitProvider =
    AsyncNotifierProvider<OrderSubmitController, Order?>(OrderSubmitController.new);
