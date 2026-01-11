import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/vendor_order.dart';
import '../state/vendor_orders_controller.dart';

class VendorOrdersTab extends ConsumerStatefulWidget {
  const VendorOrdersTab({super.key});

  @override
  ConsumerState<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends ConsumerState<VendorOrdersTab> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(vendorOrdersProvider);

    final incoming = orders.where((o) => o.status == VendorOrderStatus.incoming).toList();
    final active = orders.where((o) =>
        o.status != VendorOrderStatus.incoming &&
        o.status != VendorOrderStatus.rejected &&
        o.status != VendorOrderStatus.cancelled &&
        o.status != VendorOrderStatus.completed).toList();

    final list = tab == 0 ? incoming : active;

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Incoming')),
                ButtonSegment(value: 1, label: Text('Active')),
              ],
              selected: {tab},
              onSelectionChanged: (s) => setState(() => tab = s.first),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text(tab == 0 ? 'No incoming orders.' : 'No active orders.', style: const TextStyle(color: Colors.black54)))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _OrderCard(order: list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(vendorOrdersProvider.notifier);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined),
                const SizedBox(width: 8),
                Text('${order.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(order.createdAtLabel, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 10),
            Text('Order #${order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('${order.totalItems} services • ${order.pickupLabel} • ${order.deliveryLabel}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            ...order.items.take(3).map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text('${it.serviceName} – ${it.qtyLabel}')),
                      Text('₱ ${it.price}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18),
                const SizedBox(width: 6),
                Text('You earn: ₱ ${order.vendorEarnings}', style: const TextStyle(fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(onPressed: () => context.push('/v/orders/${order.id}'), child: const Text('View')),
              ],
            ),
            if (order.status == VendorOrderStatus.incoming) ...[
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final reason = await showDialog<String>(
                          context: context,
                          builder: (_) => const _RejectDialog(),
                        );
                        if (reason != null) ctrl.reject(order.id);
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(onPressed: () => ctrl.accept(order.id), child: const Text('Accept')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  String reason = 'Too busy';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(value: 'Too busy', groupValue: reason, onChanged: (v) => setState(() => reason = v ?? reason), title: const Text('Too busy')),
          RadioListTile<String>(value: 'Out of stock/supplies', groupValue: reason, onChanged: (v) => setState(() => reason = v ?? reason), title: const Text('Out of stock / supplies')),
          RadioListTile<String>(value: 'Too far', groupValue: reason, onChanged: (v) => setState(() => reason = v ?? reason), title: const Text('Too far')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, reason), child: const Text('Reject')),
      ],
    );
  }
}
