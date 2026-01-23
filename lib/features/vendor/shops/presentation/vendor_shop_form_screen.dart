import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  // ✅ Photo (single)
  final ImagePicker _picker = ImagePicker();
  File? _pickedPhoto;

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

    // keep these for picker label/center
    addressLine1 = s?.addressLine1;
    if (_lat != null && _lng != null) {
      pickedLatLng = LatLng(_lat!, _lng!);
    }
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

      // ✅ DON'T use labelText; put the address into the controller.
      // If your picker returns exactAddress, use it; otherwise use addressLabel.
      final addr = (res.exactAddress as String?)?.trim();
      addressLine1 = (addr != null && addr.isNotEmpty) ? addr : res.addressLabel;

      _address1.text = addressLine1 ?? '';
      _lat = pickedLatLng!.latitude;
      _lng = pickedLatLng!.longitude;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 85);
    if (!mounted || x == null) return;
    setState(() => _pickedPhoto = File(x.path));
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

  Widget _photoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shop Photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            if (_pickedPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _pickedPhoto!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(),
                ),
                child: const Center(child: Text('No new photo selected')),
              ),

            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                const Spacer(),
                if (_pickedPhoto != null)
                  TextButton(
                    onPressed: () => setState(() => _pickedPhoto = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
            // ✅ Photo first
            _photoSection(),
            const SizedBox(height: 12),

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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Select a location' : null,
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

                          // ✅ Use your existing action/provider methods (create/update),
                          // but we need the saved shop back to upload photo.
                          VendorShop saved;

                          if (isEdit) {
                            saved = await ref
                                .read(vendorShopsActionsProvider)
                                .update(widget.editShop!.id, payload);
                          } else {
                            saved = await ref.read(vendorShopsActionsProvider).create(payload);
                          }

                          // ✅ Upload photo AFTER save (if selected)
                          if (_pickedPhoto != null) {
                            final vendorId = saved.vendorId; // from API object
                            await ref
                                .read(vendorShopsRepositoryProvider)
                                .uploadPhoto(
                                  vendorId: vendorId,
                                  shopId: saved.id,
                                  photoFile: _pickedPhoto!,
                                );
                          }

                          await ref.refresh(vendorShopsProvider.future);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Save failed: $e')),
                            );
                          }
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
