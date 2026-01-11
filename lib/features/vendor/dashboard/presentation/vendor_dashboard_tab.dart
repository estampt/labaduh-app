import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../orders/state/vendor_orders_controller.dart';

class VendorDashboardTab extends ConsumerWidget {
  const VendorDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vendorOrderStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Active', value: '${stats.active}', icon: Icons.bolt)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'New', value: '${stats.newRequests}', icon: Icons.notifications_active)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(title: 'In Wash', value: '${stats.inWash}', icon: Icons.local_laundry_service)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'Ready', value: '${stats.readyForDelivery}', icon: Icons.local_shipping)),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),

            _MenuTile(
              icon: Icons.receipt_long,
              title: 'Orders',
              subtitle: 'View and manage incoming orders',
              onTap: () => context.go('/v/orders'),
            ),
            _MenuTile(
              icon: Icons.payments,
              title: 'Earnings',
              subtitle: 'View income and payouts',
              onTap: () => context.go('/v/earnings'),
            ),
            _MenuTile(
              icon: Icons.price_change,
              title: 'Services & Pricing',
              subtitle: 'Set prices and add-ons',
              onTap: () => context.go('/v/profile/pricing'),
            ),
            _MenuTile(
              icon: Icons.schedule,
              title: 'Operating Hours',
              subtitle: 'Manage availability',
              onTap: () => context.go('/v/profile/hours'),
            ),
            _MenuTile(
              icon: Icons.store,
              title: 'Shop Profile',
              subtitle: 'Business details and settings',
              onTap: () => context.go('/v/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
