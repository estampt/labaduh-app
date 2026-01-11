import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Labaduh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hi Rehnee 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Ready to send your laundry?', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),

            // Main action
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Laundry Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Pickup · Wash · Deliver', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => context.go('/c/order/services'),
                        child: const Text('Start Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Quick Links', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Track Order'),
              subtitle: const Text('See current status'),
              onTap: () => context.go('/c/order/tracking'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Order History'),
              subtitle: const Text('Past pickups and deliveries'),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Support'),
              subtitle: const Text('Chat or FAQ'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
