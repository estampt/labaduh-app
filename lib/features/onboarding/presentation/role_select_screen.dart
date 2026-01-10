import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRole { customer, vendor }

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Role')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _RoleCard(
              title: 'Customer',
              subtitle: 'Book laundry pickup, track orders, pay easily',
              onTap: () => context.go('/login', extra: AppRole.customer),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              title: 'Vendor',
              subtitle: 'Accept jobs, manage pricing, view orders',
              onTap: () => context.go('/login', extra: AppRole.vendor),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
