enum VendorOrderStatus { newRequest, accepted, inWash, readyForDelivery, completed, cancelled }

extension VendorOrderStatusX on VendorOrderStatus {
  String get label {
    switch (this) {
      case VendorOrderStatus.newRequest:
        return 'New request';
      case VendorOrderStatus.accepted:
        return 'Accepted';
      case VendorOrderStatus.inWash:
        return 'In wash';
      case VendorOrderStatus.readyForDelivery:
        return 'Ready for delivery';
      case VendorOrderStatus.completed:
        return 'Completed';
      case VendorOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class VendorOrderItem {
  const VendorOrderItem({required this.label, required this.kg});
  final String label;
  final double kg;
}

class VendorOrder {
  const VendorOrder({
    required this.id,
    required this.customerName,
    required this.address,
    required this.distanceKm,
    required this.pickupLabel,
    required this.items,
    required this.totalPricePhp,
    required this.vendorEarningsPhp,
    required this.createdAtLabel,
    required this.status,
  });

  final String id;
  final String customerName;
  final String address;
  final double distanceKm;
  final String pickupLabel;
  final List<VendorOrderItem> items;
  final double totalPricePhp;
  final double vendorEarningsPhp;
  final String createdAtLabel;
  final VendorOrderStatus status;

  String get statusLabel => status.label;
  String get addressLabel => address;
  double get vendorEarnings => vendorEarningsPhp;

  VendorOrder copyWith({VendorOrderStatus? status}) => VendorOrder(
        id: id,
        customerName: customerName,
        address: address,
        distanceKm: distanceKm,
        pickupLabel: pickupLabel,
        items: items,
        totalPricePhp: totalPricePhp,
        vendorEarningsPhp: vendorEarningsPhp,
        createdAtLabel: createdAtLabel,
        status: status ?? this.status,
      );
}
