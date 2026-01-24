import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

              if (items.isEmpty) {
                return _EmptyState(
                  title: 'No prices yet',
                  subtitle: 'Add your first service price for this shop.',
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
                                title: const Text('Delete price?'),
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
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                            ),
                            child: ListTile(
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
                                      icon: isActive
                                          ? Icons.check_circle_outline
                                          : Icons.pause_circle_outline,
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
                                  PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
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

  final _blockKg = TextEditingController();
  final _blockPrice = TextEditingController();

  final _flatPrice = TextEditingController();

  bool _isActive = true;
  bool _saving = false;

  bool get isEdit => widget.editRow != null;

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
      _blockKg.text = (r['block_kg'] ?? '').toString();
      _blockPrice.text = (r['block_price'] ?? '').toString();
      _flatPrice.text = (r['flat_price'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _minKg.dispose();
    _ratePerKg.dispose();
    _blockKg.dispose();
    _blockPrice.dispose();
    _flatPrice.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final id = widget.editRow?['id'] as int?;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete price?'),
        content: const Text('This will remove this service price from the shop.'),
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

    setState(() => _saving = true);
    try {
      await ref.read(vendorServicePricesActionsProvider).delete(
            widget.vendorId,
            widget.shopId,
            id,
          );

      // ✅ Close ONLY the bottom sheet after successful delete
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  Map<String, dynamic> _buildPayload() {
    String? n(String v) => v.trim().isEmpty ? null : v.trim();

    return {
      'service_id': _serviceId,
      'pricing_model': _model,
      'min_kg': n(_minKg.text),
      'rate_per_kg': n(_ratePerKg.text),
      'block_kg': n(_blockKg.text),
      'block_price': n(_blockPrice.text),
      'flat_price': n(_flatPrice.text),
      'is_active': _isActive,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // simple drag handle (no showDragHandle param)
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
              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: _serviceId,
                isExpanded: true, // ✅ important
                items: widget.services.map((s) {
                  final id = s['id'] as int;
                  final name = (s['name'] ?? 'Service #$id').toString();
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Row(
                      children: [
                        Icon(VendorShopServicePricesScreen._serviceIconForName(name), size: 18),
                        const SizedBox(width: 8),
                        Flexible( // ✅ instead of Expanded
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: isEdit ? null : (v) => setState(() => _serviceId = v),
                decoration: const InputDecoration(
                  labelText: 'Service',
                  prefixIcon: Icon(Icons.design_services_outlined),
                ),
                validator: (v) => (v == null) ? 'Select a service' : null,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _model,
                items: const [
                  DropdownMenuItem(value: 'per_kg_min', child: Text('Per KG (optional minimum KG)')),
                  DropdownMenuItem(value: 'per_block', child: Text('Per Block (kg + block price)')),
                  DropdownMenuItem(value: 'flat', child: Text('Flat price')),
                ],
                onChanged: (v) => setState(() => _model = v ?? 'per_kg_min'),
                decoration: const InputDecoration(
                  labelText: 'Pricing model',
                  prefixIcon: Icon(Icons.tune_outlined),
                ),
              ),

              const SizedBox(height: 12),

              if (_model == 'per_kg_min') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minKg,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min KG (optional)',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ratePerKg,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rate / KG',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ],

              if (_model == 'per_block') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _blockKg,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Block KG',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _blockPrice,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Block price',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ],

              if (_model == 'flat') ...[
                TextFormField(
                  controller: _flatPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Flat price',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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

              
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

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
