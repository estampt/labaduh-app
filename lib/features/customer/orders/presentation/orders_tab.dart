import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/orders_controller.dart';

class OrdersTab extends ConsumerWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orders.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No orders yet. Start your first order from Home.')))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final o = orders[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${o.statusLabel} • ${o.createdAtLabel}'),
                    trailing: Text(o.totalLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                    onTap: () => context.push('/c/orders/${o.id}'),
                  ),
                );
              },
            ),
    );
  }
}
