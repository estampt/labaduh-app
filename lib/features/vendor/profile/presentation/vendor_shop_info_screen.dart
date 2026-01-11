import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/vendor_profile_controller.dart';

class VendorShopInfoScreen extends ConsumerStatefulWidget {
  const VendorShopInfoScreen({super.key});

  @override
  ConsumerState<VendorShopInfoScreen> createState() => _VendorShopInfoScreenState();
}

class _VendorShopInfoScreenState extends ConsumerState<VendorShopInfoScreen> {
  late final TextEditingController shopName;
  late final TextEditingController address;
  late final TextEditingController hours;
  late final TextEditingController capacity;

  @override
  void initState() {
    super.initState();
    final p = ref.read(vendorProfileProvider);
    shopName = TextEditingController(text: p.shopName);
    address = TextEditingController(text: p.address);
    hours = TextEditingController(text: p.openHours);
    capacity = TextEditingController(text: p.capacityKgPerDay.toString());
  }

  @override
  void dispose() {
    shopName.dispose();
    address.dispose();
    hours.dispose();
    capacity.dispose();
    super.dispose();
  }

  void _save() {
    final ctrl = ref.read(vendorProfileProvider.notifier);
    ctrl.setShopName(shopName.text.trim());
    ctrl.setAddress(address.text.trim());
    ctrl.setHours(hours.text.trim());
    ctrl.setCapacity(int.tryParse(capacity.text.trim()) ?? 0);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Info')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: shopName, decoration: const InputDecoration(labelText: 'Shop name')),
            const SizedBox(height: 12),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextField(controller: hours, decoration: const InputDecoration(labelText: 'Operating hours')),
            const SizedBox(height: 12),
            TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity (KG per day)')),
            const SizedBox(height: 18),
            SizedBox(height: 52, child: FilledButton(onPressed: _save, child: const Text('Save'))),
          ],
        ),
      ),
    );
  }
}
