import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/address.dart';
import '../state/addresses_controller.dart';

class AddressEditScreen extends ConsumerStatefulWidget {
  const AddressEditScreen({super.key, this.address});
  final Object? address;

  @override
  ConsumerState<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends ConsumerState<AddressEditScreen> {
  String? id;

  late final TextEditingController label;
  late final TextEditingController line1;
  late final TextEditingController line2;
  late final TextEditingController city;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final a = widget.address is Address ? widget.address as Address : null;
    id = a?.id;

    label = TextEditingController(text: a?.label ?? '');
    line1 = TextEditingController(text: a?.line1 ?? '');
    line2 = TextEditingController(text: a?.line2 ?? '');
    city = TextEditingController(text: a?.city ?? '');
    notes = TextEditingController(text: a?.notes ?? '');
  }

  @override
  void dispose() {
    label.dispose();
    line1.dispose();
    line2.dispose();
    city.dispose();
    notes.dispose();
    super.dispose();
  }

  void _save() {
    final newAddress = Address(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: label.text.trim().isEmpty ? 'Address' : label.text.trim(),
      line1: line1.text.trim(),
      line2: line2.text.trim().isEmpty ? null : line2.text.trim(),
      city: city.text.trim(),
      notes: notes.text.trim(),
    );

    ref.read(addressesProvider.notifier).upsert(newAddress);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = id != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Address' : 'Add Address')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Label (e.g., Home, Office)')),
            const SizedBox(height: 12),
            TextField(controller: line1, decoration: const InputDecoration(labelText: 'Address line 1')),
            const SizedBox(height: 12),
            TextField(controller: line2, decoration: const InputDecoration(labelText: 'Address line 2 (optional)')),
            const SizedBox(height: 12),
            TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: 12),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 18),
            SizedBox(height: 52, child: FilledButton(onPressed: _save, child: const Text('Save'))),
          ],
        ),
      ),
    );
  }
}
