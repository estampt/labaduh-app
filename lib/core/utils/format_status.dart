import 'package:flutter/material.dart';

/// 🌍 Global Order Status Utility
/// Reusable across Customer / Vendor / Admin apps
class OrderStatusUtils {
  OrderStatusUtils._(); // Prevent instantiation

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
  
}
