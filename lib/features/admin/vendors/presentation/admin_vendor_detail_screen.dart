import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/models/user_role.dart';

/// =======================
/// Load vendor JSON from Admin vendors endpoint
/// Response shape:
/// { data: { data: [ {vendor}, ... ], ...pagination } }
/// =======================
final adminVendorDetailRawProvider =
    FutureProvider.family.autoDispose<Map<String, dynamic>?, String>((ref, vendorId) async {
  final dio = ref.read(apiClientProvider).dio as Dio;

  final res = await dio.get(
    '/api/v1/admin/vendors',
    queryParameters: {'per_page': 50},
  );

  final body = res.data;
  if (body is! Map) throw Exception('Unexpected response type');

  final wrapper = body['data'];
  if (wrapper is! Map) throw Exception('Missing data wrapper');

  final list = wrapper['data'];
  if (list is! List) throw Exception('Missing data list');

  final found = list.whereType<Map>().cast<Map>().firstWhere(
        (m) => (m['id']?.toString() ?? '') == vendorId,
        orElse: () => <String, dynamic>{},
      );

  if (found.isEmpty) return null;
  return Map<String, dynamic>.from(found);
});

/// =======================
/// Nice UX action state
/// =======================
enum _VendorAction { approve, reject }

class _VendorActionState {
  const _VendorActionState({this.loading = false, this.action, this.error});
  final bool loading;
  final _VendorAction? action;
  final String? error;

  static const idle = _VendorActionState();

  _VendorActionState copyWith({bool? loading, _VendorAction? action, String? error}) {
    return _VendorActionState(
      loading: loading ?? this.loading,
      action: action ?? this.action,
      error: error,
    );
  }
}

final _vendorActionProvider =
    StateProvider.autoDispose<_VendorActionState>((ref) => _VendorActionState.idle);

/// =======================
/// API calls (matches your Laravel routes)
/// PATCH /vendors/{vendor}/approve
/// PATCH /vendors/{vendor}/reject  { reason }
/// =======================
Future<void> _apiApproveVendor(WidgetRef ref, String vendorId) async {
  final dio = ref.read(apiClientProvider).dio as Dio;
  await dio.patch('/api/v1/admin/vendors/$vendorId/approve');
}

Future<void> _apiRejectVendor(WidgetRef ref, String vendorId, String reason) async {
  final dio = ref.read(apiClientProvider).dio as Dio;
  await dio.patch(
    '/api/v1/admin/vendors/$vendorId/reject',
    data: {'reason': reason},
  );
}


/// Friendly Laravel error extraction
String _prettyDioError(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final msg = data['message'];
    if (msg != null && msg.toString().trim().isNotEmpty) return msg.toString();

    final errors = data['errors'];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v != null) return v.toString();
      }
    }
  }
  return e.message ?? 'Request failed';
}

Future<bool> _confirmApprove(BuildContext context, String vendorName) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Approve vendor?'),
      content: Text('This will approve "$vendorName" and allow the vendor to operate.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('Approve'),
        ),
      ],
    ),
  );
  return res == true;
}


Future<String?> _rejectDialog(BuildContext context) async {
  final c = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final res = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Reject vendor'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Reason (required) e.g., Missing business permit',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter a rejection reason.';
            if (v.trim().length < 5) return 'Please provide a bit more detail.';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(context, c.text.trim());
          },
          child: const Text('Reject'),
        ),
      ],
    ),
  );

  c.dispose();
  return res;
}

/// =======================
/// Screen
/// =======================
class AdminVendorDetailScreen extends ConsumerWidget {
  const AdminVendorDetailScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVendor = ref.watch(adminVendorDetailRawProvider(vendorId));
    final actionState = ref.watch(_vendorActionProvider);
    final isBusy = actionState.loading;

    return Scaffold(
      appBar: AppBar(title: Text('Vendor $vendorId')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncVendor.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Failed to load vendor\n$e',
              textAlign: TextAlign.center,
            ),
          ),
          data: (vendor) {
            if (vendor == null) {
              return const Center(child: Text('Not found'));
            }

            final user = _asMap(vendor['user']);

            final ownerName = _s(vendor['name']).isNotEmpty ? _s(vendor['name']) : _s(user['name']);
            final email = _s(vendor['email']).isNotEmpty ? _s(vendor['email']) : _s(user['email']);
            final vendorName =
                _s(vendor['vendor_name']).isNotEmpty ? _s(vendor['vendor_name']) : _s(vendor['name']);

            final contactNumber = _s(vendor['contact_number']).isNotEmpty
                ? _s(vendor['contact_number'])
                : _s(user['contact_number']);

            final phone = _s(vendor['phone']); // can be null

            final address1 = _s(vendor['address_line1']).isNotEmpty ? _s(vendor['address_line1']) : _s(user['address_line1']);
            final address2 = _s(vendor['address_line2']).isNotEmpty ? _s(vendor['address_line2']) : _s(user['address_line2']);
            final addressFull = _joinAddress(address1, address2);

            final approvalStatus = _s(vendor['approval_status']).isEmpty ? 'pending' : _s(vendor['approval_status']);
            final isActive = _b(vendor['is_active']);

            final tier = _dash(vendor['subscription_tier']);
            final tierExpiry = _formatIso(vendor['subscription_expires_at']);

            final customersServiced = _i(vendor['customers_serviced_count']);
            final completedOrders = _i(vendor['completed_orders_count']);
            final uniqueCustomers = _i(vendor['unique_customers_served_count']);
            final kgProcessed = _dash(vendor['kilograms_processed_total']);

            final ratingAvg = _dash(vendor['rating_avg']);
            final ratingCount = _i(vendor['rating_count']);
            final createdAt = _formatIso(vendor['created_at']);

            final statusEnum = _toStatusEnum(approvalStatus, isActive);
            final statusColor = switch (statusEnum) {
              VendorApprovalStatus.pending => Colors.orange,
              VendorApprovalStatus.approved => Colors.green,
              VendorApprovalStatus.rejected => Colors.red,
              VendorApprovalStatus.suspended => Colors.grey,
            };

            return ListView(
              children: [
                // Header
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: const CircleAvatar(child: Icon(Icons.store)),
                    title: Text(
                      vendorName.isEmpty ? 'Vendor' : vendorName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$addressFull\n${_dash(email)} • ${_dash(contactNumber)}',
                      maxLines: 2,
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
                        statusEnum.label,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Error box (actions)
                if (actionState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            actionState.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Profile
                _InfoSection(
                  title: 'Profile',
                  children: [
                    _InfoRow(label: 'Name', value: _dash(ownerName)),
                    _InfoRow(label: 'Email', value: _dash(email)),
                    _InfoRow(label: 'Contact number', value: _dash(contactNumber)),
                    _InfoRow(label: 'Phone (optional)', value: _dash(phone)),
                    _InfoRow(
                      label: 'Approval status',
                      value: statusEnum.label,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusEnum.label,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Business & Address
                _InfoSection(
                  title: 'Business & Address',
                  children: [
                    _InfoRow(label: 'Vendor name', value: _dash(vendorName)),
                    _InfoRow(label: 'Address line 1', value: _dash(address1)),
                    _InfoRow(label: 'Address line 2', value: _dash(address2)),
                  ],
                ),

                const SizedBox(height: 12),

                // Subscription & Performance
                _InfoSection(
                  title: 'Subscription & Performance',
                  children: [
                    _InfoRow(label: 'Active', value: isActive ? 'Yes' : 'No'),
                    _InfoRow(label: 'Tier', value: tier),
                    _InfoRow(label: 'Expires', value: tierExpiry),
                    const Divider(height: 20),
                    _InfoRow(label: 'Customers serviced', value: '$customersServiced'),
                    _InfoRow(label: 'Completed orders', value: '$completedOrders'),
                    _InfoRow(label: 'Unique customers', value: '$uniqueCustomers'),
                    _InfoRow(label: 'Kilograms processed', value: kgProcessed),
                    const Divider(height: 20),
                    _InfoRow(label: 'Rating', value: '$ratingAvg ($ratingCount reviews)'),
                    _InfoRow(label: 'Created', value: createdAt),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                if (statusEnum == VendorApprovalStatus.pending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isBusy
                              ? null
                              : () async {
                                  ref.read(_vendorActionProvider.notifier).state = _VendorActionState.idle;

                                  final reason = await _rejectDialog(context);
                                  if (reason == null) return;

                                  ref.read(_vendorActionProvider.notifier).state =
                                      const _VendorActionState(loading: true, action: _VendorAction.reject);

                                  try {
                                    await _apiRejectVendor(ref, vendorId, reason);

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vendor rejected')),
                                    );

                                    ref.invalidate(adminVendorDetailRawProvider(vendorId));
                                  } on DioException catch (e) {
                                    ref.read(_vendorActionProvider.notifier).state =
                                        _VendorActionState(loading: false, error: _prettyDioError(e));
                                  } catch (e) {
                                    ref.read(_vendorActionProvider.notifier).state =
                                        _VendorActionState(loading: false, error: e.toString());
                                  } finally {
                                    final cur = ref.read(_vendorActionProvider);
                                    if (cur.error == null) {
                                      ref.read(_vendorActionProvider.notifier).state = _VendorActionState.idle;
                                    } else {
                                      ref.read(_vendorActionProvider.notifier).state =
                                          cur.copyWith(loading: false);
                                    }
                                  }
                                },
                          icon: (actionState.loading && actionState.action == _VendorAction.reject)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isBusy
                              ? null
                              : () async {
                                  ref.read(_vendorActionProvider.notifier).state = _VendorActionState.idle;

                                  final ok = await _confirmApprove(context, vendorName);
                                  if (!ok) return;

                                  ref.read(_vendorActionProvider.notifier).state =
                                      const _VendorActionState(loading: true, action: _VendorAction.approve);

                                  try {
                                    await _apiApproveVendor(ref, vendorId);

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vendor approved')),
                                    );

                                    ref.invalidate(adminVendorDetailRawProvider(vendorId));
                                  } on DioException catch (e) {
                                    ref.read(_vendorActionProvider.notifier).state =
                                        _VendorActionState(loading: false, error: _prettyDioError(e));
                                  } catch (e) {
                                    ref.read(_vendorActionProvider.notifier).state =
                                        _VendorActionState(loading: false, error: e.toString());
                                  } finally {
                                    final cur = ref.read(_vendorActionProvider);
                                    if (cur.error == null) {
                                      ref.read(_vendorActionProvider.notifier).state = _VendorActionState.idle;
                                    } else {
                                      ref.read(_vendorActionProvider.notifier).state =
                                          cur.copyWith(loading: false);
                                    }
                                  }
                                },
                          icon: (actionState.loading && actionState.action == _VendorAction.approve)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
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
            );
          },
        ),
      ),
    );
  }
}

/// =======================
/// UI helpers (professional sections)
/// =======================
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// =======================
/// JSON helpers (safe parsing)
/// =======================
Map<String, dynamic> _asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v as Map) : <String, dynamic>{};

String _s(dynamic v) => (v ?? '').toString().trim();

String _dash(dynamic v) => _s(v).isEmpty ? '—' : _s(v);

int _i(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(_s(v)) ?? 0;
}

bool _b(dynamic v) {
  if (v is bool) return v;
  final t = _s(v).toLowerCase();
  return t == '1' || t == 'true' || t == 'yes';
}

String _formatIso(dynamic iso) {
  final s = _s(iso);
  if (s.isEmpty) return '—';
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

String _joinAddress(String line1, String line2) {
  final a = line1.trim();
  final b = line2.trim();
  if (a.isEmpty && b.isEmpty) return '—';
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a, $b';
}

VendorApprovalStatus _toStatusEnum(String approvalStatus, bool isActive) {
  if (approvalStatus == 'approved' && !isActive) return VendorApprovalStatus.suspended;

  return switch (approvalStatus) {
    'pending' => VendorApprovalStatus.pending,
    'approved' => VendorApprovalStatus.approved,
    'rejected' => VendorApprovalStatus.rejected,
    _ => VendorApprovalStatus.pending,
  };
}
