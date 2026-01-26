import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vendor_shop_option_prices_screen.dart';

import '../data/vendor_service_prices_providers.dart';

class VendorShopServicePricesScreen extends ConsumerWidget {
  const VendorShopServicePricesScreen({
    super.key,
    required this.vendorId,
    required this.shopId,
    required this.shopName,
  });

  final int vendorId;
  final int shopId;
  final String shopName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(
      vendorServicePricesProvider((vendorId: vendorId, shopId: shopId)),
    );
    final servicesAsync = ref.watch(servicesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Service Prices'),
            Text(
              shopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        onPressed: () async {
          final services = await servicesAsync.when(
            data: (d) async => d,
            loading: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loading services...')),
              );
              return <Map<String, dynamic>>[];
            },
            error: (e, _) async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Services load error: $e')),
              );
              return <Map<String, dynamic>>[];
            },
          );

          if (services.isEmpty) return;

          final existing = await pricesAsync.when(
            data: (d) async => d,
            loading: () async => <Map<String, dynamic>>[],
            error: (_, __) async => <Map<String, dynamic>>[],
          );

          // prevent duplicates (shop_id + service_id unique)
          final existingServiceIds = existing.map((e) => e['service_id']).toSet();

          if (!context.mounted) return;

          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => _ServicePriceFormSheet(
              vendorId: vendorId,
              shopId: shopId,
              services: services.where((s) => !existingServiceIds.contains(s['id'])).toList(),
            ),
          );
        },
      ),
      body: pricesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (items) {
          return servicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(message: 'Failed to load services: $e'),
            data: (services) {
              final serviceNameById = <int, String>{};
              for (final s in services) {
                final id = s['id'];
                if (id is int) {
                  serviceNameById[id] = (s['name'] ?? 'Service #$id').toString();
                }
              }
/*
              if (items.isEmpty) {
                return _EmptyState(
                  title: 'No services yet',
                  subtitle: 'Add your first service for this shop.',
                  onAdd: () async {
                    if (!context.mounted) return;
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _ServicePriceFormSheet(
                        vendorId: vendorId,
                        shopId: shopId,
                        services: services,
                      ),
                    );
                  },
                );
              }
          */
              final activeCount = items.where((e) => e['is_active'] == true).length;

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  vendorServicePricesProvider((vendorId: vendorId, shopId: shopId)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  children: [
                    _SummaryCard(
                      shopName: shopName,
                      total: items.length,
                      active: activeCount,
                    ),
                    const SizedBox(height: 12),
                    ...items.map((row) {
                      final id = row['id'] as int;
                      final serviceId = row['service_id'] as int?;
                      final model = (row['pricing_model'] ?? 'per_kg_min').toString();
                      final isActive = row['is_active'] == true;

                      final serviceName = serviceId != null
                          ? (serviceNameById[serviceId] ?? 'Service #$serviceId')
                          : 'Service';

                      final priceLabel = _priceSummary(row);

                      final leadingIcon = _serviceIconForName(serviceName);
                      final modelLabel = _modelLabel(model);
                      final modelIcon = _modelIcon(model);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey('vsp_$id'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Service?'),
                                content: Text('Remove pricing for “$serviceName”?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            await ref.read(vendorServicePricesActionsProvider).delete(vendorId, shopId, id);
                          },
                        //This is where the recursive is done
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                leading: CircleAvatar(child: Icon(leadingIcon)),
                                title: Text(
                                  serviceName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _Chip(icon: modelIcon, label: modelLabel),
                                      _Chip(icon: Icons.payments_outlined, label: priceLabel),
                                      _Chip(
                                        icon: isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                                        label: isActive ? 'Active' : 'Inactive',
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      if (!context.mounted) return;
                                      await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => _ServicePriceFormSheet(
                                          vendorId: vendorId,
                                          shopId: shopId,
                                          services: services,
                                          editRow: row,
                                        ),
                                      );
                                      return;
                                    }

                                    if (v == 'delete') {
                                      await _deleteRow(
                                        context,
                                        ref,
                                        vendorId: vendorId,
                                        shopId: shopId,
                                        priceId: id,
                                        serviceName: serviceName,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Edit'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete_outline),
                                        title: Text('Delete'),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  if (!context.mounted) return;
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => _ServicePriceFormSheet(
                                      vendorId: vendorId,
                                      shopId: shopId,
                                      services: services,
                                      editRow: row,
                                    ),
                                  );
                                },
                              ),

                              // ✅ CHILDREN (per record)
                              // ✅ CHILDREN (per record)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                child: Column(
                                  children: [
                                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
                                    const SizedBox(height: 10),

                                    // ✅ Option Prices list (API)
                                    Consumer(builder: (context, ref, _) {
                                      final key = OptionPricesKey(
                                        vendorId: vendorId,
                                        shopId: shopId,
                                        vendorServicePriceId: id, // ✅ current service price record id
                                      );

                                      final async = ref.watch(vendorServiceOptionPricesProvider(key));
                                      return async.when(
                                        loading: () => const Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        error: (e, _) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Failed to load options: $e',
                                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                                          ),
                                        ),
                                        data: (items) {
                                          

                                          return Column(
                          children: items.map((row) {
                            // row is VendorServiceOptionPriceLite (MODEL), not Map

                            final name = row.serviceOption?.name ?? 'Option';
                            final kind = (row.serviceOption?.kind ?? '').trim();
                            final price = row.price?.toString() ?? '';
                            final isActive = row.isActive;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      kind.isEmpty ? name : '$name • $kind',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    price.isEmpty ? '-' : price,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                                    size: 18,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );

                },
              );
            }),
          ],
        ),
      ),
      // ✅ Service Options (per service price)
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(
          children: [
            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
            const SizedBox(height: 10),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Service Options',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorShopOptionPricesScreen(
                          vendorId: vendorId,
                          shopId: shopId,
                          shopName: shopName,
                          vendorServicePriceId: id, // ✅ IMPORTANT: parent service price id
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ✅ quick preview list under the service price (optional but nice)
            Builder(builder: (context) {
              final async = ref.watch(
                vendorShopOptionPricesProvider((
                  vendorId: vendorId,
                  shopId: shopId,
                  vendorServicePriceId: id,
                )),
              );

              return async.when(
                loading: () => const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Failed to load options: $e',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No service options added.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }

                  // Show only first few as preview
                  final preview = items.take(3).toList();

                  return Column(
                    children: preview.map((row) {
                      final name = row.serviceOption?.name ?? 'Option';
                      final kind = (row.serviceOption?.kind ?? '').trim();
                      final price = row.price?.toString() ?? '';
                      final isActive = row.isActive;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                kind.isEmpty ? name : '$name • $kind',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              price.isEmpty ? '-' : price,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              isActive
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              size: 18,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }),
          ],
        ),
      ),

      /*
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(
          children: [
            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
            const SizedBox(height: 10),

            // Put whatever "children" you want here:
            // Example placeholder:
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Children goes here…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ), */
    ],
  ),
),

                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _priceSummary(Map<String, dynamic> row) { 
    final model = (row['pricing_model'] ?? 'per_kg_min').toString();
    String fmt(dynamic v) => (v == null || (v is String && v.trim().isEmpty)) ? '-' : v.toString();

    if (model == 'per_kg_min') {
      final minKg = fmt(row['min_kg']);
      final rate = fmt(row['rate_per_kg']);
      return 'min $minKg kg • $rate /kg';
    }
    if (model == 'per_block') {
      final kg = fmt(row['block_kg']);
      final p = fmt(row['block_price']);
      return '$kg kg • $p /block';
    }
    final fp = fmt(row['flat_price']);
    return '$fp flat';
  }

  static String _modelLabel(String model) {
    switch (model) {
      case 'per_block':
        return 'Per block';
      case 'flat':
        return 'Flat';
      case 'per_kg_min':
      default:
        return 'Per kg';
    }
  }

  static IconData _modelIcon(String model) {
    switch (model) {
      case 'per_block':
        return Icons.inventory_2_outlined;
      case 'flat':
        return Icons.receipt_long_outlined;
      case 'per_kg_min':
      default:
        return Icons.scale_outlined;
    }
  }

  // ✅ safer icon set (works on more Flutter versions)
  static IconData _serviceIconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('dry')) return Icons.local_fire_department_outlined;
    if (n.contains('iron')) return Icons.checkroom;
    if (n.contains('shoe')) return Icons.directions_walk;
    if (n.contains('curtain')) return Icons.window;
    if (n.contains('blanket') || n.contains('bedding') || n.contains('bed')) return Icons.bed;
    if (n.contains('carpet') || n.contains('rug')) return Icons.grid_view;
    if (n.contains('sanitize') || n.contains('disinfect')) return Icons.cleaning_services;
    if (n.contains('stain')) return Icons.cleaning_services;
    return Icons.local_laundry_service;
  }

  static Future<void> _deleteRow(
    BuildContext context,
    WidgetRef ref, {
    required int vendorId,
    required int shopId,
    required int priceId,
    required String serviceName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete price?'),
        content: Text('Remove pricing for “$serviceName”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await ref.read(vendorServicePricesActionsProvider).delete(vendorId, shopId, priceId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted')),
      );
    }
  }


}


class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.shopName,
    required this.total,
    required this.active,
  });

  final String shopName;
  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.store_mall_directory_outlined)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('$active active • $total total'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Info',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('How pricing works'),
                    content: const Text(
                      'Each shop can set its own pricing per service. '
                      'Service + shop is unique, so a service can only have one price row per shop.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
            )
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.price_change_outlined, size: 52),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add price'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ServicePriceFormSheet extends ConsumerStatefulWidget {
  const _ServicePriceFormSheet({
    required this.vendorId,
    required this.shopId,
    required this.services,
    this.editRow,
  });

  final int vendorId;
  final int shopId;
  final List<Map<String, dynamic>> services;
  final Map<String, dynamic>? editRow;

  @override
  ConsumerState<_ServicePriceFormSheet> createState() => _ServicePriceFormSheetState();
}

class _ServicePriceFormSheetState extends ConsumerState<_ServicePriceFormSheet> {
  final _formKey = GlobalKey<FormState>();

  int? _serviceId;
  String _model = 'per_kg_min';

  final _minKg = TextEditingController();
  final _ratePerKg = TextEditingController();
  final _ratePerPiece = TextEditingController(); // ✅ per_piece support

  bool _isActive = true;
  bool _saving = false;

  bool _overrideAllowed = true; // ✅ from services.allow_vendor_override_price

  bool get isEdit => widget.editRow != null;

  Map<int, Map<String, dynamic>> get _serviceById {
    final m = <int, Map<String, dynamic>>{};
    for (final s in widget.services) {
      final id = s['id'];
      if (id is int) m[id] = s;
    }
    return m;
  }

  @override
  void initState() {
    super.initState();

    final r = widget.editRow;
    if (r != null) {
      _serviceId = r['service_id'] as int?;
      _model = (r['pricing_model'] ?? 'per_kg_min').toString();
      _isActive = r['is_active'] == true;

      _minKg.text = (r['min_kg'] ?? '').toString();
      _ratePerKg.text = (r['rate_per_kg'] ?? '').toString();
      _ratePerPiece.text = (r['rate_per_piece'] ?? '').toString();
    }

    // ✅ apply service defaults once if we have service_id (edit flow)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sid = _serviceId;
      if (sid != null) {
        final svc = _serviceById[sid];
        if (svc != null) _applyServiceRules(svc, forceFill: !_overrideAllowed);
      }
    });
  }

  @override
  void dispose() {
    _minKg.dispose();
    _ratePerKg.dispose();
    _ratePerPiece.dispose();
    super.dispose();
  }

  String? _n(String v) => v.trim().isEmpty ? null : v.trim();

  // ✅ Map service defaults -> UI
  void _applyServiceRules(Map<String, dynamic> svc, {bool forceFill = true}) {
    final allowOverride = (svc['allow_vendor_override_price'] == null)
        ? true
        : (svc['allow_vendor_override_price'] == true);

    // pricing model follows service.default_pricing_model (fallback base_unit)
    final defaultModel = (svc['default_pricing_model'] ?? '').toString();
    final baseUnit = (svc['base_unit'] ?? 'kg').toString();
    final modelFromService = (defaultModel.isNotEmpty)
        ? defaultModel
        : (baseUnit == 'item' ? 'per_piece' : 'per_kg_min');

    setState(() {
      _overrideAllowed = allowOverride;
      _model = modelFromService;
    });

    // Prefill fields from service defaults
    final dMinKg = svc['default_min_kg'];
    final dRateKg = svc['default_rate_per_kg'];
    final dRatePiece = svc['default_rate_per_piece'];

    void fillIf(bool condition, TextEditingController c, dynamic val) {
      if (!condition) return;
      c.text = (val == null) ? '' : val.toString();
    }

    // On CREATE: always fill
    // On EDIT: fill only if override is disabled (forceFill) OR field is empty
    final shouldFill = forceFill || !isEdit;

    if (_model == 'per_kg_min') {
      fillIf(shouldFill || _minKg.text.trim().isEmpty, _minKg, dMinKg);
      fillIf(shouldFill || _ratePerKg.text.trim().isEmpty, _ratePerKg, dRateKg);
      // clear piece field (optional)
      if (shouldFill && _ratePerPiece.text.isNotEmpty) _ratePerPiece.text = '';
    } else {
      // per_piece
      if (shouldFill && _minKg.text.isNotEmpty) _minKg.text = '';
      if (shouldFill && _ratePerKg.text.isNotEmpty) _ratePerKg.text = '';
      fillIf(shouldFill || _ratePerPiece.text.trim().isEmpty, _ratePerPiece, dRatePiece);
    }
  }

  Map<String, dynamic> _buildPayload() {
    // If override is disabled, ensure payload uses service defaults already set in controllers.
    return {
      'service_id': _serviceId,
      'pricing_model': _model,
      'min_kg': _model == 'per_kg_min' ? _n(_minKg.text) : null,
      'rate_per_kg': _model == 'per_kg_min' ? _n(_ratePerKg.text) : null,
      'rate_per_piece': _model == 'per_piece' ? _n(_ratePerPiece.text) : null,
      'is_active': _isActive,
    };
  }

  String _serviceName(Map<String, dynamic>? svc) => (svc?['name'] ?? '').toString();
  String _fmt(dynamic v) => (v == null || (v is String && v.trim().isEmpty)) ? '—' : v.toString();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final svc = (_serviceId == null) ? null : _serviceById[_serviceId!];
    final svcName = _serviceName(svc);

    // defaults from service
    final dModel = (svc?['default_pricing_model'] ?? '').toString();
    final baseUnit = (svc?['base_unit'] ?? 'kg').toString();
    final resolvedModel = dModel.isNotEmpty ? dModel : (baseUnit == 'item' ? 'per_piece' : 'per_kg_min');

    final dMinKg = _fmt(svc?['default_min_kg']);
    final dRateKg = _fmt(svc?['default_rate_per_kg']);
    final dRatePiece = _fmt(svc?['default_rate_per_piece']);

    final overrideText = _overrideAllowed ? 'Override allowed' : 'Override disabled';

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit price' : 'Add price',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ Service picker
              DropdownButtonFormField<int>(
                value: _serviceId,
                isExpanded: true,
                items: widget.services.map((s) {
                  final id = s['id'] as int;
                  final name = (s['name'] ?? 'Service #$id').toString();
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Row(
                      children: [
                        Icon(VendorShopServicePricesScreen._serviceIconForName(name), size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: isEdit
                    ? null
                    : (v) {
                        setState(() => _serviceId = v);
                        final svc = (v == null) ? null : _serviceById[v];
                        if (svc != null) _applyServiceRules(svc, forceFill: true);
                      },
                decoration: const InputDecoration(
                  labelText: 'Service',
                  prefixIcon: Icon(Icons.design_services_outlined),
                ),
                validator: (v) => (v == null) ? 'Select a service' : null,
              ),

              const SizedBox(height: 12),

              // ✅ Default pricing display card
              if (svc != null)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Defaults • ${svcName.isEmpty ? 'Service' : svcName}',
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.7)),
                              ),
                              child: Text(overrideText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Base unit: $baseUnit'),
                        Text('Default model: $resolvedModel'),
                        const SizedBox(height: 6),
                        if (resolvedModel == 'per_kg_min') ...[
                          Text('Default min kg: $dMinKg'),
                          Text('Default rate / kg: $dRateKg'),
                        ] else ...[
                          Text('Default rate / piece: $dRatePiece'),
                        ],
                        if (!_overrideAllowed) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Override is disabled. Inputs are locked to the default pricing.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ✅ pricing model follows service default, and vendor can’t change it
              // (even if override is allowed, your BRD #2 says follow services_base_unit)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Pricing model',
                  prefixIcon: Icon(Icons.tune_outlined),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_model)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ✅ Fields: lock if override not allowed
              if (_model == 'per_kg_min') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minKg,
                        readOnly: !_overrideAllowed,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min KG',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        validator: (v) {
                          if (_model != 'per_kg_min') return null;
                          if (v == null || v.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ratePerKg,
                        readOnly: !_overrideAllowed,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rate / KG',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) {
                          if (_model != 'per_kg_min') return null;
                          if (v == null || v.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],

              if (_model == 'per_piece') ...[
                TextFormField(
                  controller: _ratePerPiece,
                  readOnly: !_overrideAllowed,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rate / piece',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    if (_model != 'per_piece') return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Active'),
                secondary: Icon(_isActive ? Icons.check_circle_outline : Icons.pause_circle_outline),
              ),

              const SizedBox(height: 16),

              // ✅ Save
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          // extra guard: if override disabled but service defaults are null -> block
                          if (svc != null && !_overrideAllowed) {
                            if (_model == 'per_kg_min' &&
                                (_minKg.text.trim().isEmpty || _ratePerKg.text.trim().isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Service defaults are missing. Please set defaults in Services table.')),
                              );
                              return;
                            }
                            if (_model == 'per_piece' && _ratePerPiece.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Service defaults are missing. Please set defaults in Services table.')),
                              );
                              return;
                            }
                          }

                          setState(() => _saving = true);
                          try {
                            final payload = _buildPayload();
                            final actions = ref.read(vendorServicePricesActionsProvider);

                            if (isEdit) {
                              final id = widget.editRow!['id'] as int;
                              await actions.update(widget.vendorId, widget.shopId, id, payload);
                            } else {
                              await actions.create(widget.vendorId, widget.shopId, payload);
                            }

                            if (mounted) Navigator.pop(context);
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: Text(_saving ? 'Saving…' : (isEdit ? 'Update' : 'Create')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
