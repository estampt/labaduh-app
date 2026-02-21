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
  ConsumerState<ShopServiceOptionsScreen> createState() =>
      _ShopServiceOptionsScreenState();
}

class _ShopServiceOptionsScreenState
    extends ConsumerState<ShopServiceOptionsScreen> {
  static const _tag = '🧩[ShopServiceOptionsScreen]';

  @override
  void initState() {
    super.initState();

    debugPrint('$_tag initState');
    debugPrint(
      '$_tag ids vendorId=${widget.vendorId} shopId=${widget.shopId} shopServiceId=${widget.shopService.id}',
    );

    // ✅ Provider listener: logs transitions + errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<List<ShopServiceOptionDto>>>(
        shopServiceOptionsProvider,
        (prev, next) {
          debugPrint('$_tag provider change -> ${next.runtimeType}');
          next.when(
            loading: () => debugPrint('$_tag provider=loading'),
            error: (e, st) {
              debugPrint('$_tag provider=error: $e');
              debugPrint('$_tag stack:\n$st');
            },
            data: (rows) {
              debugPrint('$_tag provider=data rows=${rows.length}');
              if (rows.isNotEmpty) {
                final r0 = rows.first;
                debugPrint(
                  '$_tag firstRow id=${r0.id} shopServiceId=${r0.shopServiceId} '
                  'serviceOptionId=${r0.serviceOptionId} price=${r0.price} '
                  'active=${r0.isActive} sort=${r0.sortOrder} '
                  'name=${r0.serviceOption?.name}',
                );
              }
            },
          );
        },
      );
    });

    // ✅ initial load
    Future.microtask(() async {
      debugPrint('$_tag calling load()...');
      try {
        await ref.read(shopServiceOptionsProvider.notifier).load(
              vendorId: widget.vendorId,
              shopId: widget.shopId,
              shopServiceId: widget.shopService.id,
            );
        debugPrint('$_tag load() done');
      } catch (e, st) {
        debugPrint('$_tag load() threw: $e');
        debugPrint('$_tag stack:\n$st');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncRows = ref.watch(shopServiceOptionsProvider);
    final serviceName = widget.shopService.service?.name ?? 'Service';

    debugPrint('$_tag build state=${asyncRows.runtimeType}');

    return Scaffold(
      appBar: AppBar(
        title: Text('$serviceName • Add-ons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              debugPrint('$_tag refresh tapped');
              try {
                await ref.read(shopServiceOptionsProvider.notifier).refresh();
                debugPrint('$_tag refresh() done');
              } catch (e, st) {
                debugPrint('$_tag refresh() threw: $e');
                debugPrint('$_tag stack:\n$st');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refresh failed: $e')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add add-on'),
        onPressed: () async {
          debugPrint('$_tag FAB tapped -> open add sheet');
          try {
            await _openAddOptionSheet(context, ref);
            debugPrint('$_tag add sheet closed');
          } catch (e, st) {
            debugPrint('$_tag _openAddOptionSheet threw: $e');
            debugPrint('$_tag stack:\n$st');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Add-on error: $e')),
            );
          }
        },
      ),
      body: asyncRows.when(
        loading: () {
          debugPrint('$_tag UI loading');
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, st) {
          debugPrint('$_tag UI error: $e');
          debugPrint('$_tag UI stack:\n$st');
          return Center(child: Text('Error: $e'));
        },
        data: (rows) {
          debugPrint('$_tag UI data rows=${rows.length}');

          if (rows.isEmpty) {
            return const Center(child: Text('No add-ons yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = rows[i];

              debugPrint(
                '$_tag renderRow[$i] id=${r.id} shopServiceId=${r.shopServiceId} '
                'serviceOptionId=${r.serviceOptionId} price=${r.price} '
                'active=${r.isActive} sort=${r.sortOrder} name=${r.serviceOption?.name}',
              );

              final name =
                  r.serviceOption?.name ?? 'Option #${r.serviceOptionId}';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    'Price ${r.price} • sort ${r.sortOrder} • ${r.isActive ? "Active" : "Inactive"}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      debugPrint('$_tag menu="$v" rowId=${r.id}');
                      if (v == 'edit') {
                        try {
                          await _openEditOptionSheet(context, ref, r);
                          debugPrint('$_tag edit sheet closed rowId=${r.id}');
                        } catch (e, st) {
                          debugPrint('$_tag _openEditOptionSheet threw: $e');
                          debugPrint('$_tag stack:\n$st');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Edit failed: $e')),
                          );
                        }
                      } else if (v == 'delete') {
                        final ok = await _confirmDelete(context, name);
                        debugPrint('$_tag delete confirm=$ok rowId=${r.id}');
                        if (ok == true) {
                          try {
                            debugPrint('$_tag calling delete(id=${r.id})');
                            await ref
                                .read(shopServiceOptionsProvider.notifier)
                                .delete(r.id);
                            debugPrint('$_tag delete() done id=${r.id}');
                          } catch (e, st) {
                            debugPrint('$_tag delete() threw: $e');
                            debugPrint('$_tag stack:\n$st');
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Delete failed: $e')),
                            );
                          }
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
    debugPrint('$_tag _openAddOptionSheet start');

    final master = await ref.read(masterServiceOptionsProvider.future);
    debugPrint('$_tag masterServiceOptions count=${master.length}');

    final existing = ref.read(shopServiceOptionsProvider).valueOrNull ?? [];
    debugPrint('$_tag existing options count=${existing.length}');

    // Use serviceOptionId if available, else fallback to id (safe)
    final usedIds = existing
        .map((e) => e.serviceOptionId != 0 ? e.serviceOptionId : e.id)
        .toSet();

    final available = master.where((o) => !usedIds.contains(o.id)).toList();
    debugPrint('$_tag available master options=${available.length}');

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
          // ✅ log payload BEFORE sending
          debugPrint('$_tag CREATE payload=$payload');

          try {
            await ref.read(shopServiceOptionsProvider.notifier).create(payload);

            if (!context.mounted) return;
            Navigator.pop(context); // close sheet only on success
          } catch (e, st) {
            debugPrint('$_tag create() threw: $e');
            debugPrint('$_tag stack:\n$st');

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Create failed: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _openEditOptionSheet(
    BuildContext context,
    WidgetRef ref,
    ShopServiceOptionDto row,
  ) async {
    debugPrint('$_tag _openEditOptionSheet rowId=${row.id}');

    // ✅ IMPORTANT: row.name/row.description do not exist on your DTO
    // Use embedded serviceOption (if present) or minimal fallback
    final currentMaster = row.serviceOption ??
        ServiceOptionDto(
          id: row.serviceOptionId,
          name: 'Option #',
          description: '',
          kind: 'addon',
          price: row.price,
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
          debugPrint('$_tag UPDATE rowId=${row.id} payload=$payload');

          try {
            await ref
                .read(shopServiceOptionsProvider.notifier)
                .update(row.id, payload);

            if (context.mounted) Navigator.pop(context);
          } catch (e, st) {
            debugPrint('$_tag update() threw: $e');
            debugPrint('$_tag stack:\n$st');

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $e')),
            );
          }
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
  static const _tag = '🧾[_OptionCrudSheet]';

  final _formKey = GlobalKey<FormState>();

  ServiceOptionDto? _selected;
  final _priceCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  bool _active = true;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.options.first;

    debugPrint('$_tag initState isEdit=${widget.isEdit} initial=${widget.initial != null}');

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
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: _selected?.id,
                  items: widget.options
                      .map((o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(o.name),
                          ))
                      .toList(),
                  onChanged: widget.isEdit
                      ? null
                      : (id) {
                          final o = widget.options.firstWhere((x) => x.id == id);
                          setState(() {
                            _selected = o;
                            _priceCtrl.text = (o.price ?? '0').toString();
                          });
                          debugPrint('$_tag selected optionId=${o.id} name=${o.name} defaultPrice=${o.price}');
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
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => _submitting = true);

                            try {
                              final payload = <String, dynamic>{
                                // ✅ always include service_option_id
                                'service_option_id':
                                    widget.initial?.serviceOptionId ?? _selected!.id,
                                'price': num.tryParse(_priceCtrl.text.trim()) ?? 0,
                                'sort_order': int.tryParse(_sortCtrl.text.trim()) ?? 0,
                                'is_active': _active,
                              };

                              debugPrint('$_tag submit payload=$payload');

                              await widget.onSave(payload);
                            } catch (e, st) {
                              debugPrint('$_tag submit threw: $e');
                              debugPrint('$_tag stack:\n$st');

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Save failed: $e')),
                              );
                            } finally {
                              if (!mounted) return;
                              setState(() => _submitting = false);
                            }
                          },
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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