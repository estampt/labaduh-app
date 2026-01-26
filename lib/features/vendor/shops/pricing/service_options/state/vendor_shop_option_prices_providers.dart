import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../data/vendor_shop_option_prices_repository.dart'; 

import 'package:labaduh/core/network/dio_provider.dart'; 


final vendorShopOptionPricesRepositoryProvider =
    Provider<VendorShopOptionPricesRepository>((ref) {
  final dio = ref.watch(dioProvider); // ✅ comes from dio_provider.dart
  return VendorShopOptionPricesRepository(dio);
});


final vendorShopOptionPricesProvider = FutureProvider.family<
    List<VendorServiceOptionPriceLite>,
    ({int vendorId, int shopId, int vendorServicePriceId})>((ref, args) async {
  final repo = ref.watch(vendorShopOptionPricesRepositoryProvider);

  return repo.listShopOptionPrices(
    vendorId: args.vendorId,
    shopId: args.shopId,
    vendorServicePriceId: args.vendorServicePriceId, // ✅ required
  );
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
      vendorServicePriceId: serviceOptionId, // ✅ REQUIRED
      serviceOptionId: serviceOptionId,
      price: price,
      priceType: priceType,
      isActive: isActive,
    );

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
    _ref.invalidate(
    vendorShopOptionPricesProvider((
      vendorId: vendorId,
      shopId: shopId,
      vendorServicePriceId: optionPriceId, // ✅ REQUIRED
    )),
  );

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
    _ref.invalidate(vendorShopOptionPricesProvider((vendorId: vendorId, shopId: shopId, vendorServicePriceId: optionPriceId)));
  }
}
