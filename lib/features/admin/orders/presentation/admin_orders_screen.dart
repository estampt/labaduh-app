import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_models.dart';
import '../../state/admin_orders_controller.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String q = '';
  AdminOrderStatus? status;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider);

    final filtered = orders.where((o) {
      final matchQ = q.isEmpty ||
          o.id.contains(q) ||
          o.customerName.toLowerCase().contains(q.toLowerCase()) ||
          o.vendorName.toLowerCase().contains(q.toLowerCase());
      final matchS = status == null || o.status == status;
      return matchQ && matchS;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search order ID, customer, vendor'),
            onChanged: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(label: const Text('All'), selected: status == null, onSelected: (_) => setState(() => status = null)),
                const SizedBox(width: 8),
                ...AdminOrderStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s.name),
                        selected: status == s,
                        onSelected: (_) => setState(() => status = s),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No orders found', style: TextStyle(color: Colors.black54)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final o = filtered[i];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text('${o.customerName} → ${o.vendorName}\n${o.createdAt} • ${o.statusLabel}'),
                          isThreeLine: true,
                          trailing: Text('₱ ${o.total}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          onTap: () => context.push('/a/orders/${o.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
