import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../orders/domain/vendor_order.dart';
import '../../orders/state/vendor_orders_controller.dart';

class VendorQueueTab extends ConsumerWidget {
  const VendorQueueTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(vendorOrdersProvider);
    final washing = orders.where((o) => o.status == VendorOrderStatus.washing).toList();
    final ready = orders.where((o) => o.status == VendorOrderStatus.ready).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Queue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _Section(title: 'Washing', count: washing.length),
            const SizedBox(height: 8),
            ...washing.map((o) => _QueueCard(order: o)),
            const SizedBox(height: 18),
            _Section(title: 'Ready', count: ready.length),
            const SizedBox(height: 8),
            ...ready.map((o) => _QueueCard(order: o)),
            if (washing.isEmpty && ready.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('No jobs in queue.', style: TextStyle(color: Colors.black54))),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Chip(label: Text('$count')),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${order.totalItems} services • ${order.pickupLabel}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/v/orders/${order.id}'),
        ),
      ),
    );
  }
}
