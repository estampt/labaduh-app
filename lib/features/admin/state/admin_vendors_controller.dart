import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_models.dart';
import '../data/admin_seed.dart';

final adminVendorsProvider = StateNotifierProvider<AdminVendorsController, List<AdminVendor>>((ref) {
  return AdminVendorsController()..seed();
});

class AdminVendorsController extends StateNotifier<List<AdminVendor>> {
  AdminVendorsController() : super(const []);

  void seed() => state = [...seedVendors];

  AdminVendor? byId(String id) => state.where((v) => v.id == id).firstOrNull;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
