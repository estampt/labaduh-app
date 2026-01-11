import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/vendor_applications_controller.dart';

class VendorRejectedScreen extends ConsumerWidget {
  const VendorRejectedScreen({super.key, required this.appId});
  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(vendorApplicationsProvider).where((a) => a.id == appId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Application Rejected')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: app == null
            ? const Center(child: Text('Application not found'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const Icon(Icons.cancel_outlined),
                      title: Text(app.shopName, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text('Reason: ${app.adminNote ?? 'No reason provided'}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('You can re-submit an updated application.', style: TextStyle(color: Colors.black54)),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.go('/v/apply'),
                    child: const Text('Re-apply'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.go('/c/home'),
                    child: const Text('Back to Customer home'),
                  ),
                ],
              ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
