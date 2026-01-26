import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../state/vendor_service_prices_repository.dart';
import '../state/services_repository.dart';
import '../../../../../../core/network/api_client.dart';     
import 'vendor_shop_option_prices_repository.dart'; 
 

final vendorServicePricesRepositoryProvider =
    Provider<VendorServicePricesRepository>((ref) {
  final api = ref.watch(apiClientProvider); // ✅ ApiClient
  return VendorServicePricesRepository(api);
});



final servicesRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);
  return ServicesRepository(api);
});

final servicesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.listServices();
});

final vendorServicePricesProvider = FutureProvider.family<List<Map<String, dynamic>>, ({int vendorId, int shopId})>(
  (ref, args) async {
    final repo = ref.watch(vendorServicePricesRepositoryProvider);
    return repo.list(vendorId: args.vendorId, shopId: args.shopId);
  },
);

// ✅ You must already have a Dio provider somewhere in your project.
// If yours is named differently, replace dioProvider below with your actual one.
final vendorShopOptionPricesRepositoryProvider =
    Provider<VendorShopOptionPricesRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return VendorShopOptionPricesRepository(api.dio);

});

 
final vendorServicePricesActionsProvider = Provider((ref) {
  final repo = ref.watch(vendorServicePricesRepositoryProvider);
  return _VendorServicePricesActions(repo, ref);
});

class _VendorServicePricesActions {
  _VendorServicePricesActions(this.repo, this.ref);
  final VendorServicePricesRepository repo;
  final Ref ref;

  Future<void> create(int vendorId, int shopId, Map<String, dynamic> payload) async {
    await repo.create(vendorId: vendorId, shopId: shopId, payload: payload);
    ref.invalidate(vendorServicePricesProvider((vendorId: vendorId, shopId: shopId)));
  }

  Future<void> update(int vendorId, int shopId, int id, Map<String, dynamic> payload) async {
    await repo.update(vendorId: vendorId, shopId: shopId, id: id, payload: payload);
    ref.invalidate(vendorServicePricesProvider((vendorId: vendorId, shopId: shopId)));
  }

  Future<void> delete(int vendorId, int shopId, int id) async {
    await repo.delete(vendorId: vendorId, shopId: shopId, id: id);
    ref.invalidate(vendorServicePricesProvider((vendorId: vendorId, shopId: shopId)));
  }
}

final vendorServiceOptionPricesActionsProvider =
    Provider<VendorServiceOptionPricesActions>((ref) {
  final repo = ref.watch(vendorShopOptionPricesRepositoryProvider);
  return VendorServiceOptionPricesActions(ref, repo);
});

class VendorServiceOptionPricesActions {
  VendorServiceOptionPricesActions(this.ref, this.repo);

  final Ref ref;
  final VendorShopOptionPricesRepository repo;

  void _invalidate(int vendorId, int shopId, int vendorServicePriceId) {
    ref.invalidate(
      vendorServiceOptionPricesProvider(
        OptionPricesKey(
          vendorId: vendorId,
          shopId: shopId,
          vendorServicePriceId: vendorServicePriceId,
        ),
      ),
    );
  }

  Future<void> upsert({
    required int vendorId,
    required int shopId,
    required int vendorServicePriceId,
    required int serviceOptionId,
    num? price,
    String? priceType,
    bool? isActive,
  }) async {
    await repo.upsertShopOptionPrice(
      vendorId: vendorId,
      shopId: shopId,
      vendorServicePriceId: vendorServicePriceId,
      serviceOptionId: serviceOptionId,
      price: price,
      priceType: priceType,
      isActive: isActive,
    );
    _invalidate(vendorId, shopId, vendorServicePriceId);
  }

  Future<void> update({
    required int vendorId,
    required int shopId,
    required int vendorServicePriceId,
    required int optionPriceId,
    num? price,
    String? priceType,
    bool? isActive,
  }) async {
    await repo.updateShopOptionPrice(
      vendorId: vendorId,
      shopId: shopId,
      optionPriceId: optionPriceId,
      price: price,
      priceType: priceType,
      isActive: isActive,
    );
    _invalidate(vendorId, shopId, vendorServicePriceId);
  }

  Future<void> delete({
    required int vendorId,
    required int shopId,
    required int vendorServicePriceId,
    required int optionPriceId,
  }) async {
    await repo.deleteShopOptionPrice(
      vendorId: vendorId,
      shopId: shopId,
      optionPriceId: optionPriceId,
    );
    _invalidate(vendorId, shopId, vendorServicePriceId);
  }
}
 


// ✅ Master Service Options (from service_options table)
// Only active options are returned.
final serviceOptionsProvider = FutureProvider<List<ServiceOptionLite>>((ref) async {
  final repo = ref.watch(vendorShopOptionPricesRepositoryProvider);
  return repo.listServiceOptions(onlyActive: true);
});

class OptionPricesKey {
  const OptionPricesKey({
    required this.vendorId,
    required this.shopId,
    required this.vendorServicePriceId,
  });

  final int vendorId;
  final int shopId;
  final int vendorServicePriceId;

  @override
  bool operator ==(Object other) =>
      other is OptionPricesKey &&
      vendorId == other.vendorId &&
      shopId == other.shopId &&
      vendorServicePriceId == other.vendorServicePriceId;

  @override
  int get hashCode => Object.hash(vendorId, shopId, vendorServicePriceId);
}

// ✅ you already have a Dio provider somewhere. Use YOUR existing one.
/*final vendorShopOptionPricesRepositoryProvider =
    Provider<VendorShopOptionPricesRepository>((ref) {
  final dio = ref.watch(dioProvider); // <-- replace with your real dio provider name
  return VendorShopOptionPricesRepository(dio);
});
*/

final vendorServiceOptionPricesProvider = FutureProvider.family<
    List<VendorServiceOptionPriceLite>, OptionPricesKey>((ref, key) async {
  final repo = ref.watch(vendorShopOptionPricesRepositoryProvider);
  return repo.listShopOptionPrices(
    vendorId: key.vendorId,
    shopId: key.shopId,
    vendorServicePriceId: key.vendorServicePriceId,
  );
});
