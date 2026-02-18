import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/state/auth_providers.dart';
import '../../../../core/auth/session_notifier.dart';

class VendorDocumentsScreen extends ConsumerStatefulWidget {
  const VendorDocumentsScreen({super.key, required this.payload});
  final Map<String, dynamic> payload; // carries vendor info + location

  @override
  ConsumerState<VendorDocumentsScreen> createState() => _VendorDocumentsScreenState();
}

class _VendorDocumentsScreenState extends ConsumerState<VendorDocumentsScreen> {
  String? businessRegPath;
  String? governmentIdPath;
  final List<String> supportingPaths = [];

  bool loading = false;

  Future<String?> _pickOne(String title) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      dialogTitle: title,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (res == null || res.files.isEmpty) return null;
    return res.files.single.path;
  }

  Future<void> _pickMany() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      dialogTitle: 'Select supporting documents (optional)',
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (res == null || res.files.isEmpty) return;

    final paths = res.files.map((f) => f.path).whereType<String>().toList();
    if (paths.isEmpty) return;

    setState(() => supportingPaths.addAll(paths));
  }

  Future<void> _submit() async {
    if (businessRegPath == null || governmentIdPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload Business Registration and Government ID')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      final p = widget.payload;

      final vendorId =null;
      //TODO: Fix the document upload
      /*
      final vendorId = await repo.registerVendorMultipart(
        name: p['name'] as String,
        email: p['email'] as String,
        password: p['password'] as String,
        businessName: p['business_name'] as String,
        contactNumber: p['contact_number'] as String?,

        addressLine1: p['address_line1'] as String,
        addressLine2: p['address_line2'] as String?,
        postalCode: p['postal_code'] as String?,
        countryISO: p['country_ISO'] as String,
        latitude: (p['latitude'] as num).toDouble(),
        longitude: (p['longitude'] as num).toDouble(),

        businessRegistrationPath: businessRegPath!,
        governmentIdPath: governmentIdPath!,
        supportingDocPaths: supportingPaths,
      );

        */
      // refresh routing/session guard
      ref.read(sessionNotifierProvider).refresh();

      if (!mounted) return;

      // ✅ After vendor register, go to pending screen (you already have this route)
      // If vendorId is null, fallback to vendor home.
      if (vendorId != null) {
        context.go('/v/pending/$vendorId');
      } else {
        context.go('/v/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendor signup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vendor info', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Business: ${p['business_name']}'),
                  Text('Email: ${p['email']}'),
                  Text('Address: ${p['address_line1']}'),
                  Text('Country ISO: ${p['country_ISO']}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Business registration (required)'),
              subtitle: Text(businessRegPath ?? 'Upload PDF/JPG/PNG'),
              trailing: const Icon(Icons.upload_file),
              onTap: loading
                  ? null
                  : () async {
                      final p = await _pickOne('Select business registration');
                      if (p != null) setState(() => businessRegPath = p);
                    },
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Government ID (required)'),
              subtitle: Text(governmentIdPath ?? 'Upload PDF/JPG/PNG'),
              trailing: const Icon(Icons.upload_file),
              onTap: loading
                  ? null
                  : () async {
                      final p = await _pickOne('Select government ID');
                      if (p != null) setState(() => governmentIdPath = p);
                    },
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Supporting documents (optional)'),
              subtitle: Text(
                supportingPaths.isEmpty ? 'Add optional files' : '${supportingPaths.length} file(s) selected',
              ),
              trailing: const Icon(Icons.add),
              onTap: loading ? null : _pickMany,
            ),
          ),

          const SizedBox(height: 18),

          FilledButton(
            onPressed: loading ? null : _submit,
            child: loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit vendor registration'),
          ),
        ],
      ),
    );
  }
}
