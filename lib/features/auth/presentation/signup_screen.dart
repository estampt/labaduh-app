import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 

import '../../../../shared/widgets/document_upload_tile.dart';
import '../../auth/state/auth_providers.dart';
import '../../../core/models/user_role.dart';
import '../../../shared/widgets/osm_location_picker.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  UserRole role = UserRole.customer;

  final nameCtrl = TextEditingController(text: 'Rehnee');
  final emailCtrl = TextEditingController(text: 'rehneesoriano@gmail.com');
  final addressLine2Ctrl = TextEditingController(text: '15HI');
  final passCtrl = TextEditingController();

  // ✅ Vendor-only fields
  final businessNameCtrl = TextEditingController(text: 'Labaduh');

  // Phone number variables
  final phoneNumberCtrl = TextEditingController(text :'910 123 1231');
  PhoneNumber phoneNumber = PhoneNumber(isoCode: 'PH');
  bool isPhoneValid = false;

  // ✅ Address + Location
  String? addressLine1;
  LatLng? pickedLatLng;

  // Required docs
  DocumentAttachment businessReg =
      DocumentAttachment.empty('Business Registration');
  DocumentAttachment governmentId =
      DocumentAttachment.empty('Government ID');

  // Optional supporting docs placeholders
  final List<DocumentAttachment> supporting = [
    DocumentAttachment.empty('Supporting Document #1'),
    DocumentAttachment.empty('Supporting Document #2'),
  ];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    phoneNumber = PhoneNumber(
      isoCode: 'PH',
      dialCode: '+63',
      phoneNumber: '',
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneNumberCtrl.dispose();
    addressLine2Ctrl.dispose();
    passCtrl.dispose();
    businessNameCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));


Future<DocumentAttachment?> _pickFile({
  required String label,
  required List<String> allowedExtensions,
}) async {
  try {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: allowedExtensions,
      withData: true, // ✅ required on web (bytes)
    );

    if (res == null || res.files.isEmpty) return null;

    final f = res.files.first;

    // ✅ CRITICAL: never read f.path on web
    final String? safePath = kIsWeb ? null : f.path;

    return DocumentAttachment(
      label: label,
      fileName: f.name,
      path: safePath,   // ✅ only mobile/desktop
      bytes: f.bytes,   // ✅ web
      sizeBytes: f.size,
    );
  } catch (e) {
    _showSnack('File picker error: $e');
    return null;
  }
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
      addressLine1 = res.addressLabel;
    });
  }

  Future<void> _submit() async {
    setState(() => loading = true);

    final countryISO = (phoneNumber.isoCode ?? '').trim().toUpperCase();

    // Basic validation
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.isEmpty ||
        addressLine2Ctrl.text.trim().isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack('Please complete required fields');
      return;
    }

    // Phone number validation
    if (!isPhoneValid ||
        phoneNumber.phoneNumber == null ||
        phoneNumber.phoneNumber!.isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack('Please enter a valid phone number');
      return;
    }

    // ✅ Location required for BOTH roles
    if (pickedLatLng == null || (addressLine1 ?? '').trim().isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack('Please set your address location');
      return;
    }

    // ✅ Vendor-only validation
    if (role == UserRole.vendor) {
      //TODO: TO enable document validation later
      /*
      if (businessNameCtrl.text.trim().isEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        _showSnack('Please enter your business name');
        return;
      }

      if ((businessReg.path ?? '').isEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        _showSnack('Please upload your business registration/permit');
        return;
      }

      if ((governmentId.path ?? '').isEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        _showSnack('Please upload your government ID');
        return;
      }
      */
    }

    try {
      final ctrl = ref.read(authControllerProvider.notifier);

      // Build full phone number with dial code
      String? fullPhoneNumber;
      if (phoneNumber.dialCode != null && phoneNumber.phoneNumber != null) {
        final dialCode = phoneNumber.dialCode!;
        final phoneNum = phoneNumber.phoneNumber!;

        final numberWithoutDialCode = phoneNum.startsWith(dialCode)
            ? phoneNum.substring(dialCode.length)
            : phoneNum.replaceAll(RegExp(r'[^\d]+'), '');

        fullPhoneNumber = dialCode + numberWithoutDialCode;
      }

      if (role == UserRole.customer) {
        await ctrl.registerCustomer(
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          password: passCtrl.text,
          phone: fullPhoneNumber,
          addressLine1: addressLine1!.trim(),
          latitude: pickedLatLng!.latitude,
          longitude: pickedLatLng!.longitude,
          addressLine2: addressLine2Ctrl.text.trim(),
          countryISO: countryISO.isEmpty ? null : countryISO,
        );

        if (!mounted) return;
        final email = Uri.encodeComponent(emailCtrl.text.trim());
        final next = Uri.encodeComponent('/c/home');
        context.go('/otp?email=$email&next=$next&role=$role');
      } else {
 
        // role == vendor
        await ctrl.registerVendor(
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          password: passCtrl.text,

          businessName: businessNameCtrl.text.trim(),
          businessRegistration: businessReg, // ✅ non-null after validation
          governmentId: governmentId, // ✅ non-null after validation 

          phone: fullPhoneNumber,
          addressLine1: addressLine1!.trim(),
          latitude: pickedLatLng!.latitude,
          longitude: pickedLatLng!.longitude,
          addressLine2: addressLine2Ctrl.text.trim(),
          countryISO: countryISO.isEmpty ? null : countryISO,
        );

        if (!mounted) return;
        final email = Uri.encodeComponent(emailCtrl.text.trim());
        final next = Uri.encodeComponent('/v/pending');
        context.go('/otp?email=$email&role=$role&next=$next');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Signup failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locSubtitle = pickedLatLng == null
        ? 'Pick your location on map (required)'
        : '${pickedLatLng!.latitude.toStringAsFixed(6)}, ${pickedLatLng!.longitude.toStringAsFixed(6)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User type',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(
                          value: UserRole.customer,
                          label: Text('Customer'),
                          icon: Icon(Icons.person_outline),
                        ),
                        ButtonSegment(
                          value: UserRole.vendor,
                          label: Text('Vendor'),
                          icon: Icon(Icons.store_outlined),
                        ),
                      ],
                      selected: {role},
                      onSelectionChanged: (set) =>
                          setState(() => role = set.first),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Vendor accounts must be approved by Admin before accepting orders.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: nameCtrl,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: emailCtrl,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            InternationalPhoneNumberInput(
              onInputChanged: (PhoneNumber number) {
                setState(() => phoneNumber = number);
              },
              onInputValidated: (bool value) {
                setState(() => isPhoneValid = value);
              },
              selectorConfig: const SelectorConfig(
                selectorType: PhoneInputSelectorType.DROPDOWN,
                showFlags: true,
                useEmoji: true,
                trailingSpace: false,
              ),
              ignoreBlank: false,
              autoValidateMode: AutovalidateMode.disabled,
              selectorTextStyle: const TextStyle(color: Colors.black),
              initialValue: phoneNumber,
              textFieldController: phoneNumberCtrl,
              formatInput: true,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              inputDecoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                enabled: !loading,
              ),
              searchBoxDecoration: InputDecoration(
                hintText: 'Search country...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSaved: (PhoneNumber number) {},
            ),

            const SizedBox(height: 12),

            TextField(
              controller: passCtrl,
              enabled: !loading,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(
                  addressLine1 ?? 'Set your address',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(locSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: loading ? null : _pickLocation,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: addressLine2Ctrl,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Address Line 2',
                hintText: 'Unit, Building, Suite, Floor, etc.',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 2,
              minLines: 1,
            ),

            // ✅ Vendor-only UI
            if (role == UserRole.vendor) ...[
              const SizedBox(height: 12),

              TextField(
                controller: businessNameCtrl,
                enabled: !loading,
                decoration: const InputDecoration(
                  labelText: 'Business name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),
              const Text('Required documents',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),

              DocumentUploadTile(
                title: 'Business registration',
                subtitle:
                    'Upload DTI/SEC registration or business permit (PDF/JPG/PNG)',
                isRequired: true,
                attachment: businessReg,
                onAttachPressed: () async {
                  final picked = await _pickFile(
                    label: 'Business Registration',
                    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (picked != null) setState(() => businessReg = picked);
                },
                onRemovePressed: () => setState(() =>
                    businessReg = DocumentAttachment.empty('Business Registration')),
              ),

              DocumentUploadTile(
                title: 'Government ID',
                subtitle: 'Upload government-issued ID (JPG/PNG/PDF)',
                isRequired: true,
                attachment: governmentId,
                onAttachPressed: () async {
                  final picked = await _pickFile(
                    label: 'Government ID',
                    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (picked != null) setState(() => governmentId = picked);
                },
                onRemovePressed: () => setState(
                    () => governmentId = DocumentAttachment.empty('Government ID')),
              ),

              const SizedBox(height: 12),
              const Text('Supporting documents (optional)',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),

              ...List.generate(supporting.length, (i) {
                final item = supporting[i];
                return DocumentUploadTile(
                  title: item.label,
                  subtitle: 'Add any supporting document (PDF/JPG/PNG)',
                  isRequired: false,
                  attachment: item,
                  onAttachPressed: () async {
                    final picked = await _pickFile(
                      label: item.label,
                      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (picked != null) setState(() => supporting[i] = picked);
                  },
                  onRemovePressed: () => setState(() =>
                      supporting[i] = DocumentAttachment.empty(item.label)),
                );
              }),

              const SizedBox(height: 12),
            ],

            const SizedBox(height: 20),

            FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create Account',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: loading ? null : () => context.go('/login'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
