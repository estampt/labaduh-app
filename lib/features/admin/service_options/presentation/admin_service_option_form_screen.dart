import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/service_option.dart';
import 'providers/service_options_providers.dart';

class AdminServiceOptionFormScreen extends ConsumerStatefulWidget {
  final ServiceOption? existing;
  const AdminServiceOptionFormScreen({super.key, this.existing});

  @override
  ConsumerState<AdminServiceOptionFormScreen> createState() => _AdminServiceOptionFormScreenState();
}

class _AdminServiceOptionFormScreenState extends ConsumerState<AdminServiceOptionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _groupKey;
  late final TextEditingController _price;
  late final TextEditingController _sortOrder;

  ServiceOptionKind _kind = ServiceOptionKind.option;
  ServiceOptionPriceType _priceType = ServiceOptionPriceType.fixed;

  bool _isRequired = false;
  bool _isMultiSelect = false;
  bool _isActive = true;

  bool? _isDefaultSelected; // optional

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _groupKey = TextEditingController(text: e?.groupKey ?? '');
    _price = TextEditingController(text: e?.price ?? '0.00');
    _sortOrder = TextEditingController(text: (e?.sortOrder ?? 0).toString());

    if (e != null) {
      _kind = e.kind;
      _priceType = e.priceType;
      _isRequired = e.isRequired;
      _isMultiSelect = e.isMultiSelect;
      _isActive = e.isActive;
      _isDefaultSelected = e.isDefaultSelected; // can be null
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _groupKey.dispose();
    _price.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Service Option' : 'Add Service Option')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<ServiceOptionKind>(
                value: _kind,
                decoration: const InputDecoration(labelText: 'Kind'),
                items: const [
                  DropdownMenuItem(value: ServiceOptionKind.option, child: Text('Option')),
                  DropdownMenuItem(value: ServiceOptionKind.addon, child: Text('Add-on')),
                ],
                onChanged: (v) => setState(() => _kind = v ?? ServiceOptionKind.option),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _groupKey,
                decoration: const InputDecoration(labelText: 'Group Key (optional)'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<ServiceOptionPriceType>(
                value: _priceType,
                decoration: const InputDecoration(labelText: 'Price Type'),
                items: const [
                  DropdownMenuItem(value: ServiceOptionPriceType.fixed, child: Text('Fixed')),
                  DropdownMenuItem(value: ServiceOptionPriceType.perKg, child: Text('Per KG')),
                  DropdownMenuItem(value: ServiceOptionPriceType.perItem, child: Text('Per Item')),
                ],
                onChanged: (v) => setState(() => _priceType = v ?? ServiceOptionPriceType.fixed),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _sortOrder,
                decoration: const InputDecoration(labelText: 'Sort Order'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _isRequired,
                onChanged: (v) => setState(() => _isRequired = v),
                title: const Text('Required'),
              ),
              SwitchListTile(
                value: _isMultiSelect,
                onChanged: (v) => setState(() => _isMultiSelect = v),
                title: const Text('Multi Select'),
              ),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Active'),
              ),

              // optional: only show if you want to manage it
              if (_isDefaultSelected != null)
                SwitchListTile(
                  value: _isDefaultSelected ?? false,
                  onChanged: (v) => setState(() => _isDefaultSelected = v),
                  title: const Text('Default Selected'),
                ),

              const SizedBox(height: 18),

              FilledButton(
                onPressed: _saving ? null : () => _save(context),
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),

              if (isEdit) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _saving ? null : () => _delete(context),
                  child: const Text('Delete'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final api = ref.read(adminServiceOptionsApiProvider);

      final opt = (widget.existing ??
              ServiceOption(
                id: 0,
                name: '',
                description: null,
                kind: ServiceOptionKind.option,
                groupKey: null,
                price: '0.00',
                priceType: ServiceOptionPriceType.fixed,
                isRequired: false,
                isMultiSelect: false,
                isDefaultSelected: null,
                sortOrder: 0,
                isActive: true,
              ))
          .copyWith(
        name: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        kind: _kind,
        groupKey: _groupKey.text.trim().isEmpty ? null : _groupKey.text.trim(),
        price: _price.text.trim(),
        priceType: _priceType,
        isRequired: _isRequired,
        isMultiSelect: _isMultiSelect,
        isDefaultSelected: _isDefaultSelected,
        sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
        isActive: _isActive,
      );

      if (widget.existing == null) {
        await api.create(opt);
      } else {
        await api.update(opt.id, opt.toPayload());
      }

      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(BuildContext context) async {
    setState(() => _saving = true);
    try {
      final api = ref.read(adminServiceOptionsApiProvider);
      await api.delete(widget.existing!.id);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
