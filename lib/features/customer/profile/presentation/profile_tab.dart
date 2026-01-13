import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/logout_helper.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Rehnee (placeholder)'),
                subtitle: Text('Customer'),
              ),
            ),

            const SizedBox(height: 12),

            // ---------------- ADDRESSES ----------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Addresses'),
                subtitle: const Text('Manage pickup/drop-off locations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/c/profile/addresses'),
              ),
            ),

            const SizedBox(height: 12),

            // ---------------- PAYMENTS ----------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.credit_card_outlined),
                title: const Text('Payment methods'),
                subtitle: const Text('GCash / Cards (placeholder)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/c/profile/payments'),
              ),
            ),

            const SizedBox(height: 12),

            // ---------------- SETTINGS ----------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                subtitle: const Text('Notifications, privacy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/c/profile/settings'),
              ),
            ),

            const SizedBox(height: 12),

            // ---------------- SUPPORT ----------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Support'),
                subtitle: const Text('FAQ and contact'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/c/profile/support'),
              ),
            ),

            const SizedBox(height: 12),

            // ================= ADMIN ACCESS =================
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.orange.withOpacity(0.08),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.orange),
                title: const Text(
                  'Admin Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Internal / admin access'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/a/overview'),
              ),
            ),

            const SizedBox(height: 12),

            // ---------------- LOGOUT ----------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                subtitle: const Text('Sign out of this device'),
                onTap: () async {
                  await performLogout(
                    ref: ref,
                    router: GoRouter.of(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
