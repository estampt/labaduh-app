import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/state/auth_providers.dart';

class VendorPendingScreen extends ConsumerStatefulWidget {
  const VendorPendingScreen({super.key, required this.appId});
  final String appId;

  @override
  ConsumerState<VendorPendingScreen> createState() => _VendorPendingScreenState();
}

class _VendorPendingScreenState extends ConsumerState<VendorPendingScreen> {
  Timer? _timer;
  String status = 'pending';

  @override
  void initState() {
    super.initState();
    _poll(); // immediate
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final approval = await repo.refreshMe();
      if (!mounted) return;
      if (approval != null && approval.isNotEmpty) {
        setState(() => status = approval);
      }

      if (approval == 'approved') { 
        context.go('/v/home');
      } else if (approval == 'rejected') {
        // If you have a rejected route, use it. If not, keep pending UI.
        context.go('/v/rejected/${widget.appId}');
      }
    } catch (_) {
      // ignore polling errors (offline, etc.)
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Application')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('We are reviewing your documents. This page auto-refreshes.'),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _poll,
                child: const Text('Refresh now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
