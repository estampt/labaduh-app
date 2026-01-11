import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_role.dart';
import '../../../vendor/state/vendor_applications_controller.dart';

class AdminVendorDetailScreen extends ConsumerWidget {
  const AdminVendorDetailScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(vendorApplicationsProvider.notifier);
    final app = ref.watch(vendorApplicationsProvider).where((a) => a.id == vendorId).firstOrNull ?? ctrl.byId(vendorId);

    if (app == null) {
      return Scaffold(appBar: AppBar(title: Text('Vendor $vendorId')), body: const Center(child: Text('Not found')));
    }

    final statusColor = switch (app.status) {
      VendorApprovalStatus.pending => Colors.orange,
      VendorApprovalStatus.approved => Colors.green,
      VendorApprovalStatus.rejected => Colors.red,
      VendorApprovalStatus.suspended => Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(title: Text(app.shopName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.store)),
                title: Text(app.shopName, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${app.city}\nOwner: ${app.ownerName}\n${app.email} • ${app.mobile}'),
                isThreeLine: true,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text(app.status.label, style: TextStyle(color: statusColor, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('Documents'),
                subtitle: Text('Business permit / ID / etc. (placeholder)'),
              ),
            ),
            if (app.status == VendorApprovalStatus.rejected && (app.adminNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Rejection reason'),
                  subtitle: Text(app.adminNote ?? ''),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (app.status == VendorApprovalStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final note = await _rejectDialog(context);
                        if (note != null && note.trim().isNotEmpty) {
                          ctrl.reject(app.id, note.trim());
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor rejected')));
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        ctrl.approve(app.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor approved')));
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _rejectDialog(BuildContext context) async {
    final c = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject vendor'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Reason (e.g., missing business permit)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Reject')),
        ],
      ),
    );
    c.dispose();
    return res;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
