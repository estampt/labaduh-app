import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/vendor_profile_controller.dart';

class VendorProfileTab extends ConsumerWidget {
  const VendorProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(vendorProfileProvider);
    final ctrl = ref.read(vendorProfileProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.storefront)),
                title: Text(profile.shopName, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${profile.address}\n${profile.openHours}'),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                value: profile.vacationMode,
                onChanged: ctrl.setVacation,
                title: const Text('Vacation mode', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Pause incoming orders'),
                secondary: const Icon(Icons.beach_access_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.store_mall_directory_outlined),
                title: const Text('Shop info'),
                subtitle: const Text('Hours, address, capacity'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/v/profile/shop'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.price_change_outlined),
                title: const Text('Pricing'),
                subtitle: const Text('System price or your own'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/v/profile/pricing'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                subtitle: const Text('Notifications, auto-accept'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/v/profile/settings'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Support'),
                subtitle: const Text('FAQs and contact'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/v/profile/support'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
