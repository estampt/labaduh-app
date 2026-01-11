enum OrderStatus { pendingPickup, pickedUp, washing, ready, delivered, cancelled }

class OrderSummary {
  OrderSummary({
    required this.id,
    required this.title,
    required this.createdAtLabel,
    required this.totalLabel,
    required this.status,
  });

  final String id;
  final String title;
  final String createdAtLabel;
  final String totalLabel;
  final OrderStatus status;

  String get statusLabel {
    return switch (status) {
      OrderStatus.pendingPickup => 'Pickup scheduled',
      OrderStatus.pickedUp => 'Picked up',
      OrderStatus.washing => 'Washing',
      OrderStatus.ready => 'Ready',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
  }
}
