import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../order/state/order_draft_controller.dart';
import '../../orders/state/orders_controller.dart';

class CustomerHomeTab extends ConsumerWidget {
  const CustomerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Labaduh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Hi Rehnee 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Ready to send your laundry?', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Laundry Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Pickup · Wash · Deliver', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          ref.read(orderDraftControllerProvider.notifier).reset();
                          context.push('/c/order/services');

                        },
                        child: const Text('Start Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Quick Links', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Track latest order'),
                subtitle: Text(orders.isEmpty ? 'No active orders' : 'View status updates'),
                trailing: const Icon(Icons.chevron_right),
                onTap: orders.isEmpty ? null : () => context.push('/c/order/tracking'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Order history'),
                subtitle: const Text('See past pickups and deliveries'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/c/orders'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
