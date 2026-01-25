import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/vendor_shop_option_prices_repository.dart';

// ✅ Reuse your existing Dio provider.
// If you already have `dioProvider`, use that.
// Otherwise, replace this provider with `ref.read(apiClientProvider).dio`.
final dioProvider = Provider<Dio>((ref) {
  throw UnimplementedError('Plug in your Dio instance here (reuse your existing dioProvider).');
});

final vendorShopOptionPricesRepositoryProvider = Provider<VendorShopOptionPricesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VendorShopOptionPricesRepository(dio);
});

final vendorShopOptionPricesProvider = FutureProvider.family<
    List<VendorServiceOptionPriceLite>,
    ({int vendorId, int shopId})>((ref, args) async {
  final repo = ref.watch(vendorShopOptionPricesRepositoryProvider);
  return repo.listShopOptionPrices(vendorId: args.vendorId, shopId: args.shopId);
});

final serviceOptionsProvider = FutureProvider<List<ServiceOptionLite>>((ref) async {
  final repo = ref.watch(vendorShopOptionPricesRepositoryProvider);
  return repo.listServiceOptions(onlyActive: true);
});

final vendorShopOptionPricesActionsProvider = Provider<VendorShopOptionPricesActions>((ref) {
  final repo = ref.watch(vendorShopOptionPricesRepositoryProvider);
  return VendorShopOptionPricesActions(ref, repo);
});

class VendorShopOptionPricesActions {
  VendorShopOptionPricesActions(this._ref, this._repo);
  final Ref _ref;
  final VendorShopOptionPricesRepository _repo;

  Future<void> upsert({
    required int vendorId,
    required int shopId,
    required int serviceOptionId,
    num? price,
    String? priceType,
    bool? isActive,
  }) async {
    await _repo.upsertShopOptionPrice(
      vendorId: vendorId,
      shopId: shopId,
      serviceOptionId: serviceOptionId,
      price: price,
      priceType: priceType,
      isActive: isActive,
    );
    _ref.invalidate(vendorShopOptionPricesProvider((vendorId: vendorId, shopId: shopId)));
  }

  Future<void> update({
    required int vendorId,
    required int shopId,
    required int optionPriceId,
    num? price,
    String? priceType,
    bool? isActive,
  }) async {
    await _repo.updateShopOptionPrice(
      vendorId: vendorId,
      shopId: shopId,
      optionPriceId: optionPriceId,
      price: price,
      priceType: priceType,
      isActive: isActive,
    );
    _ref.invalidate(vendorShopOptionPricesProvider((vendorId: vendorId, shopId: shopId)));
  }

  Future<void> delete({
    required int vendorId,
    required int shopId,
    required int optionPriceId,
  }) async {
    await _repo.deleteShopOptionPrice(
      vendorId: vendorId,
      shopId: shopId,
      optionPriceId: optionPriceId,
    );
    _ref.invalidate(vendorShopOptionPricesProvider((vendorId: vendorId, shopId: shopId)));
  }
}
