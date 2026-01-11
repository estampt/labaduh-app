import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_models.dart';
import '../../state/admin_orders_controller.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(adminOrdersProvider.notifier);
    final order = ref.watch(adminOrdersProvider).where((o) => o.id == orderId).firstOrNull ?? ctrl.byId(orderId);

    if (order == null) {
      return Scaffold(appBar: AppBar(title: Text('Order #$orderId')), body: const Center(child: Text('Not found')));
    }

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
                leading: const Icon(Icons.person_outline),
                title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('Vendor: ${order.vendorName}'),
                trailing: Text('₱ ${order.total}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.place_outlined),
                title: const Text('Distance'),
                subtitle: Text('${order.distanceKm.toStringAsFixed(1)} km'),
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
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AdminOrderStatus.values.map((s) {
                        final selected = order.status == s;
                        return ChoiceChip(
                          label: Text(s.name),
                          selected: selected,
                          onSelected: (_) => ctrl.setStatus(order.id, s),
                        );
                      }).toList(),
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
                title: Text('Admin notes'),
                subtitle: Text('Add dispute notes / adjustments later (placeholder)'),
              ),
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
