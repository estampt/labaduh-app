import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:labaduh/core/utils/order_status_utils.dart';

import '../state/vendor_orders_controller.dart';
import '../data/vendor_order.dart';

class VendorOrderDetailScreen extends ConsumerWidget {
  const VendorOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

   

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(vendorOrdersProvider.notifier);
    final order = ref.watch(vendorOrdersProvider).where((o) => o.id == orderId).firstOrNull ?? ctrl.byId(orderId);

    if (order == null) {
      return Scaffold(appBar: AppBar(title: Text('Order $orderId')), body: const Center(child: Text('Not found')));
    }

    
    final actionLabel = OrderStatusUtils.statusLabel(order.status.toString());
    final isActionEnabled = order.status != VendorOrderStatus.completed && order.status != VendorOrderStatus.cancelled;

    return Scaffold(
      appBar: AppBar(title: Text('Order ${order.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${order.distanceKm.toStringAsFixed(1)} km • ${order.pickupLabel}'),
                trailing: Text(order.statusLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Address'),
                subtitle: Text(order.addressLabel),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Items', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (final it in order.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• ${it.label} — ${it.kg} kg'),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vendor earnings', style: TextStyle(fontWeight: FontWeight.w900)),
                        Text('₱ ${order.vendorEarnings.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Total: ₱ ${order.totalPricePhp.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !isActionEnabled ? null : () => ctrl.advanceStatus(order.id),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
