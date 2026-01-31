import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart'; 
import '../data/shop_services_dtos.dart';
import '../data/shop_services_repository.dart';
import '../data/master_services_repository.dart';

// repositories
final shopServicesRepositoryProvider = Provider<ShopServicesRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ShopServicesRepository(api);
});

final masterServicesRepositoryProvider = Provider<MasterServicesRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MasterServicesRepository(api);
});

// master list provider (cached)
final masterServicesProvider = FutureProvider<List<ServiceDto>>((ref) async {
  final repo = ref.read(masterServicesRepositoryProvider);
  final all = await repo.listServices();
  return all;
});


final shopServicesProvider = StateNotifierProvider.autoDispose<
    ShopServicesNotifier,
    AsyncValue<List<ShopServiceDto>>>((ref) {
  final repo = ref.read(shopServicesRepositoryProvider);
  return ShopServicesNotifier(repo);
});

class ShopServicesNotifier extends StateNotifier<AsyncValue<List<ShopServiceDto>>> {
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
      rows.sort(_sort);
      return rows;
    });
  }

  Future<void> refresh() async {
    final v = _vendorId;
    final s = _shopId;
    if (v == null || s == null) return;
    await load(vendorId: v, shopId: s);
  }

  Future<ShopServiceDto> create(Map<String, dynamic> payload) async {
    final v = _vendorId;
    final s = _shopId;
    if (v == null || s == null) throw StateError('Notifier not initialized. Call load() first.');

    final created = await _repo.create(v, s, payload);

    final current = state.valueOrNull ?? [];
    final next = [...current, created]..sort(_sort);
    state = AsyncValue.data(next);

    return created;
  }

  Future<ShopServiceDto> update(int id, Map<String, dynamic> payload) async {
    final v = _vendorId;
    final s = _shopId;
    if (v == null || s == null) throw StateError('Notifier not initialized. Call load() first.');

    final updated = await _repo.update(v, s, id, payload);

    final current = state.valueOrNull ?? [];
    final next = current.map((e) => e.id == id ? updated : e).toList()..sort(_sort);
    state = AsyncValue.data(next);

    return updated;
  }

  Future<void> delete(int id) async {
    final v = _vendorId;
    final s = _shopId;
    if (v == null || s == null) throw StateError('Notifier not initialized. Call load() first.');

    await _repo.delete(v, s, id);

    final current = state.valueOrNull ?? [];
    final next = current.where((e) => e.id != id).toList()..sort(_sort);
    state = AsyncValue.data(next);
  }

  int _sort(ShopServiceDto a, ShopServiceDto b) {
    final so = a.sortOrder.compareTo(b.sortOrder);
    if (so != 0) return so;
    final an = (a.service?.name ?? '').compareTo(b.service?.name ?? '');
    if (an != 0) return an;
    return a.id.compareTo(b.id);
  }
}
