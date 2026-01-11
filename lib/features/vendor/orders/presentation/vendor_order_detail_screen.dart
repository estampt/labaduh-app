import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/vendor_order.dart';
import '../state/vendor_orders_controller.dart';

class VendorOrderDetailScreen extends ConsumerWidget {
  const VendorOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(vendorOrdersProvider);
    final ctrl = ref.read(vendorOrdersProvider.notifier);
    final order = orders.where((o) => o.id == orderId).firstOrNull ?? ctrl.byId(orderId);

    if (order == null) {
      return Scaffold(appBar: AppBar(title: Text('Order #$orderId')), body: const Center(child: Text('Order not found')));
    }

    final actionLabel = nextVendorActionLabel(order.status);

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id}')),
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
                title: const Text('Pickup address'),
                subtitle: Text(order.addressLabel),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Services', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (final it in order.items) ...[
                      Row(
                        children: [
                          Expanded(child: Text('${it.serviceName} • ${it.qtyLabel}')),
                          Text('₱ ${it.price}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Text('Vendor earnings', style: TextStyle(fontWeight: FontWeight.w900))),
                        Text('₱ ${order.vendorEarnings}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Notes'),
                subtitle: Text('Call upon arrival (placeholder)'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: actionLabel == null || order.status == VendorOrderStatus.incoming
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => ctrl.advanceStatus(order.id),
                    child: Text(actionLabel),
                  ),
                ),
              ),
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
