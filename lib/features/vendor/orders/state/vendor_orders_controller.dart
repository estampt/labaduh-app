import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vendor_order.dart';

final vendorOrdersProvider = StateNotifierProvider<VendorOrdersController, List<VendorOrder>>((ref) {
  return VendorOrdersController()..seed();
});

class VendorOrdersController extends StateNotifier<List<VendorOrder>> {
  VendorOrdersController() : super(const []);

  void seed() {
    state = [
      VendorOrder(
        id: 'o1001',
        customerName: 'Rehnee (placeholder)',
        address: 'BGC, Taguig',
        distanceKm: 3.4,
        pickupLabel: 'Today 5:00 PM',
        items: const [
          VendorOrderItem(label: 'Wash & Fold (Whites)', kg: 6),
          VendorOrderItem(label: 'Wash & Iron (Pants)', kg: 4),
        ],
        totalPricePhp: 580,
        vendorEarningsPhp: 520,
        createdAtLabel: 'Today 10:15',
        status: VendorOrderStatus.newRequest,
      ),
      VendorOrder(
        id: 'o1002',
        customerName: 'Ana Santos',
        address: 'Makati CBD',
        distanceKm: 6.8,
        pickupLabel: 'Today 2:00 PM',
        items: const [VendorOrderItem(label: 'Wash & Iron (Mixed)', kg: 8)],
        totalPricePhp: 360,
        vendorEarningsPhp: 320,
        createdAtLabel: 'Today 09:40',
        status: VendorOrderStatus.inWash,
      ),
      VendorOrder(
        id: 'o1003',
        customerName: 'Miguel Cruz',
        address: 'Ortigas, Pasig',
        distanceKm: 8.1,
        pickupLabel: 'Tomorrow 9:00 AM',
        items: const [VendorOrderItem(label: 'Dry Clean (Formal)', kg: 5)],
        totalPricePhp: 780,
        vendorEarningsPhp: 690,
        createdAtLabel: 'Yesterday',
        status: VendorOrderStatus.readyForDelivery,
      ),
    ];
  }

  VendorOrder? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  void accept(String id) => _setStatus(id, VendorOrderStatus.accepted);
  void reject(String id) => _setStatus(id, VendorOrderStatus.cancelled);

  void advanceStatus(String id) {
    final o = byId(id);
    if (o == null) return;

    final next = switch (o.status) {
      VendorOrderStatus.newRequest => VendorOrderStatus.accepted,
      VendorOrderStatus.accepted => VendorOrderStatus.inWash,
      VendorOrderStatus.inWash => VendorOrderStatus.readyForDelivery,
      VendorOrderStatus.readyForDelivery => VendorOrderStatus.completed,
      VendorOrderStatus.completed => VendorOrderStatus.completed,
      VendorOrderStatus.cancelled => VendorOrderStatus.cancelled,
    };

    _setStatus(id, next);
  }

  void _setStatus(String id, VendorOrderStatus status) {
    state = [for (final o in state) if (o.id == id) o.copyWith(status: status) else o];
  }
}

final vendorOrderStatsProvider = Provider<VendorOrderStats>((ref) {
  final orders = ref.watch(vendorOrdersProvider);
  int active = 0, newReq = 0, inWash = 0, ready = 0;

  for (final o in orders) {
    if (o.status != VendorOrderStatus.completed && o.status != VendorOrderStatus.cancelled) active++;
    if (o.status == VendorOrderStatus.newRequest) newReq++;
    if (o.status == VendorOrderStatus.inWash) inWash++;
    if (o.status == VendorOrderStatus.readyForDelivery) ready++;
  }

  return VendorOrderStats(active: active, newRequests: newReq, inWash: inWash, readyForDelivery: ready);
});

class VendorOrderStats {
  const VendorOrderStats({
    required this.active,
    required this.newRequests,
    required this.inWash,
    required this.readyForDelivery,
  });

  final int active;
  final int newRequests;
  final int inWash;
  final int readyForDelivery;
}
