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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                child: const Icon(Icons.store),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.ownerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                [
                                  // Address line 1 + 2
                                  [
                                    a.addressLine1Short,
                                    if ((a.addressLine2 ?? '').trim().isNotEmpty) a.addressLine2!.trim(),
                                  ].join(' '),

                                  // Contact number (optional)
                                  if ((a.contactNumber ?? '').trim().isNotEmpty)
                                    'Contact: ${a.contactNumber!.trim()}',

                                  // Vendor name + applied date
                                  'Vendor: ${a.vendorName} • Applied: ${a.createdAtLabel}',
                                ].join('\n'),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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

/// =======================
/// Provider (API fetch)
/// =======================

final adminVendorsProvider =
    FutureProvider.autoDispose<List<AdminVendorRow>>((ref) async {
  final dio = ref.read(apiClientProvider).dio as Dio;

  final res = await dio.get(
    '/api/v1/admin/vendors',
    queryParameters: {'per_page': 50},
  );

  dynamic body = res.data;

  // If Dio returns something unexpected (rare), fail early.
  if (body is! Map) {
    throw Exception('Unexpected response type: ${body.runtimeType}');
  }

  // ✅ Expected: { "data": { "current_page":..., "data":[...] } }
  // But we also safely handle: { "data": [ ... ] }
  // And also: { "status":..., "data": { ... } }
  final dynamic dataWrapper = body['data'];

  List<dynamic> items;

  if (dataWrapper is Map) {
    final dynamic inner = dataWrapper['data'];
    if (inner is List) {
      items = inner;
    } else {
      throw Exception('Missing "data.data" list in response');
    }
  } else if (dataWrapper is List) {
    // fallback: { data: [ ... ] }
    items = dataWrapper;
  } else {
    throw Exception('Missing "data" wrapper in response');
  }

  return items
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
    this.addressLine2,
  });

  final String id; // keep same as your old screen
  final String vendorName; // vendor_name
  final String ownerName; // name (or user.name)
  final String approvalStatus; // pending/approved/rejected
  String? addressLine2;
  String? contactNumber;
  final bool isActive;
  final DateTime createdAt;

  final String? email; 
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
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};

    // Safe id parse (handles int/string)
    final idVal = json['id'];
    final id = idVal == null
        ? ''
        : (idVal is num ? idVal.toInt().toString() : idVal.toString());

    // Owner name: prefer root name if not empty, else fallback to user.name
    final rootName = (json['name'] ?? '').toString().trim();
    final ownerName = rootName.isNotEmpty
        ? rootName
        : (user['name'] ?? '').toString();

    // Vendor name: prefer vendor_name, else fallback to vendor's name
    final vendorName = (json['vendor_name'] ?? json['name'] ?? '').toString();

    // Vendor name: prefer vendor_name, else fallback to vendor's name
    final address_line2 = (json['address_line2'] ?? '').toString();

    final contact_number = (json['contact_number'] ?? '').toString();

    // created_at parsing (nullable)
    final createdAtStr = (json['created_at'] ?? '').toString();
    final createdAt = DateTime.tryParse(createdAtStr);

    return AdminVendorRow(
      id: id,
      vendorName: vendorName,
      ownerName: ownerName,
      approvalStatus: (json['approval_status'] ?? 'pending').toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0), // 1970 as explicit fallback
      email: (json['email'] ?? user['email'])?.toString(),
      contactNumber: (json['contact_number'] ?? user['contact_number'])?.toString(),
      addressLine1: (json['address_line1'] ?? user['address_line1'])?.toString(),
      addressLine2: (json['address_line2'] ?? user['address_line2'])?.toString(), 
    );
  }

}
