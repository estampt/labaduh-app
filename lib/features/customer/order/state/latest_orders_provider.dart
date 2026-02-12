import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/latest_orders_models.dart';
import 'order_providers.dart';

/// Holds current list + cursor
class LatestOrdersState {
  final List<LatestOrder> orders;
  final String? cursor;
  final bool isLoadingMore;

  const LatestOrdersState({
    required this.orders,
    required this.cursor,
    required this.isLoadingMore,
  });

  LatestOrdersState copyWith({
    List<LatestOrder>? orders,
    String? cursor,
    bool? isLoadingMore,
  }) {
    return LatestOrdersState(
      orders: orders ?? this.orders,
      cursor: cursor ?? this.cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class LatestOrdersController extends AsyncNotifier<LatestOrdersState> {
  @override
  Future<LatestOrdersState> build() async {
    final api = ref.read(customerOrdersApiProvider);
    final res = await api.latestOrders();
    return LatestOrdersState(
      orders: res.data,
      cursor: res.cursor,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(customerOrdersApiProvider);
      final res = await api.latestOrders();
      return LatestOrdersState(
        orders: res.data,
        cursor: res.cursor,
        isLoadingMore: false,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    if (current.isLoadingMore) return;
    if (current.cursor == null) return;

    // mark loading more
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    final api = ref.read(customerOrdersApiProvider);
    try {
      final res = await api.latestOrders(cursor: current.cursor);

      // append
      final merged = [...current.orders, ...res.data];
      state = AsyncValue.data(
        LatestOrdersState(
          orders: merged,
          cursor: res.cursor,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      // revert loading more flag but keep current list
      state = AsyncValue.error(e, st);
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }
}

final latestOrdersProvider =
    AsyncNotifierProvider<LatestOrdersController, LatestOrdersState>(
        LatestOrdersController.new);


/// Completed orders (history) - fetched once on demand (no polling).
final completedOrdersProvider = FutureProvider.autoDispose<List<LatestOrder>>((ref) async {
  final api = ref.read(customerOrdersApiProvider);
  final res = await api.listOrders(status: 'closed');
  return res.data;
});
