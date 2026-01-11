enum VendorOrderStatus {
  incoming,
  accepted,
  pickedUp,
  washing,
  ready,
  handedOff,
  delivered,
  completed,
  cancelled,
  rejected,
}

class VendorOrderItem {
  VendorOrderItem({
    required this.serviceName,
    required this.qtyLabel,
    required this.price,
  });

  final String serviceName;
  final String qtyLabel;
  final int price;
}

class VendorOrder {
  VendorOrder({
    required this.id,
    required this.customerName,
    required this.distanceKm,
    required this.pickupLabel,
    required this.deliveryLabel,
    required this.addressLabel,
    required this.vendorEarnings,
    required this.items,
    required this.createdAtLabel,
    required this.status,
  });

  final String id;
  final String customerName;
  final double distanceKm;
  final String pickupLabel;
  final String deliveryLabel;
  final String addressLabel;
  final int vendorEarnings;
  final List<VendorOrderItem> items;
  final String createdAtLabel;
  final VendorOrderStatus status;

  int get totalItems => items.length;

  String get statusLabel {
    return switch (status) {
      VendorOrderStatus.incoming => 'Incoming',
      VendorOrderStatus.accepted => 'Accepted',
      VendorOrderStatus.pickedUp => 'Picked up',
      VendorOrderStatus.washing => 'Washing',
      VendorOrderStatus.ready => 'Ready',
      VendorOrderStatus.handedOff => 'Handed off',
      VendorOrderStatus.delivered => 'Delivered',
      VendorOrderStatus.completed => 'Completed',
      VendorOrderStatus.cancelled => 'Cancelled',
      VendorOrderStatus.rejected => 'Rejected',
    };
  }
}

VendorOrderStatus? nextVendorStatus(VendorOrderStatus current) {
  return switch (current) {
    VendorOrderStatus.accepted => VendorOrderStatus.pickedUp,
    VendorOrderStatus.pickedUp => VendorOrderStatus.washing,
    VendorOrderStatus.washing => VendorOrderStatus.ready,
    VendorOrderStatus.ready => VendorOrderStatus.handedOff,
    VendorOrderStatus.handedOff => VendorOrderStatus.delivered,
    VendorOrderStatus.delivered => VendorOrderStatus.completed,
    _ => null,
  };
}

String? nextVendorActionLabel(VendorOrderStatus current) {
  return switch (current) {
    VendorOrderStatus.accepted => 'Confirm Pickup',
    VendorOrderStatus.pickedUp => 'Start Washing',
    VendorOrderStatus.washing => 'Mark as Ready',
    VendorOrderStatus.ready => 'Handed to Rider/Customer',
    VendorOrderStatus.handedOff => 'Mark as Delivered',
    VendorOrderStatus.delivered => 'Complete Order',
    _ => null,
  };
}
