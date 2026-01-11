import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/vendor_order.dart';
import '../state/vendor_orders_controller.dart';

class VendorOrdersTab extends ConsumerStatefulWidget {
  const VendorOrdersTab({super.key});

  @override
  ConsumerState<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends ConsumerState<VendorOrdersTab> {
  VendorOrderStatus? filter;
  String q = '';

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(vendorOrdersProvider.notifier);
    final orders = ref.watch(vendorOrdersProvider);

    final filtered = orders.where((o) {
      final matchQ = q.isEmpty ||
          o.id.toLowerCase().contains(q.toLowerCase()) ||
          o.customerName.toLowerCase().contains(q.toLowerCase()) ||
          o.address.toLowerCase().contains(q.toLowerCase());
      final matchF = filter == null || o.status == filter;
      return matchQ && matchF;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search order/customer/address'),
              onChanged: (v) => setState(() => q = v.trim()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(label: const Text('All'), selected: filter == null, onSelected: (_) => setState(() => filter = null)),
                  const SizedBox(width: 8),
                  ...VendorOrderStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.label),
                          selected: filter == s,
                          onSelected: (_) => setState(() => filter = s),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No orders', style: TextStyle(color: Colors.black54)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = filtered[i];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.local_laundry_service)),
                            title: Text('${o.id} • ${o.customerName}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            subtitle: Text('${o.statusLabel} • ${o.distanceKm.toStringAsFixed(1)} km\nPickup: ${o.pickupLabel}\n${o.addressLabel}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (o.status == VendorOrderStatus.newRequest)
                                  IconButton(
                                    tooltip: 'Reject',
                                    icon: const Icon(Icons.close),
                                    onPressed: () => ctrl.reject(o.id),
                                  ),
                                if (o.status == VendorOrderStatus.newRequest)
                                  IconButton(
                                    tooltip: 'Accept',
                                    icon: const Icon(Icons.check),
                                    onPressed: () => ctrl.accept(o.id),
                                  ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => context.push('/v/orders/${o.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
