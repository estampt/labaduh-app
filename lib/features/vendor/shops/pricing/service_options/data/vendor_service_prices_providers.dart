import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/vendor_service_prices_repository.dart';
import '../state/services_repository.dart';
import '../../../../../../core/network/api_client.dart';     
 
final vendorServicePricesRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);
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
