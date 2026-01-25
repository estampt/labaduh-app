import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/vendor_shop_option_prices_providers.dart';
import '../data/vendor_shop_option_prices_repository.dart';

class VendorShopOptionPricesScreen extends ConsumerWidget {
  const VendorShopOptionPricesScreen({
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
    final state = ref.watch(vendorShopOptionPricesProvider((vendorId: vendorId, shopId: shopId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Options & Add-ons'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString(), onRetry: () {
          ref.invalidate(vendorShopOptionPricesProvider((vendorId: vendorId, shopId: shopId)));
        }),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              onAdd: () => _openAddSheet(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vendorShopOptionPricesProvider((vendorId: vendorId, shopId: shopId)));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final row = items[i];
                final title = row.serviceOption?.name ?? 'Option #${row.serviceOptionId}';
                final kind = (row.serviceOption?.kind ?? '').toLowerCase();
                final isAddon = kind == 'addon';
                final icon = isAddon ? Icons.add_circle_outline : Icons.tune;

                final priceLabel = _priceLabel(row.price, row.priceType);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            _ActiveChip(active: row.isActive),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  _openEditSheet(context, ref, row);
                                  return;
                                }
                                if (v == 'delete') {
                                  await _confirmDelete(context, ref, row);
                                  return;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                priceLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TypeChip(type: row.priceType),
                          ],
                        ),
                        if ((row.serviceOption?.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            row.serviceOption!.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Option'),
      ),
    );
  }

  void _openAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OptionPriceSheet(
        vendorId: vendorId,
        shopId: shopId,
        mode: _SheetMode.add,
      ),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, VendorServiceOptionPriceLite row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OptionPriceSheet(
        vendorId: vendorId,
        shopId: shopId,
        mode: _SheetMode.edit,
        editRow: row,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, VendorServiceOptionPriceLite row) async {
    final title = row.serviceOption?.name ?? 'Option #${row.serviceOptionId}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete option price?'),
        content: Text('This will remove pricing for:\n\n$title'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // ✅ delete + close properly
    try {
      await ref.read(vendorShopOptionPricesActionsProvider).delete(
            vendorId: vendorId,
            shopId: shopId,
            optionPriceId: row.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  static String _priceLabel(num? price, String? priceType) {
    final p = (price == null) ? 'Use default' : price.toStringAsFixed(2);
    final t = (priceType ?? '').trim().isEmpty ? 'default type' : priceType!;
    return 'Price: $p • Type: $t';
  }
}

enum _SheetMode { add, edit }

class _OptionPriceSheet extends ConsumerStatefulWidget {
  const _OptionPriceSheet({
    required this.vendorId,
    required this.shopId,
    required this.mode,
    this.editRow,
  });

  final int vendorId;
  final int shopId;
  final _SheetMode mode;
  final VendorServiceOptionPriceLite? editRow;

  @override
  ConsumerState<_OptionPriceSheet> createState() => _OptionPriceSheetState();
}

class _OptionPriceSheetState extends ConsumerState<_OptionPriceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();

  ServiceOptionLite? _selectedOption;
  String? _priceType; // fixed|per_kg|per_item
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == _SheetMode.edit && widget.editRow != null) {
      _isActive = widget.editRow!.isActive;
      _priceType = widget.editRow!.priceType;
      if (widget.editRow!.price != null) _priceCtrl.text = widget.editRow!.price!.toString();
      _selectedOption = widget.editRow!.serviceOption;
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(serviceOptionsProvider);
    final existingAsync =
        ref.watch(vendorShopOptionPricesProvider((vendorId: widget.vendorId, shopId: widget.shopId)));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.mode == _SheetMode.add ? Icons.add_circle_outline : Icons.edit_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.mode == _SheetMode.add ? 'Add Option / Add-on' : 'Edit Option Price',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Picker
                  optionsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Text('Failed to load options: $e'),
                    data: (allOptions) {
                      return existingAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => _buildOptionDropdown(context, allOptions, const []),
                        data: (existingRows) {
                          // hide already added options (only for ADD mode)
                          final usedIds = existingRows.map((e) => e.serviceOptionId).toSet();
                          final filtered = (widget.mode == _SheetMode.add)
                              ? allOptions.where((o) => !usedIds.contains(o.id)).toList()
                              : allOptions;

                          return _buildOptionDropdown(context, filtered, existingRows);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Price
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Override Price (optional)',
                      hintText: 'Leave empty to use default from service_options',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Price type override
                  DropdownButtonFormField<String>(
                    value: _priceType,
                    items: const [
                      DropdownMenuItem(value: 'fixed', child: Text('fixed')),
                      DropdownMenuItem(value: 'per_kg', child: Text('per_kg')),
                      DropdownMenuItem(value: 'per_item', child: Text('per_item')),
                    ],
                    onChanged: (v) => setState(() => _priceType = v),
                    decoration: const InputDecoration(
                      labelText: 'Override Price Type (optional)',
                      prefixIcon: Icon(Icons.straighten_outlined),
                      hintText: 'Leave empty to use default price_type',
                    ),
                  ),

                  const SizedBox(height: 10),

                  SwitchListTile.adaptive(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: const Text('If off, this option won’t be selectable by customers.'),
                    secondary: const Icon(Icons.toggle_on_outlined),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: Icon(_saving ? Icons.hourglass_top : Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save'),
                      onPressed: _saving ? null : () => _save(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionDropdown(
    BuildContext context,
    List<ServiceOptionLite> options,
    List<VendorServiceOptionPriceLite> existingRows,
  ) {
    final isEdit = widget.mode == _SheetMode.edit;

    // Ensure selection exists in edit mode even if options list is filtered
    final merged = [...options];
    if (isEdit && _selectedOption != null && merged.every((o) => o.id != _selectedOption!.id)) {
      merged.insert(0, _selectedOption!);
    }

    return DropdownButtonFormField<int>(
      value: _selectedOption?.id,
      items: merged.map((o) {
        final kind = (o.kind ?? '').toLowerCase();
        final icon = kind == 'addon' ? Icons.add_circle_outline : Icons.tune;
        return DropdownMenuItem(
          value: o.id,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(o.name, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              if ((o.kind ?? '').isNotEmpty) _MiniChip(text: o.kind!),
            ],
          ),
        );
      }).toList(),
      onChanged: isEdit
          ? null
          : (id) {
              final opt = merged.firstWhere((x) => x.id == id);
              setState(() {
                _selectedOption = opt;
                // prefill helpful defaults for vendor:
                _priceType ??= opt.priceType;
                if (_priceCtrl.text.trim().isEmpty && opt.price != null) {
                  _priceCtrl.text = opt.price!.toString();
                }
              });
            },
      validator: (v) {
        if (isEdit) return null;
        if (v == null) return 'Please select an option/add-on';
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Select Option / Add-on',
        prefixIcon: Icon(Icons.list_alt_outlined),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // for edit mode, service_option_id cannot change
    final serviceOptionId = widget.mode == _SheetMode.edit
        ? widget.editRow!.serviceOptionId
        : _selectedOption!.id;

    final priceText = _priceCtrl.text.trim();
    final num? price = priceText.isEmpty ? null : num.tryParse(priceText);

    setState(() => _saving = true);
    try {
      final actions = ref.read(vendorShopOptionPricesActionsProvider);

      if (widget.mode == _SheetMode.add) {
        await actions.upsert(
          vendorId: widget.vendorId,
          shopId: widget.shopId,
          serviceOptionId: serviceOptionId,
          price: price,
          priceType: _priceType,
          isActive: _isActive,
        );
      } else {
        await actions.update(
          vendorId: widget.vendorId,
          shopId: widget.shopId,
          optionPriceId: widget.editRow!.id,
          price: price,
          priceType: _priceType,
          isActive: _isActive,
        );
      }

      if (mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(active ? Icons.check_circle_outline : Icons.block_outlined, size: 18),
      label: Text(active ? 'ACTIVE' : 'INACTIVE'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String? type;

  @override
  Widget build(BuildContext context) {
    final t = (type ?? '').isEmpty ? 'default' : type!;
    return Chip(
      label: Text(t),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.extension_outlined, size: 56),
            const SizedBox(height: 10),
            Text('No options/add-ons yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Tap “Add Option” to set pricing overrides for add-ons and options in this shop.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 10),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
