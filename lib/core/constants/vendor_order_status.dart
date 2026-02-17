/// Vendor Order Status Constants & Helpers
///
/// Centralized mapping for:
/// - Raw API status (snake_case)
/// - UI display labels
/// - Filtering & chips
/// - Future timeline usage

class VendorOrderStatusConstants {
  VendorOrderStatusConstants._(); // Prevent instantiation

  // ---------------------------------------------------------------------------
  // Raw API Status Keys
  // ---------------------------------------------------------------------------

  static const created = 'created';
  static const published = 'published';
  static const accepted = 'accepted';

  static const pickupScheduled = 'pickup_scheduled';
  static const pickedUp = 'picked_up';

  static const weightReviewed = 'weight_reviewed';
  static const weightAccepted = 'weight_accepted';

  static const washing = 'washing';
  static const ready = 'ready';

  static const deliveryScheduled = 'delivery_scheduled';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';

  static const completed = 'completed';
  static const canceled = 'canceled';

  static const unknown = 'unknown';

  // ---------------------------------------------------------------------------
  // UI Labels Mapping
  // ---------------------------------------------------------------------------

  static const Map<String, String> labels = {
    created: 'Order Created',
    published: 'Finding a Laundry Partner',
    accepted: 'Order Accepted',

    pickupScheduled: 'Pickup Scheduled',
    pickedUp: 'Laundry Picked Up',

    weightReviewed: 'Weight Reviewed',
    weightAccepted: 'Weight Confirmed',

    washing: 'Washing in Progress',
    ready: 'Ready for Delivery',

    deliveryScheduled: 'Delivery Scheduled',
    outForDelivery: 'Out for Delivery',
    delivered: 'Delivered',

    completed: 'Order Completed',
    canceled: 'Order Cancelled',

    unknown: 'Status Unavailable',
  };

  // ---------------------------------------------------------------------------
  // Helper: Get Label from Raw Status
  // ---------------------------------------------------------------------------

  static String label(String? raw) {
    final key = (raw ?? '').trim().toLowerCase();
    return labels[key] ?? labels[unknown]!;
  }

  // ---------------------------------------------------------------------------
  // Helper: All filterable statuses (exclude unknown)
  // ---------------------------------------------------------------------------

  static List<String> get filterableStatuses {
    return labels.keys.where((k) => k != unknown).toList();
  }

  // ---------------------------------------------------------------------------
  // Helper: Status → Timeline Step Index (future use)
  // ---------------------------------------------------------------------------

  static int stepIndex(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case created:
      case published:
      case accepted:
        return 0;

      case pickupScheduled:
      case pickedUp:
        return 1;

      case weightReviewed:
      case weightAccepted:
        return 2;

      case washing:
        return 3;

      case ready:
        return 4;

      case deliveryScheduled:
      case outForDelivery:
        return 5;

      case delivered:
        return 6;

      case completed:
        return 7;

      default:
        return 0;
    }
  }
}
