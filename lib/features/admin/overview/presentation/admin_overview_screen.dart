import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/kpi_card.dart';
import '../../shared/widgets/section_header.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: const [
              Expanded(child: KpiCard(title: 'Active orders', value: '12', subtitle: 'Right now', icon: Icons.local_laundry_service)),
              SizedBox(width: 10),
              Expanded(child: KpiCard(title: 'Vendors online', value: '28', subtitle: 'Available', icon: Icons.store)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: KpiCard(title: 'GMV today', value: '₱ 18,240', subtitle: 'Gross', icon: Icons.payments)),
              SizedBox(width: 10),
              Expanded(child: KpiCard(title: 'Platform fees', value: '₱ 912', subtitle: 'Estimated', icon: Icons.percent)),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader('Quick actions'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickAction(icon: Icons.receipt_long, label: 'View Orders', onTap: () => context.go('/a/orders')),
              _QuickAction(icon: Icons.store, label: 'Manage Vendors', onTap: () => context.go('/a/vendors')),
              _QuickAction(icon: Icons.price_change, label: 'System Pricing', onTap: () => context.go('/a/pricing')),
              _QuickAction(icon: Icons.settings, label: 'Settings', onTap: () => context.go('/a/settings')),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader('Health'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('All systems operational'),
              subtitle: Text('No incidents reported (placeholder)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
