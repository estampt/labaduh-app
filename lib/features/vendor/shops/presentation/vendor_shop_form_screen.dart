import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../domain/vendor_shop.dart';
import '../state/vendor_shops_providers.dart'; 

// ✅ adjust this import to your final path
import '../../../../shared/widgets/osm_location_picker.dart';

class VendorShopFormScreen extends ConsumerStatefulWidget {
  const VendorShopFormScreen({super.key, this.editShop});
  final VendorShop? editShop;

  @override
  ConsumerState<VendorShopFormScreen> createState() => _VendorShopFormScreenState();
}

class _VendorShopFormScreenState extends ConsumerState<VendorShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _maxOrders;
  late final TextEditingController _maxKg;

  double? _lat;
  double? _lng;
  bool _isActive = true;
  bool _saving = false;
  
  // ✅ Address + Location
  String? addressLine1;
  LatLng? pickedLatLng;

  @override
  void initState() {
    super.initState();
    final s = widget.editShop;

    _name = TextEditingController(text: s?.name ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _address1 = TextEditingController(text: s?.addressLine1 ?? '');
    _address2 = TextEditingController(text: s?.addressLine2 ?? '');
    _maxOrders = TextEditingController(text: s?.defaultMaxOrdersPerDay?.toString() ?? '50');
    _maxKg = TextEditingController(text: s?.defaultMaxKgPerDay?.toString() ?? '300.00');

    _lat = s?.latitude;
    _lng = s?.longitude;
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address1.dispose();
    _address2.dispose();
    _maxOrders.dispose();
    _maxKg.dispose();
    super.dispose();
  }

  
  Future<void> _pickLocation() async {
    final res = await OSMMapLocationPicker.open(
      context,
      initialCenter: pickedLatLng,
      initialLabel: addressLine1,
    );
    if (!mounted || res == null) return;

    setState(() {
      pickedLatLng = res.latLng;
      addressLine1 = res.addressLabel; //'${res.latLng.latitude.toStringAsFixed(6)}, ${res.latLng.longitude.toStringAsFixed(6)}';
      _address1.text = addressLine1!;
    });
  } 
  

  Map<String, dynamic> _buildPayload() {
    return {
      "name": _name.text.trim(),
      "phone": _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      "address_line1": _address1.text.trim(),
      "address_line2": _address2.text.trim().isEmpty ? null : _address2.text.trim(),
      "postal_code": null,
      "country_id": null,
      "state_province_id": null,
      "city_id": null,
      "latitude": _lat,
      "longitude": _lng,
      "default_max_orders_per_day": int.tryParse(_maxOrders.text.trim()) ?? 50,
      "default_max_kg_per_day": _maxKg.text.trim(),
      "is_active": _isActive,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editShop != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Shop' : 'Create Shop')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Shop name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 10),

            // ✅ Address Line 1: read-only + opens popup picker
            TextFormField(
              controller: _address1,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Address line 1',
                hintText: 'Tap to select location',
                suffixIcon: Icon(Icons.map_outlined),
              ),
              onTap: _pickLocation,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Select a location'
                  : null,
            ),

            const SizedBox(height: 10),
            TextFormField(
              controller: _address2,
              decoration: const InputDecoration(labelText: 'Address line 2 (optional)'),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxOrders,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max orders/day'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _maxKg,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max kg/day'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Active'),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_lat == null || _lng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a location')),
                          );
                          return;
                        }

                        setState(() => _saving = true);
                        try {
                          final payload = _buildPayload();
                          if (isEdit) {
                            await ref
                                .read(vendorShopsActionsProvider)
                                .update(widget.editShop!.id, payload);
                          } else {
                            await ref.read(vendorShopsActionsProvider).create(payload);
                          }
                          ref.invalidate(vendorShopsProvider);
                          if (mounted) Navigator.pop(context);
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
