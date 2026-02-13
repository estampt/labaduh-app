import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../../core/network/api_client.dart';
import 'admin_services_screen.dart'; // for adminServicesProvider invalidation

enum OptionKind { option, addon }

extension OptionKindX on OptionKind {
  String get key => this == OptionKind.addon ? 'addon' : 'option';
  String get label => this == OptionKind.addon ? 'Add-ons' : 'Options';
}

final adminServiceOptionsProvider = FutureProvider.autoDispose.family<List<ServiceOptionRow>, _OptArgs>((ref, args) async {
  final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed

  final res = await dio.get(
    '/admin/service-options',
    queryParameters: {
      'kind': args.kind.key,
      'per_page': 200,
    },
  );
  
  final body = res.data;
  List list;
  if (body is Map && body['data'] is Map && (body['data']['data'] is List)) {
    list = body['data']['data'] as List;
  } else if (body is Map && body['data'] is List) {
    list = body['data'] as List;
  } else if (body is List) {
    list = body;
  } else {
    throw Exception('Unexpected options response');
  }

  return list
      .whereType<Map>()
      .map((m) => ServiceOptionRow.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

class _OptArgs {
  const _OptArgs(this.serviceId, this.kind);
  final String serviceId;
  final OptionKind kind;

  @override
  bool operator ==(Object other) => other is _OptArgs && other.serviceId == serviceId && other.kind == kind;
  @override
  int get hashCode => Object.hash(serviceId, kind);
}

class ServiceOptionRow {
  ServiceOptionRow({
    required this.id,
    required this.serviceId,
    required this.kind,
    required this.name,
    required this.price,
    required this.priceType,
    required this.isActive,
    required this.groupKey,
    required this.sortOrder,
  });

  final String id;
  final String serviceId;
  final String kind; // option/addon
  final String name;
  final double price;
  final String priceType; // fixed/per_kg/per_item
  final bool isActive;

  final String? groupKey; // for addon
  final int sortOrder;

  factory ServiceOptionRow.fromJson(Map<String, dynamic> json) {
    final p = json['price'];
    double price = 0;
    if (p is num) price = p.toDouble();
    if (p is String) price = double.tryParse(p) ?? 0;

    return ServiceOptionRow(
      id: json['id'].toString(),
      serviceId: (json['service_id'] ?? '').toString(),
      kind: (json['kind'] ?? 'option').toString(),
      name: (json['name'] ?? '').toString(),
      price: price,
      priceType: (json['price_type'] ?? 'fixed').toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      groupKey: json['group_key']?.toString(),
      sortOrder: (json['sort_order'] is num) ? (json['sort_order'] as num).toInt() : (int.tryParse('${json['sort_order']}') ?? 0),
    );
  }
}

class AdminServiceOptionsScreen extends ConsumerStatefulWidget {
  const AdminServiceOptionsScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  final String serviceId;
  final String serviceName;

  @override
  ConsumerState<AdminServiceOptionsScreen> createState() => _AdminServiceOptionsScreenState();
}

class _AdminServiceOptionsScreenState extends ConsumerState<AdminServiceOptionsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String q = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = _tab.index == 1 ? OptionKind.addon : OptionKind.option;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Options'),
            Tab(text: 'Add-ons'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => _CreateEditOptionDialog(
              serviceId: widget.serviceId,
              kind: kind,
            ),
          );
          if (created == true) {
            ref.invalidate(adminServiceOptionsProvider(_OptArgs(widget.serviceId, kind)));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search ${kind.label.toLowerCase()}',
              ),
              onChanged: (v) => setState(() => q = v.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _OptionsList(
                serviceId: widget.serviceId,
                kind: kind,
                query: q,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsList extends ConsumerWidget {
  const _OptionsList({required this.serviceId, required this.kind, required this.query});
  final String serviceId;
  final OptionKind kind;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminServiceOptionsProvider(_OptArgs(serviceId, kind)));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load ${kind.label}\n$e', textAlign: TextAlign.center)),
      data: (rows) {
        final filtered = rows.where((o) {
          if (query.isEmpty) return true;
          final n = query.toLowerCase();
          return o.name.toLowerCase().contains(n) ||
              (o.groupKey ?? '').toLowerCase().contains(n) ||
              o.priceType.toLowerCase().contains(n);
        }).toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No ${kind.label.toLowerCase()} found', style: const TextStyle(color: Colors.black54)));
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final o = filtered[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  kind == OptionKind.addon
                      ? 'Group: ${o.groupKey ?? '-'} • ${_priceLabel(o)}'
                      : _priceLabel(o),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: o.isActive,
                      onChanged: (v) async {
                        await _patchOption(
                          ref,
                          optionId: o.id,
                          payload: {'is_active': v},
                        );
                        ref.invalidate(adminServiceOptionsProvider(_OptArgs(serviceId, kind)));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final updated = await showDialog<bool>(
                          context: context,
                          builder: (_) => _CreateEditOptionDialog(
                            serviceId: serviceId,
                            kind: kind,
                            existing: o,
                          ),
                        );
                        if (updated == true) {
                          ref.invalidate(adminServiceOptionsProvider(_OptArgs(serviceId, kind)));
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await _confirmDelete(context, o.name);
                        if (!ok) return;
                        await _deleteOption(ref, optionId: o.id);
                        ref.invalidate(adminServiceOptionsProvider(_OptArgs(serviceId, kind)));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _priceLabel(ServiceOptionRow o) {
  final p = o.price.toStringAsFixed(2);
  switch (o.priceType) {
    case 'per_kg':
      return 'Price: $p / kg';
    case 'per_item':
      return 'Price: $p / item';
    default:
      return 'Price: $p (fixed)';
  }
}

Future<void> _patchOption(WidgetRef ref, {required String optionId, required Map<String, dynamic> payload}) async {
  final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed
  await dio.patch('/admin/service-options/$optionId', data: payload);

  // refresh services list too (if you show counts later)
  ref.invalidate(adminServicesProvider);
}

Future<void> _deleteOption(WidgetRef ref, {required String optionId}) async {
  final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed
  await dio.delete('/admin/service-options/$optionId');
  ref.invalidate(adminServicesProvider);
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  return (await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete'),
          content: Text('Delete "$name"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        ),
      )) ??
      false;
}

class _CreateEditOptionDialog extends ConsumerStatefulWidget {
  const _CreateEditOptionDialog({
    required this.serviceId,
    required this.kind,
    this.existing,
  });

  final String serviceId;
  final OptionKind kind;
  final ServiceOptionRow? existing;

  @override
  ConsumerState<_CreateEditOptionDialog> createState() => _CreateEditOptionDialogState();
}

class _CreateEditOptionDialogState extends ConsumerState<_CreateEditOptionDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController groupCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController sortCtrl;

  String priceType = 'fixed';
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    nameCtrl = TextEditingController(text: e?.name ?? '');
    groupCtrl = TextEditingController(text: e?.groupKey ?? '');
    priceCtrl = TextEditingController(text: (e?.price ?? 0).toStringAsFixed(2));
    sortCtrl = TextEditingController(text: (e?.sortOrder ?? 0).toString());

    priceType = e?.priceType ?? 'fixed';
    isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    groupCtrl.dispose();
    priceCtrl.dispose();
    sortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit ${widget.kind.label}' : 'Add ${widget.kind.label.substring(0, widget.kind.label.length - 1)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            if (widget.kind == OptionKind.addon)
              TextField(
                controller: groupCtrl,
                decoration: const InputDecoration(labelText: 'Group Key (e.g., fragrance, speed)'),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priceType,
                    items: const [
                      DropdownMenuItem(value: 'fixed', child: Text('fixed')),
                      DropdownMenuItem(value: 'per_kg', child: Text('per_kg')),
                      DropdownMenuItem(value: 'per_item', child: Text('per_item')),
                    ],
                    onChanged: (v) => setState(() => priceType = v ?? 'fixed'),
                    decoration: const InputDecoration(labelText: 'Price Type'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort Order'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
              title: const Text('Active'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;

            final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
            final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;

            final payload = <String, dynamic>{
              'name': name,
              'price': price,
              'price_type': priceType,
              'is_active': isActive,
              'sort_order': sort,
            };

            if (widget.kind == OptionKind.addon) {
              payload['group_key'] = groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim();
            }

            try {
              final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed

              if (isEdit) {
                await dio.patch('/admin/service-options/${widget.existing!.id}', data: payload);
              } else {
                await dio.post(
                  '/admin/services/',
                  data: {
                    ...payload,
                    'kind': widget.kind.key,
                  },
                );
              }

              ref.invalidate(adminServicesProvider);
              Navigator.pop(context, true);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
            }
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
