import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/shop_service_options_dtos.dart';
import '../data/shop_service_options_repository.dart';
import '../data/master_service_options_repository.dart';

final shopServiceOptionsRepositoryProvider =
    Provider<ShopServiceOptionsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ShopServiceOptionsRepository(api);
});

final masterServiceOptionsRepositoryProvider =
    Provider<MasterServiceOptionsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MasterServiceOptionsRepository(api);
});

// master options list (cached)
final masterServiceOptionsProvider =
    FutureProvider<List<ServiceOptionDto>>((ref) async {
  final repo = ref.read(masterServiceOptionsRepositoryProvider);
  return repo.listAll();
});

final shopServiceOptionsProvider = StateNotifierProvider.autoDispose<
    ShopServiceOptionsNotifier,
    AsyncValue<List<ShopServiceOptionDto>>>((ref) {
  final repo = ref.read(shopServiceOptionsRepositoryProvider);
  return ShopServiceOptionsNotifier(repo);
});

class ShopServiceOptionsNotifier
    extends StateNotifier<AsyncValue<List<ShopServiceOptionDto>>> {
  ShopServiceOptionsNotifier(this._repo)
      : super(const AsyncValue.loading());

  final ShopServiceOptionsRepository _repo;

  int? _vendorId;
  int? _shopId;
  int? _shopServiceId;

  Future<void> load({
    required int vendorId,
    required int shopId,
    required int shopServiceId,
  }) async {
    _vendorId = vendorId;
    _shopId = shopId;
    _shopServiceId = shopServiceId;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final rows = await _repo.list(vendorId, shopId, shopServiceId);
      rows.sort(_sort);
      return rows;
    });
  }

  Future<void> refresh() async {
    final v = _vendorId;
    final s = _shopId;
    final ss = _shopServiceId;
    if (v == null || s == null || ss == null) return;
    await load(vendorId: v, shopId: s, shopServiceId: ss);
  }

  Future<ShopServiceOptionDto> create(Map<String, dynamic> payload) async {
    final v = _vendorId!;
    final s = _shopId!;
    final ss = _shopServiceId!;
    final created = await _repo.create(v, s, ss, payload);

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, created]..sort(_sort));
    return created;
  }

  Future<ShopServiceOptionDto> update(int id, Map<String, dynamic> payload) async {
    final v = _vendorId!;
    final s = _shopId!;
    final ss = _shopServiceId!;
    final updated = await _repo.update(v, s, ss, id, payload);

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((e) => e.id == id ? updated : e).toList()..sort(_sort),
    );
    return updated;
  }

  Future<void> delete(int id) async {
    final v = _vendorId!;
    final s = _shopId!;
    final ss = _shopServiceId!;
    await _repo.delete(v, s, ss, id);

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((e) => e.id != id).toList()..sort(_sort));
  }

  int _sort(ShopServiceOptionDto a, ShopServiceOptionDto b) {
    final so = a.sortOrder.compareTo(b.sortOrder);
    if (so != 0) return so;
    final an = (a.serviceOption?.name ?? '').toLowerCase();
    final bn = (b.serviceOption?.name ?? '').toLowerCase();
    return an.compareTo(bn);
  }
}
