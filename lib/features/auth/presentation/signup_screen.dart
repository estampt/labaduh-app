import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:latlong2/latlong.dart';

import '../../auth/state/auth_providers.dart';
import '../../../core/models/user_role.dart';
import '../../../core/auth/session_notifier.dart';
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
  final addressLine2Ctrl = TextEditingController();
  final passCtrl = TextEditingController();

  // Phone number variables
  final phoneNumberCtrl = TextEditingController();
  PhoneNumber phoneNumber = PhoneNumber(isoCode: 'PH');
  String initialCountry = 'PH';
  bool isPhoneValid = false;

  // ✅ Address + Location
  String? addressLine1;
  LatLng? pickedLatLng;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Initialize phone number for Philippines
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
      addressLine1 = res.addressLabel;
    });
  }

  Future<void> _submit() async {
    setState(() => loading = true);

    final countryISO = (phoneNumber.isoCode ?? '').trim().toUpperCase(); // e.g. "SG"
  
    // Basic validation
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.isEmpty ||
        addressLine2Ctrl.text.trim().isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    // Phone number validation
    if (!isPhoneValid || phoneNumber.phoneNumber == null || phoneNumber.phoneNumber!.isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    // ✅ Location required for BOTH roles
    if (pickedLatLng == null || (addressLine1 ?? '').trim().isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your address location')),
      );
      return;
    }

    try {
      final ctrl = ref.read(authControllerProvider.notifier);

      // Get full phone number with country code 
      String? fullPhoneNumber;
      if (phoneNumber.dialCode != null && phoneNumber.phoneNumber != null) {
        final dialCode = phoneNumber.dialCode!;
        final phoneNum = phoneNumber.phoneNumber!;
        
        // Remove the dial code from the beginning if it exists
        final numberWithoutDialCode = phoneNum.startsWith(dialCode)
            ? phoneNum.substring(dialCode.length)
            : phoneNum.replaceAll(RegExp(r'[^\d]+'), '');
        
        fullPhoneNumber = dialCode + numberWithoutDialCode;
      }

       
      if (role == UserRole.customer) {
        // ✅ Register customer WITHOUT mobile parameter if not supported
        // Check if registerCustomer accepts mobile parameter
        await ctrl.registerCustomer(
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          password: passCtrl.text,
          
          // phone number INCLUDING country code (e.g. +639171234567)
          phone: fullPhoneNumber,

          // the human-readable label from the map picker
          addressLine1: addressLine1!.trim(),

          // coordinates from the map picker
          latitude: pickedLatLng!.latitude,
          longitude: pickedLatLng!.longitude,

          // unit / building / floor, etc.
          addressLine2: addressLine2Ctrl.text.trim(),

          countryISO: countryISO.isEmpty ? null : countryISO,
        );
 
        if (!mounted) return;
        final email = Uri.encodeComponent(emailCtrl.text.trim());
        final next = Uri.encodeComponent('/c/home');
        context.go('/otp?email=$email&next=$next');
        // Debug: print all values
        print('=== SUCCESS ===');
         
      } else {
        // ✅ Vendor still goes to /v/apply (vendor onboarding/documents)
        // Forward the location + address so /v/apply can prefill.
        if (!mounted) return;

        context.go(
          '/v/apply',
          extra: {
            'name': nameCtrl.text.trim(),
            'email': emailCtrl.text.trim(),
            'mobile': fullPhoneNumber,
            'country_code': phoneNumber.dialCode,
            'iso_code': phoneNumber.isoCode,
            'password': passCtrl.text,
            'address_label': addressLine1,
            'address_line2': addressLine2Ctrl.text.trim(),
            'lat': pickedLatLng!.latitude,
            'lng': pickedLatLng!.longitude,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User type', style: TextStyle(fontWeight: FontWeight.w900)),
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
                      onSelectionChanged: (set) => setState(() => role = set.first),
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
              )
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: emailCtrl, 
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              )
            ),
            
            const SizedBox(height: 12),
            
            // UPDATED: Using intl_phone_number_input
            InternationalPhoneNumberInput(
              onInputChanged: (PhoneNumber number) {
                setState(() {
                  phoneNumber = number;
                });
              },
              onInputValidated: (bool value) {
                setState(() {
                  isPhoneValid = value;
                });
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
                signed: true,
                decimal: true,
              ),
              inputDecoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isPhoneValid ? Colors.grey : Colors.red,
                  ),
                ),
                enabled: !loading,
              ),
              searchBoxDecoration: InputDecoration(
                hintText: 'Search country...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSaved: (PhoneNumber number) {
                // Handle when form is saved
              },
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

            // ✅ ADDRESS + OSM MAP PICKER
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

            // UPDATED: Address Line 2 Input Field - Now Mandatory
            TextField(
              controller: addressLine2Ctrl,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Address Line 2',
                hintText: 'Unit, Building, Suite, Floor, etc.',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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