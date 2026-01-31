import 'package:flutter_riverpod/flutter_riverpod.dart'; 

import '../data/shop_services_dtos.dart';
import '../data/shop_services_repository.dart';
import '../../../../../core/network/api_client.dart';
 
final shopServicesRepositoryProvider = Provider<ShopServicesRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ShopServicesRepository(api);
});


final shopServicesProvider = StateNotifierProvider.autoDispose<
    ShopServicesNotifier, AsyncValue<List<ShopServiceDto>>>((ref) {
  final repo = ref.read(shopServicesRepositoryProvider);
  return ShopServicesNotifier(repo);
});

class ShopServicesNotifier
    extends StateNotifier<AsyncValue<List<ShopServiceDto>>> {
  ShopServicesNotifier(this._repo) : super(const AsyncValue.loading());

  final ShopServicesRepository _repo;

  int? _vendorId;
  int? _shopId;

  Future<void> load({required int vendorId, required int shopId}) async {
    _vendorId = vendorId;
    _shopId = shopId;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final rows = await _repo.list(vendorId, shopId);
      rows.sort((a, b) {
        final so = a.sortOrder.compareTo(b.sortOrder);
        if (so != 0) return so;
        final an = (a.service?.name ?? '').compareTo(b.service?.name ?? '');
        if (an != 0) return an;
        return a.id.compareTo(b.id);
      });
      return rows;
    });
  }

  Future<void> refresh() async {
    final v = _vendorId;
    final s = _shopId;
    if (v == null || s == null) return;
    await load(vendorId: v, shopId: s);
  }
}
