import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_models.dart';
import '../data/admin_seed.dart';

final adminOrdersProvider = StateNotifierProvider<AdminOrdersController, List<AdminOrder>>((ref) {
  return AdminOrdersController()..seed();
});

class AdminOrdersController extends StateNotifier<List<AdminOrder>> {
  AdminOrdersController() : super(const []);

  void seed() => state = [...seedOrders];

  AdminOrder? byId(String id) => state.where((o) => o.id == id).firstOrNull;

  void setStatus(String id, AdminOrderStatus status) {
    state = [
      for (final o in state)
        if (o.id == id)
          AdminOrder(
            id: o.id,
            customerName: o.customerName,
            vendorName: o.vendorName,
            total: o.total,
            createdAt: o.createdAt,
            status: status,
            distanceKm: o.distanceKm,
          )
        else
          o
    ];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
