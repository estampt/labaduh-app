import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_role.dart';
import '../../state/vendor_applications_controller.dart';

class VendorPendingScreen extends ConsumerWidget {
  const VendorPendingScreen({super.key, required this.appId});
  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(vendorApplicationsProvider).where((a) => a.id == appId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
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
                      leading: const Icon(Icons.hourglass_top),
                      title: Text('${app.shopName}'),
                      subtitle: Text('Status: ${app.status.label}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your application is pending admin approval. You will be able to access Vendor features once approved.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      final latest = ref.read(vendorApplicationsProvider).where((a) => a.id == appId).firstOrNull;
                      if (latest == null) return;

                      if (latest.status == VendorApprovalStatus.approved) {
                        context.go('/v/home');
                      } else if (latest.status == VendorApprovalStatus.rejected) {
                        context.go('/v/rejected?id=$appId');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Still pending. Please check again later.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check status'),
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
