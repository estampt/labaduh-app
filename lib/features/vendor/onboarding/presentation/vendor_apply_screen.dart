import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/state/session_controller.dart';
import '../../../../shared/widgets/document_upload_tile.dart';
import '../../../../shared/widgets/osm_location_picker.dart';

import '../../data/vendor_application.dart';
import '../../state/vendor_applications_controller.dart';

class VendorApplyScreen extends ConsumerStatefulWidget {
  const VendorApplyScreen({super.key});

  @override
  ConsumerState<VendorApplyScreen> createState() => _VendorApplyScreenState();
}

class _VendorApplyScreenState extends ConsumerState<VendorApplyScreen> {
  final shopCtrl = TextEditingController();
  final cityCtrl = TextEditingController(text: 'Quezon City');
  final ownerCtrl = TextEditingController(text: 'Rehnee');
  final mobileCtrl = TextEditingController(text: '09xx xxx xxxx');
  final emailCtrl = TextEditingController(text: 'rehnee@example.com');

  LatLng? pickedLatLng;

  // Required docs
  DocumentAttachment businessReg = DocumentAttachment.empty('Business Registration');
  DocumentAttachment governmentId = DocumentAttachment.empty('Government ID');

  // Optional supporting docs placeholders
  final List<DocumentAttachment> supporting = [
    DocumentAttachment.empty('Supporting Document #1'),
    DocumentAttachment.empty('Supporting Document #2'),
  ];

  @override
  void dispose() {
    shopCtrl.dispose();
    cityCtrl.dispose();
    ownerCtrl.dispose();
    mobileCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => businessReg.isAttached && governmentId.isAttached && pickedLatLng != null;

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<DocumentAttachment?> _pickFile({
    required String label,
    required List<String> allowedExtensions,
  }) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: allowedExtensions,
        withData: false, // keep light; upload later using path/stream
      );
      if (res == null || res.files.isEmpty) return null;

      final f = res.files.first;
      if (f.name.isEmpty) return null;

      return DocumentAttachment(
        label: label,
        fileName: f.name,
        path: f.path,
        sizeBytes: f.size,
      );
    } catch (e) {
      _showSnack('File picker error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final appsCtrl = ref.read(vendorApplicationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Application')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Approval required'),
                subtitle: Text('Your shop must be approved by Admin before accepting orders.'),
              ),
            ),
            const SizedBox(height: 12),

            TextField(controller: ownerCtrl, decoration: const InputDecoration(labelText: 'Owner / Contact name')),
            const SizedBox(height: 10),
            TextField(controller: shopCtrl, decoration: const InputDecoration(labelText: 'Shop name')),
            const SizedBox(height: 10),
            TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: 10),
            TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),

            const SizedBox(height: 12),

            // Location picker
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Shop location'),
                subtitle: Text(
                  pickedLatLng == null
                      ? 'Tap to pin your shop location on map (required)'
                      : 'Pinned: ${pickedLatLng!.latitude.toStringAsFixed(6)}, ${pickedLatLng!.longitude.toStringAsFixed(6)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final res = await OSMMapLocationPicker.open(
                    context,
                    initialCenter: pickedLatLng ?? const LatLng(14.5995, 120.9842),
                  );
                  if (res != null) setState(() => pickedLatLng = res.latLng);
                },
              ),
            ),

            const SizedBox(height: 12),
            const Text('Required documents', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),

            DocumentUploadTile(
              title: 'Business registration',
              subtitle: 'Upload DTI/SEC registration or business permit (PDF/JPG/PNG)',
              isRequired: true,
              attachment: businessReg,
              onAttachPressed: () async {
                final picked = await _pickFile(label: 'Business Registration', allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png']);
                if (picked != null) setState(() => businessReg = picked);
              },
              onRemovePressed: () => setState(() => businessReg = DocumentAttachment.empty('Business Registration')),
            ),

            DocumentUploadTile(
              title: 'Government ID',
              subtitle: 'Upload government-issued ID (JPG/PNG/PDF)',
              isRequired: true,
              attachment: governmentId,
              onAttachPressed: () async {
                final picked = await _pickFile(label: 'Government ID', allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png']);
                if (picked != null) setState(() => governmentId = picked);
              },
              onRemovePressed: () => setState(() => governmentId = DocumentAttachment.empty('Government ID')),
            ),

            const SizedBox(height: 12),
            const Text('Supporting documents (optional)', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),

            ...List.generate(supporting.length, (i) {
              final item = supporting[i];
              return DocumentUploadTile(
                title: item.label,
                subtitle: 'Add any supporting document (PDF/JPG/PNG)',
                isRequired: false,
                attachment: item,
                onAttachPressed: () async {
                  final picked = await _pickFile(label: item.label, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png']);
                  if (picked != null) setState(() => supporting[i] = picked);
                },
                onRemovePressed: () => setState(() => supporting[i] = DocumentAttachment.empty(item.label)),
              );
            }),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: !_canSubmit
                  ? () {
                      if (pickedLatLng == null) _showSnack('Please pin your shop location on the map.');
                      if (!businessReg.isAttached) _showSnack('Business registration document is required.');
                      if (!governmentId.isAttached) _showSnack('Government ID is required.');
                    }
                  : () {
                      final id = 'v${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                      final app = VendorApplication(
                        id: id,
                        ownerName: ownerCtrl.text.trim().isEmpty ? session.userName : ownerCtrl.text.trim(),
                        shopName: shopCtrl.text.trim().isEmpty ? 'New Vendor' : shopCtrl.text.trim(),
                        city: cityCtrl.text.trim().isEmpty ? 'City' : cityCtrl.text.trim(),
                        mobile: mobileCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        createdAtLabel: 'Just now',
                        status: VendorApprovalStatus.pending,
                      );

                      // NOTE: Next step: send these to Laravel
                      // - pickedLatLng.latitude/longitude
                      // - businessReg.path, governmentId.path, supporting[i].path
                      appsCtrl.submit(app);
                      context.go('/v/pending?id=$id');
                    },
              child: const Text('Submit application'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Attachments are picked locally. Next step is uploading to Laravel API.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
