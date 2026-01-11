import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VendorProfileTab extends StatelessWidget {
  const VendorProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: CircleAvatar(child: Icon(Icons.store)),
                title: Text('Labaduh Laundry Shop (placeholder)'),
                subtitle: Text('Vendor'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.price_change_outlined),
                title: const Text('Services & Pricing'),
                subtitle: const Text('Manage vendor pricing and services'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/v/profile/pricing'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Operating hours'),
                subtitle: const Text('Set your schedule'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/v/profile/hours'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                subtitle: const Text('Notifications, privacy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/v/profile/settings'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                subtitle: Text('Hook to auth later'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
