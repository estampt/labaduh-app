import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_notifier.dart';
import '../../../../core/network/api_client.dart';
import '../data/vendor_shops_repository.dart';
import '../domain/vendor_shop.dart';

final vendorIdProvider = Provider<int>((ref) {
  final session = ref.watch(sessionNotifierProvider);
  final vid = session.vendorId; // keep as-is
  if (vid == null || vid.toString().isEmpty) {
    throw Exception('vendorId is null in session');
  }
  return int.parse(vid.toString());
});

final vendorShopsRepositoryProvider = Provider<VendorShopsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return VendorShopsRepository(api);
});

final vendorShopsProvider = FutureProvider<List<VendorShop>>((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  return ref.watch(vendorShopsRepositoryProvider).list(vendorId: vendorId);
});

final vendorShopsActionsProvider = Provider<_VendorShopsActions>((ref) {
  final vendorId = ref.watch(vendorIdProvider);
  final repo = ref.watch(vendorShopsRepositoryProvider);
  return _VendorShopsActions(repo, vendorId);
});

class _VendorShopsActions {
  _VendorShopsActions(this.repo, this.vendorId);
  final VendorShopsRepository repo;
  final int vendorId;

  Future<void> toggle(int shopId) => repo.toggle(vendorId: vendorId, shopId: shopId);

  Future<VendorShop> create(Map<String, dynamic> payload) =>
      repo.create(vendorId: vendorId, payload: payload);

  Future<VendorShop> update(int shopId, Map<String, dynamic> payload) =>
      repo.update(vendorId: vendorId, shopId: shopId, payload: payload);
}
