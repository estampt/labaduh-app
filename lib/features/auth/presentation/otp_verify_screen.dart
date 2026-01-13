import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/state/auth_providers.dart';
import '../../../core/auth/session_notifier.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({
    super.key,
    required this.email,
    required this.next,
  });

  final String email;
  final String next;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final codeCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            email: widget.email,
            code: codeCtrl.text.trim(),
          );

      // refresh guard/session then go
      ref.read(sessionNotifierProvider).refresh();

      if (!mounted) return;
      context.go(widget.next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).requestOtp(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resend failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'We sent a code to: ${widget.email}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP code'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _verify,
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
            TextButton(
              onPressed: _resend,
              child: const Text('Resend code'),
            ),
          ],
        ),
      ),
    );
  }
}
