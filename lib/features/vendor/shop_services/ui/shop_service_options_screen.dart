import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop_services_dtos.dart';
import '../data/shop_service_options_dtos.dart';
import '../state/shop_service_options_notifier.dart';

class ShopServiceOptionsScreen extends ConsumerStatefulWidget {
  const ShopServiceOptionsScreen({
    super.key,
    required this.vendorId,
    required this.shopId,
    required this.shopService,
  });

  final int vendorId;
  final int shopId;
  final ShopServiceDto shopService;

  @override
  ConsumerState<ShopServiceOptionsScreen> createState() => _ShopServiceOptionsScreenState();
}

class _ShopServiceOptionsScreenState extends ConsumerState<ShopServiceOptionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopServiceOptionsProvider.notifier).load(
            vendorId: widget.vendorId,
            shopId: widget.shopId,
            shopServiceId: widget.shopService.id,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncRows = ref.watch(shopServiceOptionsProvider);
    final serviceName = widget.shopService.service?.name ?? 'Service';

    return Scaffold(
      appBar: AppBar(
        title: Text('$serviceName • Add-ons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shopServiceOptionsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add add-on'),
        onPressed: () async {
          try {
            await _openAddOptionSheet(context, ref);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Add-on error: $e')),
            );
          }
        },
      ),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No add-ons yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = rows[i];
              final name = r.serviceOption?.name ?? 'Option #${r.serviceOptionId}';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                ),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('Price ${r.price} • sort ${r.sortOrder} • ${r.isActive ? "Active" : "Inactive"}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _openEditOptionSheet(context, ref, r);
                      } else if (v == 'delete') {
                        final ok = await _confirmDelete(context, name);
                        if (ok == true) {
                          await ref.read(shopServiceOptionsProvider.notifier).delete(r.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAddOptionSheet(BuildContext context, WidgetRef ref) async {
    final master = await ref.read(masterServiceOptionsProvider.future);
    final existing = ref.read(shopServiceOptionsProvider).valueOrNull ?? [];
    final usedIds = existing.map((e) => e.serviceOptionId).toSet();

    final available = master.where((o) => !usedIds.contains(o.id)).toList();
    if (available.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All add-ons already added.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OptionCrudSheet(
        title: 'Add add-on',
        options: available,
        initial: null,
        onSave: (payload) async {
          await ref.read(shopServiceOptionsProvider.notifier).create(payload);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _openEditOptionSheet(
      BuildContext context, WidgetRef ref, ShopServiceOptionDto row) async {
    // serviceOptionId is fixed on edit
    final currentMaster = row.serviceOption ??
        ServiceOptionDto(
          id: row.serviceOptionId,
          name: 'Option',
          kind: 'addon',
          isActive: true,
          sortOrder: 0,
        );

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OptionCrudSheet(
        title: 'Edit add-on',
        options: [currentMaster],
        initial: row,
        isEdit: true,
        onSave: (payload) async {
          await ref.read(shopServiceOptionsProvider.notifier).update(row.id, payload);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete add-on?'),
        content: Text('Delete "$name"?'),
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
}

class _OptionCrudSheet extends StatefulWidget {
  const _OptionCrudSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.onSave,
    this.isEdit = false,
  });

  final String title;
  final List<ServiceOptionDto> options;
  final ShopServiceOptionDto? initial;
  final bool isEdit;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  @override
  State<_OptionCrudSheet> createState() => _OptionCrudSheetState();
}

class _OptionCrudSheetState extends State<_OptionCrudSheet> {
  final _formKey = GlobalKey<FormState>();

  ServiceOptionDto? _selected;
  final _priceCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.options.first;

    if (widget.initial == null) {
      // default price from master option
      _priceCtrl.text = (_selected?.price ?? '').toString();
      _sortCtrl.text = '0';
      _active = true;
    } else {
      final r = widget.initial!;
      _priceCtrl.text = r.price;
      _sortCtrl.text = r.sortOrder.toString();
      _active = r.isActive;
    }

    if (_priceCtrl.text.trim().isEmpty) _priceCtrl.text = '0';
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
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
                  items: widget.options
                      .map((o) => DropdownMenuItem(value: o.id, child: Text(o.name)))
                      .toList(),
                  onChanged: widget.isEdit
                      ? null
                      : (id) {
                          final o = widget.options.firstWhere((x) => x.id == id);
                          setState(() {
                            _selected = o;
                            // default price from master
                            _priceCtrl.text = (o.price ?? '0').toString();
                          });
                        },
                  decoration: const InputDecoration(labelText: 'Service option'),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (flat)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sort order'),
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
                        // ✅ always include service_option_id (backend may require it)
                        'service_option_id': widget.initial?.serviceOptionId ?? _selected!.id,
                        'price': num.tryParse(_priceCtrl.text.trim()) ?? 0,
                        'sort_order': int.tryParse(_sortCtrl.text.trim()) ?? 0,
                        'is_active': _active,
                      };

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
