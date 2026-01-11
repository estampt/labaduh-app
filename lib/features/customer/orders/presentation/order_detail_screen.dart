import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Pickup scheduled', true),
      ('Picked up', true),
      ('Washing', true),
      ('Ready', false),
      ('Delivered', false),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.storefront_outlined),
                title: Text('Laundry partner (placeholder)'),
                subtitle: Text('Rating: 4.8 • 1.2km away'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Items', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    _line('Wash & Fold', '6 KG'),
                    _line('Whites', '6 KG'),
                    const Divider(height: 20),
                    _line('Total', '₱ 498', strong: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tracking', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    for (final s in steps) ...[
                      Row(
                        children: [
                          Icon(s.$2 ? Icons.check_circle : Icons.radio_button_unchecked),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.$1, style: TextStyle(fontWeight: s.$2 ? FontWeight.w800 : FontWeight.w600)),
                          ),
                        ],
                      ),
                      if (s != steps.last) const Divider(height: 18),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _line(String left, String right, {bool strong = false}) {
    final style = TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w600);
    return Row(
      children: [
        Expanded(child: Text(left, style: style)),
        Text(right, style: style),
      ],
    );
  }
}
