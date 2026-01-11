enum AdminOrderStatus { incoming, matched, pickedUp, washing, ready, delivered, completed, cancelled }

class AdminOrder {
  AdminOrder({
    required this.id,
    required this.customerName,
    required this.vendorName,
    required this.total,
    required this.createdAt,
    required this.status,
    required this.distanceKm,
  });

  final String id;
  final String customerName;
  final String vendorName;
  final int total;
  final String createdAt;
  final AdminOrderStatus status;
  final double distanceKm;

  String get statusLabel => switch (status) {
        AdminOrderStatus.incoming => 'Incoming',
        AdminOrderStatus.matched => 'Matched',
        AdminOrderStatus.pickedUp => 'Picked up',
        AdminOrderStatus.washing => 'Washing',
        AdminOrderStatus.ready => 'Ready',
        AdminOrderStatus.delivered => 'Delivered',
        AdminOrderStatus.completed => 'Completed',
        AdminOrderStatus.cancelled => 'Cancelled',
      };
}

class AdminVendor {
  AdminVendor({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.activeOrders,
    required this.subscriptionTier,
  });

  final String id;
  final String name;
  final String city;
  final double rating;
  final int activeOrders;
  final String subscriptionTier;
}

class AdminUser {
  AdminUser({required this.id, required this.name, required this.city, required this.createdAt});
  final String id;
  final String name;
  final String city;
  final String createdAt;
}

class PricingRow {
  PricingRow({
    required this.serviceId,
    required this.serviceName,
    required this.baseKg,
    required this.basePrice,
    required this.excessPerKg,
  });

  final String serviceId;
  final String serviceName;
  final int baseKg;
  final int basePrice;
  final int excessPerKg;

  PricingRow copyWith({int? baseKg, int? basePrice, int? excessPerKg}) {
    return PricingRow(
      serviceId: serviceId,
      serviceName: serviceName,
      baseKg: baseKg ?? this.baseKg,
      basePrice: basePrice ?? this.basePrice,
      excessPerKg: excessPerKg ?? this.excessPerKg,
    );
  }
}
