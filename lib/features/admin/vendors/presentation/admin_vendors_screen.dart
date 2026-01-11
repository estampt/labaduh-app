import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_role.dart';
import '../../../vendor/state/vendor_applications_controller.dart';

class AdminVendorsScreen extends ConsumerStatefulWidget {
  const AdminVendorsScreen({super.key});

  @override
  ConsumerState<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends ConsumerState<AdminVendorsScreen> {
  String q = '';
  VendorApprovalStatus? filter;

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(vendorApplicationsProvider);

    final filtered = apps.where((a) {
      final matchQ = q.isEmpty ||
          a.shopName.toLowerCase().contains(q.toLowerCase()) ||
          a.ownerName.toLowerCase().contains(q.toLowerCase()) ||
          a.city.toLowerCase().contains(q.toLowerCase()) ||
          a.id.contains(q);
      final matchF = filter == null || a.status == filter;
      return matchQ && matchF;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search vendor/applications'),
            onChanged: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(label: const Text('All'), selected: filter == null, onSelected: (_) => setState(() => filter = null)),
                const SizedBox(width: 8),
                ...VendorApprovalStatus.values.map((s) => Padding(
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
                ? const Center(child: Text('No vendors found', style: TextStyle(color: Colors.black54)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = filtered[i];
                      final statusColor = switch (a.status) {
                        VendorApprovalStatus.pending => Colors.orange,
                        VendorApprovalStatus.approved => Colors.green,
                        VendorApprovalStatus.rejected => Colors.red,
                        VendorApprovalStatus.suspended => Colors.grey,
                      };

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.store)),
                          title: Text(a.shopName, style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text('${a.city} • Owner: ${a.ownerName}\nApplied: ${a.createdAtLabel}'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(a.status.label, style: TextStyle(color: statusColor, fontWeight: FontWeight.w900)),
                          ),
                          onTap: () => context.push('/a/vendors/${a.id}'),
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
