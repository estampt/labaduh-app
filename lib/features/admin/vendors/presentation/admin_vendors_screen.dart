import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/admin_vendors_controller.dart';

class AdminVendorsScreen extends ConsumerStatefulWidget {
  const AdminVendorsScreen({super.key});

  @override
  ConsumerState<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends ConsumerState<AdminVendorsScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(adminVendorsProvider);
    final filtered = vendors.where((v) => q.isEmpty || v.name.toLowerCase().contains(q.toLowerCase()) || v.city.toLowerCase().contains(q.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search vendor name or city'),
            onChanged: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No vendors found', style: TextStyle(color: Colors.black54)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final v = filtered[i];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.store)),
                          title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text('${v.city} • ⭐ ${v.rating} • Active: ${v.activeOrders}\nTier: ${v.subscriptionTier}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/a/vendors/${v.id}'),
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
