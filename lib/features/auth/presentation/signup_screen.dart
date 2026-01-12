import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/state/auth_providers.dart';
import '../../../core/models/user_role.dart';
import '../../../core/auth/session_notifier.dart';

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

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    mobileCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () async {
                // Basic validation
                if (nameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty ||
                    passCtrl.text.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please complete required fields')),
                  );
                  return;
                }

                try {
                  final ctrl = ref.read(authControllerProvider.notifier);

                  if (role == UserRole.customer) {
                    await ctrl.registerCustomer(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text,
                    );

                    // IMPORTANT: tell router to re-check session
                    ref.read(sessionNotifierProvider).refresh();

                    if (!context.mounted) return;
                    context.go('/c/home');
                  } else {
                    // Vendor signup requires location + mandatory documents.
                    // This base signup screen forwards vendors to the vendor application flow.
                    if (!context.mounted) return;
                    context.go('/v/apply');
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Signup failed: $e')),
                  );
                }
              },
              child: const Text('Create account'),
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
