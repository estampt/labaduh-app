import 'package:flutter/material.dart';
import '../domain/order_status.dart';

/// 🌍 Global Order Status Utility (Enum-first)
class OrderStatusUtils {
  OrderStatusUtils._();


  /*
  //TODO Usage
  Wherever you currently compute stepIndex, do:

  final st = OrderStatusParsing.fromApi(o.status);
  final stepIndex = OrderStatusUtils.stepIndex(st);


  Then your UI stays exactly the same:

  _TrackingStep(label: 'Accepted', state: _stepState(0, stepIndex)),
  ...
  _TrackingStep(label: 'Delivered', state: _stepState(6, stepIndex)),

  */
  // ------------------------------
  // Label
  // ------------------------------
  static String label(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'Order Created';
      case OrderStatus.published:
        return 'Searching for Vendor';
      case OrderStatus.accepted:
        return 'Vendor Accepted';

      case OrderStatus.pickupScheduled:
        return 'Pickup Scheduled';
      case OrderStatus.pickedUp:
        return 'Laundry Picked Up';

      case OrderStatus.weightReviewed:
        return 'Weight Reviewed';
      case OrderStatus.weightAccepted:
        return 'Weight Confirmed';

      case OrderStatus.washing:
        return 'Washing in Progress';
      case OrderStatus.ready:
        return 'Ready for Delivery';

      case OrderStatus.deliveryScheduled:
        return 'Delivery Scheduled';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';

      case OrderStatus.completed:
        return 'Order Completed';

      case OrderStatus.canceled:
        return 'Order Canceled';

      case OrderStatus.unknown:
        return 'Unknown Status';
    }
  }


// --------------------------------------------------
  // 🏷️ STATUS LABEL
  // --------------------------------------------------
  static String statusLabel(String? status) {
    final s = (status ?? '').toLowerCase().trim();

    switch (s) {
      case 'created':
        return 'Order Created';

      case 'published':
        return 'Searching for Vendor';

      case 'accepted':
        return 'Vendor Accepted';

      case 'pickup_scheduled':
        return 'Pickup Scheduled';

      case 'picked_up':
        return 'Laundry Picked Up';

      case 'weight_reviewed':
        return 'Weight Reviewed';

      case 'weight_accepted':
        return 'Weight Confirmed';

      case 'washing':
        return 'Washing in Progress';

      case 'ready':
        return 'Ready for Delivery';

      case 'delivery_scheduled':
        return 'Delivery Scheduled';

      case 'delivering':
      case 'out_for_delivery':
        return 'Out for Delivery';

      case 'delivered':
        return 'Delivered';

      case 'completed':
        return 'Order Completed';

      case 'canceled':
      case 'cancelled':
        return 'Order Canceled';

      default:
        return status ?? '-';
    }
  }
  // ------------------------------
  // Color
  // ------------------------------
  static Color color(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return Colors.grey;
      case OrderStatus.published:
        return Colors.blue;
      case OrderStatus.accepted:
        return Colors.teal;

      case OrderStatus.pickupScheduled:
        return Colors.orangeAccent;
      case OrderStatus.pickedUp:
        return Colors.orange;

      case OrderStatus.weightReviewed:
        return Colors.amber;
      case OrderStatus.weightAccepted:
        return Colors.amber.shade700;

      case OrderStatus.washing:
        return Colors.deepPurple;

      case OrderStatus.ready:
        return Colors.indigo;

      case OrderStatus.deliveryScheduled:
        return Colors.lightBlue;
      case OrderStatus.outForDelivery:
        return Colors.blueAccent;
      case OrderStatus.delivered:
        return Colors.green;

      case OrderStatus.completed:
        return Colors.green.shade800;

      case OrderStatus.canceled:
        return Colors.red;

      case OrderStatus.unknown:
        return Colors.grey;
    }
  }

    // --------------------------------------------------
  // Timeline Step Index (matches YOUR Tracking UI)
  // 0 Accepted
  // 1 Pickup scheduled
  // 2 Picked up
  // 3 Weight review
  // 4 Washing
  // 5 Out for delivery
  // 6 Delivered
  //
  // -1 = before timeline (created/published) or unknown/canceled
  // --------------------------------------------------
  static int stepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 0;

      case OrderStatus.pickupScheduled:
        return 1;

      case OrderStatus.pickedUp:
        return 2;

      // Weight review step: treat both as step 3 (still same stage)
      case OrderStatus.weightReviewed:
      case OrderStatus.weightAccepted:
        return 3;

      case OrderStatus.washing:
        return 4;

      // delivery stage: scheduled/out for delivery are step 5
      case OrderStatus.deliveryScheduled:
      case OrderStatus.outForDelivery:
        return 5;

      // delivered + completed are step 6 (final)
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 6;

      // pre-timeline
      case OrderStatus.created:
      case OrderStatus.published:
        return -1;

      // terminal / unknown
      case OrderStatus.canceled:
      case OrderStatus.unknown:
        return -1;

      case OrderStatus.ready:
        // If you still use "ready" in backend, decide where it fits:
        // Usually between washing and delivery => step 4 or 5
        // I'll map it to "Washing" stage to keep timeline simple.
        return 4;
    }
  }

  // --------------------------------------------------
  // Progress 0.0 -> 1.0 aligned to stepIndex above
  // --------------------------------------------------
  static double progress(OrderStatus status) {
    final idx = stepIndex(status);

    if (idx < 0) {
      // created/published: small progress so UI doesn't look "empty"
      if (status == OrderStatus.created) return 0.05;
      if (status == OrderStatus.published) return 0.10;
      return 0.0;
    }

    // 0..6 -> 1/7 .. 7/7
    return (idx + 1) / 7.0;
  }

 
  //TODO: how to use 
  // Color color = OrderStatusUtils.statusColor(order.status);
  /*
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: OrderStatusUtils.statusColor(order.status),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    OrderStatusUtils.statusLabel(order.status),
    style: const TextStyle(color: Colors.white),
  ),
)
  */
  // --------------------------------------------------
  // 🎨 STATUS COLOR
  // --------------------------------------------------
  static Color statusColor(String? status) {
    final s = (status ?? '').toLowerCase().trim();

    switch (s) {
      /// ---------------- ORDER CREATED ----------------
      case 'created':
        return Colors.grey;

      case 'published':
        return Colors.blue;

      /// ---------------- ACCEPTANCE ----------------
      case 'accepted':
        return Colors.teal;

      /// ---------------- PICKUP ----------------
      case 'pickup_scheduled':
        return Colors.orangeAccent;

      case 'picked_up':
        return Colors.orange;

      /// ---------------- WEIGHT REVIEW ----------------
      case 'weight_reviewed':
        return Colors.amber;

      case 'weight_accepted':
        return Colors.amber.shade700;

      /// ---------------- WASHING ----------------
      case 'washing':
        return Colors.deepPurple;

      /// ---------------- READY ----------------
      case 'ready':
        return Colors.indigo;

      /// ---------------- DELIVERY ----------------
      case 'delivery_scheduled':
        return Colors.lightBlue;

      case 'delivering':
      case 'out_for_delivery':
        return Colors.blueAccent;

      case 'delivered':
        return Colors.green;

      /// ---------------- COMPLETED ----------------
      case 'completed':
        return Colors.green.shade800;

      /// ---------------- CANCELED ----------------
      case 'canceled':
      case 'cancelled':
        return Colors.red;

      /// ---------------- DEFAULT ----------------
      default:
        return Colors.grey;
    }
  }
  // ------------------------------
  // Useful guards
  // ------------------------------
  static bool isCancelable(OrderStatus status) =>
      status == OrderStatus.created || status == OrderStatus.published;

  static bool isTerminal(OrderStatus status) =>
      status == OrderStatus.completed || status == OrderStatus.canceled;

  static bool isActive(OrderStatus status) =>
      !isTerminal(status) && status != OrderStatus.unknown;
}
