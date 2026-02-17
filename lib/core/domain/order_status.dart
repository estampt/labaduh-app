enum OrderStatus {
  created,
  published,
  accepted,

  pickupScheduled,
  pickedUp,

  weightReviewed,
  weightAccepted,

  washing,
  ready,

  deliveryScheduled,
  outForDelivery,
  delivered,

  completed,
  canceled,

  unknown,
}

extension OrderStatusParsing on OrderStatus {
  static OrderStatus fromApi(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();

    switch (s) {
      case 'created':
        return OrderStatus.created;
      case 'published':
        return OrderStatus.published;
      case 'accepted':
        return OrderStatus.accepted;

      case 'pickup_scheduled':
        return OrderStatus.pickupScheduled;
      case 'picked_up':
        return OrderStatus.pickedUp;

      case 'weight_reviewed':
        return OrderStatus.weightReviewed;
      case 'weight_accepted':
        return OrderStatus.weightAccepted;

      case 'washing':
        return OrderStatus.washing;
      case 'ready':
        return OrderStatus.ready;

      case 'delivery_scheduled':
        return OrderStatus.deliveryScheduled;

      // backend variants
      case 'delivering':
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;

      case 'delivered':
        return OrderStatus.delivered;

      case 'completed':
        return OrderStatus.completed;

      // backend variants
      case 'canceled':
      case 'cancelled':
        return OrderStatus.canceled;

      default:
        return OrderStatus.unknown;
    }
  }

  /// If you ever need to send back to API
  String toApi() {
    switch (this) {
      case OrderStatus.pickupScheduled:
        return 'pickup_scheduled';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.weightReviewed:
        return 'weight_reviewed';
      case OrderStatus.weightAccepted:
        return 'weight_accepted';
      case OrderStatus.deliveryScheduled:
        return 'delivery_scheduled';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.canceled:
        return 'canceled';
      case OrderStatus.unknown:
        return 'unknown';
      default:
        return name; // created/published/accepted/washing/ready/delivered/completed
    }
  }
}
