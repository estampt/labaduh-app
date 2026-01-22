import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import 'admin_addon_form_dialog.dart';

/// Provider to fetch addons
final adminAddonsProvider = FutureProvider.autoDispose.family<PaginatedAddons, AddonsQuery>((ref, query) async {
  final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed

  final res = await dio.get(
    '/api/v1/admin/addons',
    queryParameters: {
      'per_page': query.perPage,
      if (query.search.isNotEmpty) 'search': query.search,
      if (query.groupKey.isNotEmpty) 'group_key': query.groupKey,
      if (query.activeOnly != null) 'is_active': query.activeOnly,
      'page': query.page,
    },
  );

  final body = res.data;
  if (body is! Map) throw Exception('Unexpected response: $body');

  // Expected: { data: { current_page, data:[...], ... } }
  final data = body['data'];
  if (data is Map && data['data'] is List) {
    final items = (data['data'] as List)
        .whereType<Map>()
        .map((m) => AdminAddon.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return PaginatedAddons(
      items: items,
      currentPage: (data['current_page'] as num?)?.toInt() ?? query.page,
      lastPage: (data['last_page'] as num?)?.toInt() ?? 1,
      total: (data['total'] as num?)?.toInt() ?? items.length,
    );
  }

  // Fallback: {data:[...]}
  if (body['data'] is List) {
    final items = (body['data'] as List)
        .whereType<Map>()
        .map((m) => AdminAddon.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return PaginatedAddons(items: items, currentPage: 1, lastPage: 1, total: items.length);
  }

  throw Exception('Unexpected addons payload shape.');
});

class AddonsQuery {
  const AddonsQuery({
    required this.search,
    required this.groupKey,
    required this.activeOnly,
    required this.page,
    required this.perPage,
  });

  final String search;
  final String groupKey;
  final bool? activeOnly; // null=all
  final int page;
  final int perPage;

  AddonsQuery copyWith({
    String? search,
    String? groupKey,
    bool? activeOnly,
    int? page,
    int? perPage,
  }) {
    return AddonsQuery(
      search: search ?? this.search,
      groupKey: groupKey ?? this.groupKey,
      activeOnly: activeOnly,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AddonsQuery &&
      other.search == search &&
      other.groupKey == groupKey &&
      other.activeOnly == activeOnly &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode => Object.hash(search, groupKey, activeOnly, page, perPage);
}

class PaginatedAddons {
  const PaginatedAddons({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminAddon> items;
  final int currentPage;
  final int lastPage;
  final int total;
}

class AdminAddon {
  const AdminAddon({
    required this.id,
    required this.name,
    required this.groupKey,
    required this.description,
    required this.price,
    required this.priceType,
    required this.isActive,
    required this.sortOrder,
    required this.isRequired,
    required this.isMultiSelect,
  });

  final String id;
  final String name;
  final String groupKey;
  final String description;

  final double price;
  final String priceType; // fixed / per_kg / per_item
  final bool isActive;
  final int sortOrder;

  final bool isRequired;
  final bool isMultiSelect;

  factory AdminAddon.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '0').toString()) ?? 0;
    }

    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse((v ?? '0').toString()) ?? 0;
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      return (v ?? '').toString() == '1' || (v ?? '').toString().toLowerCase() == 'true';
    }

    return AdminAddon(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      groupKey: (json['group_key'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _toDouble(json['price']),
      priceType: (json['price_type'] ?? 'fixed').toString(),
      isActive: _toBool(json['is_active']),
      sortOrder: _toInt(json['sort_order']),
      isRequired: _toBool(json['is_required']),
      isMultiSelect: _toBool(json['is_multi_select']),
    );
  }
}

class AdminAddonsScreen extends ConsumerStatefulWidget {
  const AdminAddonsScreen({super.key});

  @override
  ConsumerState<AdminAddonsScreen> createState() => _AdminAddonsScreenState();
}

class _AdminAddonsScreenState extends ConsumerState<AdminAddonsScreen> {
  String search = '';
  String groupKey = '';
  bool? activeOnly = true; // default: active
  int page = 1;

  AddonsQuery get query => AddonsQuery(
        search: search.trim(),
        groupKey: groupKey.trim(),
        activeOnly: activeOnly,
        page: page,
        perPage: 30,
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminAddonsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add-ons'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminAddonsProvider(query)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => const AdminAddonFormDialog(),
          );

          if (ok == true) {
            ref.invalidate(adminAddonsProvider(query));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Filters(
              search: search,
              groupKey: groupKey,
              activeOnly: activeOnly,
              onSearchChanged: (v) => setState(() {
                search = v;
                page = 1;
              }),
              onGroupChanged: (v) => setState(() {
                groupKey = v;
                page = 1;
              }),
              onActiveChanged: (v) => setState(() {
                activeOnly = v;
                page = 1;
              }),
              onOpenCreate: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => const AdminAddonFormDialog(),
                );
                if (ok == true) ref.invalidate(adminAddonsProvider(query));
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load add-ons\n$e', textAlign: TextAlign.center)),
                data: (paged) {
                  final items = paged.items;

                  if (items.isEmpty) {
                    return const Center(
                      child: Text('No add-ons found', style: TextStyle(color: Colors.black54)),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _AddonTile(
                            addon: items[i],
                            onEdit: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AdminAddonFormDialog(existing: items[i]),
                              );
                              if (ok == true) ref.invalidate(adminAddonsProvider(query));
                            },
                            onToggleActive: (v) async {
                              await _patchAddon(ref, items[i].id, {'is_active': v});
                              ref.invalidate(adminAddonsProvider(query));
                            },
                            onDelete: () async {
                              final ok = await _confirmDelete(context, items[i].name);
                              if (!ok) return;
                              await _deleteAddon(ref, items[i].id);
                              ref.invalidate(adminAddonsProvider(query));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Pager(
                        current: paged.currentPage,
                        last: paged.lastPage,
                        total: paged.total,
                        onPrev: paged.currentPage > 1
                            ? () => setState(() => page = page - 1)
                            : null,
                        onNext: paged.currentPage < paged.lastPage
                            ? () => setState(() => page = page + 1)
                            : null,
                      ),
                    ],
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

class _Filters extends StatelessWidget {
  const _Filters({
    required this.search,
    required this.groupKey,
    required this.activeOnly,
    required this.onSearchChanged,
    required this.onGroupChanged,
    required this.onActiveChanged,
    required this.onOpenCreate,
  });

  final String search;
  final String groupKey;
  final bool? activeOnly;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<bool?> onActiveChanged;
  final VoidCallback onOpenCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search add-ons',
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                      hintText: 'Group key (e.g. fragrance, speed)',
                    ),
                    onChanged: onGroupChanged,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<bool?>(
                  value: activeOnly,
                  onChanged: onActiveChanged,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Active')),
                    DropdownMenuItem(value: false, child: Text('Inactive')),
                    DropdownMenuItem(value: null, child: Text('All')),
                  ],
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onOpenCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddonTile extends StatelessWidget {
  const _AddonTile({
    required this.addon,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final AdminAddon addon;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priceText = _priceLabel(addon.price, addon.priceType);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.extension_outlined)),
        title: Text(addon.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Group: ${addon.groupKey.isEmpty ? '-' : addon.groupKey} • $priceText'),
              if (addon.description.isNotEmpty) Text(addon.description, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: -6,
                children: [
                  _chip(addon.isRequired ? 'Required' : 'Optional'),
                  _chip(addon.isMultiSelect ? 'Multi-select' : 'Single-select'),
                  _chip('Sort: ${addon.sortOrder}'),
                ],
              ),
            ],
          ),
        ),
        trailing: SizedBox(
          width: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Switch(
                value: addon.isActive,
                onChanged: onToggleActive,
              ),
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Chip(
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.current,
    required this.last,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int current;
  final int last;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Page $current / $last • $total total', style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

String _priceLabel(double price, String priceType) {
  final p = price.toStringAsFixed(2);
  switch (priceType) {
    case 'per_kg':
      return '$p / kg';
    case 'per_item':
      return '$p / item';
    default:
      return '$p (fixed)';
  }
}

Future<void> _patchAddon(WidgetRef ref, String id, Map<String, dynamic> payload) async {
  final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed
  await dio.patch('/api/v1/admin/addons/$id', data: payload);
}

Future<void> _deleteAddon(WidgetRef ref, String id) async {
  final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed
  await dio.delete('/api/v1/admin/addons/$id');
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  return (await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete add-on'),
          content: Text('Delete "$name"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        ),
      )) ??
      false;
}
