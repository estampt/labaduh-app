import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import 'admin_addons_screen.dart'; // for AdminAddon model

class AdminAddonFormDialog extends ConsumerStatefulWidget {
  const AdminAddonFormDialog({super.key, this.existing});

  final AdminAddon? existing;

  @override
  ConsumerState<AdminAddonFormDialog> createState() => _AdminAddonFormDialogState();
}

class _AdminAddonFormDialogState extends ConsumerState<AdminAddonFormDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController groupCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController sortCtrl;

  String priceType = 'fixed';
  bool isActive = true;
  bool isRequired = false;
  bool isMultiSelect = false;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    nameCtrl = TextEditingController(text: e?.name ?? '');
    groupCtrl = TextEditingController(text: e?.groupKey ?? '');
    descCtrl = TextEditingController(text: e?.description ?? '');
    priceCtrl = TextEditingController(text: (e?.price ?? 0).toStringAsFixed(2));
    sortCtrl = TextEditingController(text: (e?.sortOrder ?? 0).toString());

    priceType = e?.priceType ?? 'fixed';
    isActive = e?.isActive ?? true;
    isRequired = e?.isRequired ?? false;
    isMultiSelect = e?.isMultiSelect ?? false;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    groupCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    sortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Add-on' : 'Create Add-on'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: groupCtrl,
              decoration: const InputDecoration(labelText: 'Group Key (fragrance, speed, treatment)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            TextField(
              controller: sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort Order'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
              title: const Text('Active'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isRequired,
              onChanged: (v) => setState(() => isRequired = v),
              title: const Text('Required'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isMultiSelect,
              onChanged: (v) => setState(() => isMultiSelect = v),
              title: const Text('Multi-select'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : () => _save(context),
          child: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;

    final payload = <String, dynamic>{
      'name': name,
      'group_key': groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim(),
      'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      'price': price,
      'price_type': priceType,
      'is_active': isActive,
      'is_required': isRequired,
      'is_multi_select': isMultiSelect,
      'sort_order': sort,
    };

    setState(() => saving = true);

    try {
      final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed

      if (widget.existing == null) {
        await dio.post('/api/v1/admin/addons', data: payload);
      } else {
        await dio.patch('/api/v1/admin/addons/${widget.existing!.id}', data: payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
