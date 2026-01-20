import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/network/api_client.dart';



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
    final asyncVendors = ref.watch(adminVendorsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search vendor/applications',
            ),
            onChanged: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filter == null,
                  onSelected: (_) => setState(() => filter = null),
                ),
                const SizedBox(width: 8),
                ...VendorApprovalStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: filter == s,
                      onSelected: (_) => setState(() => filter = s),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: asyncVendors.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load vendors\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              data: (vendors) {
                final filtered = vendors.where((a) {
                  final needle = q.toLowerCase();

                  final matchQ = q.isEmpty ||
                      a.vendorName.toLowerCase().contains(needle) ||
                      a.ownerName.toLowerCase().contains(needle) ||
                      (a.email ?? '').toLowerCase().contains(needle) ||
                      (a.contactNumber ?? '').toLowerCase().contains(needle) ||
                      (a.addressLine1 ?? '').toLowerCase().contains(needle) ||
                      a.id.contains(q);

                  final matchF = filter == null || a.status == filter;
                  return matchQ && matchF;
                }).toList();

                return filtered.isEmpty
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
                              title: Text(a.vendorName, style: const TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text(
                                '${a.addressLine1Short} • Owner: ${a.ownerName}\nApplied: ${a.createdAtLabel}',
                              ),
                              isThreeLine: true,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  a.status.label,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
                                ),
                              ),
                              onTap: () => context.push('/a/vendors/${a.id}'),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Provider (API fetch)
/// =======================

final adminVendorsProvider = FutureProvider.autoDispose<List<AdminVendorRow>>((ref) async {
  // ✅ Adjust this ONE line if your API client/provider is different.
  final dio = ref.read(apiClientProvider).dio as Dio;

  // Your correct endpoint based on your example: /api/v1/admin/vendors
  final res = await dio.get('/api/v1/admin/vendors', queryParameters: {
    'per_page': 50,
  });

  final body = res.data;
  if (body is! Map) throw Exception('Unexpected response type');

  final data = body['data'];
  if (data is! Map) throw Exception('Missing data wrapper');

  final list = data['data'];
  if (list is! List) throw Exception('Missing paginated data list');

  return list
      .whereType<Map>()
      .map((m) => AdminVendorRow.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

class AdminVendorRow {
  AdminVendorRow({
    required this.id,
    required this.vendorName,
    required this.ownerName,
    required this.approvalStatus,
    required this.isActive,
    required this.createdAt,
    this.email,
    this.contactNumber,
    this.addressLine1,
  });

  final String id; // keep same as your old screen
  final String vendorName; // vendor_name
  final String ownerName; // name (or user.name)
  final String approvalStatus; // pending/approved/rejected
  final bool isActive;
  final DateTime createdAt;

  final String? email;
  final String? contactNumber;
  final String? addressLine1;

  VendorApprovalStatus get status {
    if (approvalStatus == 'approved' && !isActive) return VendorApprovalStatus.suspended;

    return switch (approvalStatus) {
      'pending' => VendorApprovalStatus.pending,
      'approved' => VendorApprovalStatus.approved,
      'rejected' => VendorApprovalStatus.rejected,
      _ => VendorApprovalStatus.pending,
    };
  }

  String get createdAtLabel {
    final d = createdAt;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String get addressLine1Short {
    final a = (addressLine1 ?? '').trim();
    if (a.isEmpty) return 'No address';
    // keep card clean: show first ~40 chars
    return a.length <= 40 ? a : '${a.substring(0, 40)}...';
  }

  factory AdminVendorRow.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user']) : null;

    final ownerName = (json['name']?.toString().trim().isNotEmpty ?? false)
        ? json['name'].toString()
        : (user?['name']?.toString() ?? '');

    return AdminVendorRow(
      id: (json['id'] as num).toInt().toString(),
      vendorName: (json['vendor_name'] ?? json['name'] ?? '').toString(),
      ownerName: ownerName,
      approvalStatus: (json['approval_status'] ?? 'pending').toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      email: (json['email'] ?? user?['email'])?.toString(),
      contactNumber: (json['contact_number'] ?? user?['contact_number'])?.toString(),
      addressLine1: (json['address_line1'] ?? user?['address_line1'])?.toString(),
    );
  }
}
