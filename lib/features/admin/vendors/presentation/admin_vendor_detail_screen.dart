import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/admin_vendors_controller.dart';

class AdminVendorDetailScreen extends ConsumerWidget {
  const AdminVendorDetailScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(adminVendorsProvider.notifier);
    final vendor = ref.watch(adminVendorsProvider).where((v) => v.id == vendorId).firstOrNull ?? ctrl.byId(vendorId);

    if (vendor == null) {
      return Scaffold(appBar: AppBar(title: Text('Vendor $vendorId')), body: const Center(child: Text('Not found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(vendor.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.store)),
                title: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${vendor.city} • ⭐ ${vendor.rating}'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Subscription tier'),
                subtitle: Text(vendor.subscriptionTier),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _showTierDialog(context, vendor.subscriptionTier),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.block_outlined),
                title: Text('Suspend vendor'),
                subtitle: Text('Disable matching for this vendor (placeholder)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTierDialog(BuildContext context, String current) async {
    String selected = current;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in const ['Free', 'Pro', 'Elite'])
              RadioListTile<String>(
                value: t,
                groupValue: selected,
                onChanged: (v) => selected = v ?? selected,
                title: Text(t),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
