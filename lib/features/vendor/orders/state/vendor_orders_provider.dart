// vendor_orders_provider.dart
//
// Riverpod provider layer for vendor orders.
// - VendorOrderRepository provider
// - FutureProvider.family for active orders (loading/error/data)
// - Easy refresh via ref.refresh(...)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:labaduh/core/auth/session_notifier.dart';

import '../../../../core/network/api_client.dart';
import '../model/vendor_order_model.dart';
import '../data/vendor_orders_repository.dart';

typedef VendorShopParams = ({int vendorId, int shopId});

final vendorOrderRepositoryProvider = Provider<VendorOrderRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return VendorOrderRepository(api);
});

/// ✅ UI consumes this:
/// ref.watch(vendorOrdersProvider((vendorId: 2, shopId: 2)))
final vendorOrdersProvider =
    FutureProvider.family<List<VendorOrderModel>, VendorShopParams>((ref, params) async {
  final repo = ref.watch(vendorOrderRepositoryProvider);
  final list = await repo.getActiveOrders(
    vendorId: params.vendorId,
    shopId: params.shopId,
  );

  return list ?? <VendorOrderModel>[];
});

/// Active shop orders (no need to pass params everywhere)
final activeVendorOrdersProvider = FutureProvider<List<VendorOrderModel>>((ref) async {
  final session = ref.watch(sessionNotifierProvider);

  // VendorShopParams is a RECORD in your code:
  // typedef VendorShopParams = ({int vendorId, int shopId});
  final params = (vendorId: session.vendorId, shopId: session.activeShopId);

  // Wait for the family provider result
  return ref.watch(vendorOrdersProvider(params as VendorShopParams).future);
});
