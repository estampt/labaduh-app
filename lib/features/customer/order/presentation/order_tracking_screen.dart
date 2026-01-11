import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Pickup scheduled', true),
      ('Picked up', true),
      ('Washing', false),
      ('Ready', false),
      ('Delivered', false),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Order #1024', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Status updates (UI placeholder)', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final s in steps) ...[
                      Row(
                        children: [
                          Icon(s.$2 ? Icons.check_circle : Icons.radio_button_unchecked),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.$1, style: TextStyle(fontWeight: s.$2 ? FontWeight.w800 : FontWeight.w600))),
                        ],
                      ),
                      if (s != steps.last) const Divider(height: 18),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => context.push('/c/order/success'),
                child: const Text('Simulate Delivered (demo)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
