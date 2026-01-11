import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vendor_order.dart';

final vendorOrdersProvider =
    StateNotifierProvider<VendorOrdersController, List<VendorOrder>>((ref) {
  return VendorOrdersController()..seed();
});

class VendorOrdersController extends StateNotifier<List<VendorOrder>> {
  VendorOrdersController() : super(const []);

  void seed() {
    state = [
      VendorOrder(
        id: '2001',
        customerName: 'Rehnee',
        distanceKm: 1.2,
        pickupLabel: 'ASAP (Today)',
        deliveryLabel: 'Pickup & Deliver',
        addressLabel: '123 Sample St, Quezon City',
        vendorEarnings: 620,
        createdAtLabel: 'Just now',
        status: VendorOrderStatus.incoming,
        items: [
          VendorOrderItem(serviceName: 'Wash & Fold', qtyLabel: '6 KG', price: 299),
          VendorOrderItem(serviceName: 'All Whites', qtyLabel: '6 KG', price: 319),
          VendorOrderItem(serviceName: 'Delicates', qtyLabel: '3 KG', price: 249),
        ],
      ),
      VendorOrder(
        id: '2000',
        customerName: 'Miguel',
        distanceKm: 2.8,
        pickupLabel: 'Tomorrow',
        deliveryLabel: 'Walk-in',
        addressLabel: 'Walk-in (customer drop-off)',
        vendorEarnings: 310,
        createdAtLabel: 'Today, 4:10 PM',
        status: VendorOrderStatus.washing,
        items: [
          VendorOrderItem(serviceName: 'Colored', qtyLabel: '6 KG', price: 309),
        ],
      ),
    ];
  }

  void accept(String orderId) {
    state = [
      for (final o in state)
        if (o.id == orderId) _copy(o, status: VendorOrderStatus.accepted) else o
    ];
  }

  void reject(String orderId) {
    state = [
      for (final o in state)
        if (o.id == orderId) _copy(o, status: VendorOrderStatus.rejected) else o
    ];
  }

  void advanceStatus(String orderId) {
    state = [
      for (final o in state)
        if (o.id == orderId)
          _copy(o, status: nextVendorStatus(o.status) ?? o.status)
        else
          o
    ];
  }

  VendorOrder? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  VendorOrder _copy(VendorOrder o, {VendorOrderStatus? status}) {
    return VendorOrder(
      id: o.id,
      customerName: o.customerName,
      distanceKm: o.distanceKm,
      pickupLabel: o.pickupLabel,
      deliveryLabel: o.deliveryLabel,
      addressLabel: o.addressLabel,
      vendorEarnings: o.vendorEarnings,
      items: o.items,
      createdAtLabel: o.createdAtLabel,
      status: status ?? o.status,
    );
  }
}
