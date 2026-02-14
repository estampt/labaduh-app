import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // <- add this for unawaited
import '../../../core/push/push_providers.dart'; // <- adjust path

import '../../auth/state/auth_providers.dart';
import '../../../core/auth/session_notifier.dart';
import '../../../core/push/last_seen/last_seen_providers.dart';
 

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => loading = true);

    try {
      final ctrl = ref.read(authControllerProvider.notifier);

      final outcome = await ctrl.login(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      if (!outcome.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(outcome.message ?? 'Login failed')),
        );
        return;
      }

      // 🔑 IMPORTANT: notify router that auth state changed
      ref.read(sessionNotifierProvider).refresh();

      // ✅ NEW: register FCM token to backend (don’t block navigation)
      unawaited(ref.read(pushTokenServiceProvider).bootstrap());
      unawaited(ref.read(pushNotificationServiceProvider).bootstrap());
      unawaited(Future(() => ref.read(lastSeenServiceProvider).start()));

      
      if (!mounted) return;
      
      context.go(outcome.nextRoute);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
