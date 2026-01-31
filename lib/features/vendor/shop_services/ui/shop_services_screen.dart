import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/shop_services_notifier.dart';
import '../data/shop_services_dtos.dart';
import 'shop_service_options_screen.dart';  
class ShopServicesScreen extends ConsumerStatefulWidget {
  const ShopServicesScreen({
    super.key,
    required this.vendorId,
    required this.shopId,
    required this.shopName,
  });

  final int vendorId;
  final int shopId;
  final String shopName;

  @override
  ConsumerState<ShopServicesScreen> createState() => _ShopServicesScreenState();
}

class _ShopServicesScreenState extends ConsumerState<ShopServicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopServicesProvider.notifier).load(
            vendorId: widget.vendorId,
            shopId: widget.shopId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncRows = ref.watch(shopServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shop Services'),
            Text(
              widget.shopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shopServicesProvider.notifier).refresh(),
          ),
        ],
      ),

      // Keep FAB styled like your attached screen
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        onPressed: () => _openAddServiceSheet(context, ref),
      ),


      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (rows) {
          final activeCount = rows.where((e) => e.isActive).length;

          return RefreshIndicator(
            onRefresh: () async => ref.read(shopServicesProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              children: [
                _SummaryCard(
                  shopName: widget.shopName,
                  total: rows.length,
                  active: activeCount,
                ),
                const SizedBox(height: 12),

                if (rows.isEmpty)
                  _EmptyState(
                    title: 'No services added',
                    subtitle: 'Add at least one service to start offering laundry services.',
                    onAdd: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Next step: Add Service CRUD')),
                      );
                    },
                  )
                else
                  ...rows.map((r) {
                    final serviceName = r.service?.name ?? 'Service #${r.serviceId}';
                    final leadingIcon = _serviceIconForName(serviceName);

                    final modelLabel = _modelLabel(r.pricingModel);
                    final modelIcon = _modelIcon(r.pricingModel);

                    final priceLabel = _priceSummary(r);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey('shop_service_${r.id}'),
                        direction: DismissDirection.endToStart,

                        // 🔒 CRITICAL: prevent route glitches
                        resizeDuration: null,

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
                          final ok = await _confirmDelete(context, serviceName);
                          if (ok != true) return false;

                          await ref.read(shopServicesProvider.notifier).delete(r.id);

                          // 🔒 Always return false
                          // Let Riverpod state change remove the item safely
                          return false;
                        },

                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                      _Chip(icon: Icons.scale_outlined, label: 'uom ${r.uom}'),
                                      _Chip(icon: Icons.payments_outlined, label: priceLabel),
                                      _Chip(
                                        icon: r.isActive
                                            ? Icons.check_circle_outline
                                            : Icons.pause_circle_outline,
                                        label: r.isActive ? 'Active' : 'Inactive',
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      await _openEditServiceSheet(context, ref, r);
                                    } else if (v == 'delete') {
                                      final ok = await _confirmDelete(context, serviceName);
                                      if (ok == true) {
                                        await ref
                                            .read(shopServicesProvider.notifier)
                                            .delete(r.id);
                                      }
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
                              ),

                              // Child section
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                child: Column(
                                  children: [
                                    Divider(
                                      height: 1,
                                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Service Add-ons',
                                            style: TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ShopServiceOptionsScreen(
                                                  vendorId: widget.vendorId,
                                                  shopId: widget.shopId,
                                                  shopService: r,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Manage'),
                                        ),

                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if ((r.options).isEmpty)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'No add-ons yet. Tap Manage to add.',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      )
                                    else
                                      Column(
                                        children: (List.of(r.options)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
                                            .map((o) {
                                          final optionName = o.serviceOption?.name ?? 'Option #${o.serviceOptionId}';
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    optionName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text('S\$${o.price}'),
                                                const SizedBox(width: 10),
                                                Icon(
                                                  o.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                  ],
                                ),
                              ),
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
      ),
    );
  }

  static String _priceSummary(ShopServiceDto r) {
    // For your shop_services schema (tiered_min_plus etc.)
    final model = r.pricingModel;
    String fmt(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

    if (model == 'tiered_min_plus') {
      return 'min ${fmt(r.minimum)} ${r.uom} • ${fmt(r.minPrice)} + ${fmt(r.pricePerUom)}/${r.uom}';
    }
    if (model == 'per_uom') {
      return '${fmt(r.pricePerUom)}/${r.uom}';
    }
    if (model == 'fixed') {
      return fmt(r.minPrice);
    }
    if (model == 'quote') {
      return 'Quote';
    }
    return model;
  }

  static String _modelLabel(String model) {
    switch (model) {
      case 'tiered_min_plus':
        return 'Tiered min+';
      case 'per_uom':
        return 'Per uom';
      case 'fixed':
        return 'Fixed';
      case 'quote':
        return 'Quote';
      default:
        return model;
    }
  }

  static IconData _modelIcon(String model) {
    switch (model) {
      case 'tiered_min_plus':
        return Icons.stacked_line_chart;
      case 'per_uom':
        return Icons.scale_outlined;
      case 'fixed':
        return Icons.receipt_long_outlined;
      case 'quote':
        return Icons.request_quote_outlined;
      default:
        return Icons.tune;
    }
  }

  static IconData _serviceIconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('dry')) return Icons.local_fire_department_outlined;
    if (n.contains('iron')) return Icons.checkroom;
    if (n.contains('curtain')) return Icons.window;
    if (n.contains('blanket') || n.contains('bedding') || n.contains('bed')) return Icons.bed;
    if (n.contains('carpet') || n.contains('rug')) return Icons.grid_view;
    if (n.contains('sanitize') || n.contains('disinfect')) return Icons.cleaning_services;
    return Icons.local_laundry_service;
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
                    title: const Text('How services work'),
                    content: const Text(
                      'Each shop has its own list of enabled services with pricing settings. '
                      'You can add add-ons per service.',
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
            const Icon(Icons.miscellaneous_services_outlined, size: 52),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add service'),
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


Future<bool?> _confirmDelete(BuildContext context, String name) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete service?'),
      content: Text('Delete "$name" from this shop?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}


Future<void> _openAddServiceSheet(BuildContext context, WidgetRef ref) async {
  final master = await ref.read(masterServicesProvider.future);
  final existing = ref.read(shopServicesProvider).valueOrNull ?? [];
  final usedIds = existing.map((e) => e.serviceId).toSet();

  final available = master.where((s) => !usedIds.contains(s.id)).toList();
  if (available.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All services already added for this shop.')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ShopServiceCrudSheet(
      title: 'Add Service',
      services: available,
      initial: null,
      onSave: (payload) async {
        await ref.read(shopServicesProvider.notifier).create(payload);
        if (context.mounted) Navigator.pop(context);
      },
    ),
  );
}

Future<void> _openEditServiceSheet(BuildContext context, WidgetRef ref, ShopServiceDto row) async {
  // lock service selection on edit; keep current service name
  final currentService = row.service ?? ServiceDto(id: row.serviceId, name: 'Service',  isActive: true);  

  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ShopServiceCrudSheet(
      title: 'Edit Service',
      services: [currentService],
      initial: row,
      isEdit: true,
      onSave: (payload) async {
        try {
          await ref.read(shopServicesProvider.notifier).update(row.id, payload);
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
      },

    ),
  );
}


class _ShopServiceCrudSheet extends StatefulWidget {
  const _ShopServiceCrudSheet({
    required this.title,
    required this.services,
    required this.initial,
    required this.onSave,
    this.isEdit = false,
  });

  final String title;
  final List<ServiceDto> services;
  final ShopServiceDto? initial;
  final bool isEdit;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  @override
  State<_ShopServiceCrudSheet> createState() => _ShopServiceCrudSheetState();
}

class _ShopServiceCrudSheetState extends State<_ShopServiceCrudSheet> {
  final _formKey = GlobalKey<FormState>();

  ServiceDto? _selected;

  final _pricingModelCtrl = TextEditingController();
  final _uomCtrl = TextEditingController();
  final _minimumCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _ppuCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.services.first;

    if (widget.initial == null) {
      // defaults for create
      _pricingModelCtrl.text = 'tiered_min_plus';
      _uomCtrl.text = (_selected?.baseUnit ?? 'kg');
      _currencyCtrl.text = 'SGD';
      _sortCtrl.text = '0';
      _active = true;
    } else {
      final r = widget.initial!;
      _pricingModelCtrl.text = r.pricingModel;
      _uomCtrl.text = r.uom;
      _minimumCtrl.text = r.minimum ?? '';
      _minPriceCtrl.text = r.minPrice ?? '';
      _ppuCtrl.text = r.pricePerUom ?? '';
      _currencyCtrl.text = r.currency;
      _sortCtrl.text = r.sortOrder.toString();
      _active = r.isActive;
    }
  }

  @override
  void dispose() {
    _pricingModelCtrl.dispose();
    _uomCtrl.dispose();
    _minimumCtrl.dispose();
    _minPriceCtrl.dispose();
    _ppuCtrl.dispose();
    _currencyCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: _selected?.id,
                  items: widget.services
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: widget.isEdit
                      ? null
                      : (id) {
                          final s = widget.services.firstWhere((x) => x.id == id);
                          setState(() {
                            _selected = s;
                            // sensible defaults
                            if (_uomCtrl.text.trim().isEmpty) _uomCtrl.text = s.baseUnit ?? 'kg';
                          });
                        },
                  decoration: const InputDecoration(labelText: 'Service'),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _pricingModelCtrl,
                  decoration: const InputDecoration(labelText: 'pricing_model'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _uomCtrl,
                  decoration: const InputDecoration(labelText: 'uom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minimumCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'minimum'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'min_price'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _ppuCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'price_per_uom'),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currencyCtrl,
                        decoration: const InputDecoration(labelText: 'currency'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sortCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'sort_order'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final payload = <String, dynamic>{
                        // ✅ Always send service_id (backend may require it even for edit)
                        'service_id': widget.initial?.serviceId ?? _selected!.id,

                        'pricing_model': _pricingModelCtrl.text.trim(),
                        'uom': _uomCtrl.text.trim(),

                        'minimum': _minimumCtrl.text.trim().isEmpty
                            ? null
                            : num.tryParse(_minimumCtrl.text.trim()),

                        'min_price': _minPriceCtrl.text.trim().isEmpty
                            ? null
                            : num.tryParse(_minPriceCtrl.text.trim()),

                        'price_per_uom': _ppuCtrl.text.trim().isEmpty
                            ? null
                            : num.tryParse(_ppuCtrl.text.trim()),

                        'currency': _currencyCtrl.text.trim().isEmpty
                            ? 'SGD'
                            : _currencyCtrl.text.trim(),

                        'sort_order': int.tryParse(_sortCtrl.text.trim()) ?? 0,
                        'is_active': _active,
                      }..removeWhere((k, v) => v == null);


                      await widget.onSave(payload);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
