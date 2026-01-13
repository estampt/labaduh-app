import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final emailCtrl = TextEditingController(text: 'rehnee@example.com');
  final mobileCtrl = TextEditingController(text: '09xx xxx xxxx');
  final passCtrl = TextEditingController();

  // ✅ Address + Location
  String? pickedAddressLabel;
  LatLng? pickedLatLng;

  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    mobileCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final res = await OSMMapLocationPicker.open(
      context,
      initialCenter: pickedLatLng, // uses previous selection if any
      initialLabel: pickedAddressLabel,
    );
    if (!mounted || res == null) return;

    setState(() {
      pickedLatLng = res.latLng;
      pickedAddressLabel = res.addressLabel;
    });
  }

  Future<void> _submit() async {
    setState(() => loading = true);

    // Basic validation
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    // ✅ Location required for BOTH roles
    if (pickedLatLng == null || (pickedAddressLabel ?? '').trim().isEmpty) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your address location')),
      );
      return;
    }

    try {
      final ctrl = ref.read(authControllerProvider.notifier);

      if (role == UserRole.customer) {
        // ✅ Register customer (you can extend repository later to accept lat/lng/address)
        await ctrl.registerCustomer(
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          password: passCtrl.text,
        );

        // ✅ Optional: request OTP (make sure AuthRepository has requestOtp)
        // If you don't have it yet, comment this block.
        await ref.read(authRepositoryProvider).requestOtp(
              email: emailCtrl.text.trim(),
            );

        // IMPORTANT: tell router to re-check session
        ref.read(sessionNotifierProvider).refresh();

        if (!mounted) return;

        // ✅ Go to OTP screen first, then OTP screen will redirect to /c/home
        final email = Uri.encodeComponent(emailCtrl.text.trim());
        final next = Uri.encodeComponent('/c/home');
        context.go('/otp?email=$email&next=$next');
      } else {
        // ✅ Vendor still goes to /v/apply (vendor onboarding/documents)
        // Forward the location + address so /v/apply can prefill.
        if (!mounted) return;

        context.go(
          '/v/apply',
          extra: {
            'name': nameCtrl.text.trim(),
            'email': emailCtrl.text.trim(),
            'mobile': mobileCtrl.text.trim(),
            'password': passCtrl.text,
            'address_label': pickedAddressLabel,
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

            // ✅ ADDRESS + OSM MAP PICKER
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(pickedAddressLabel ?? 'Set your address'),
                subtitle: Text(locSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: loading ? null : _pickLocation,
              ),
            ),

            const SizedBox(height: 12),

            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile')),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
