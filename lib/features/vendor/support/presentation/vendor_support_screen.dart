import 'package:flutter/material.dart';

class VendorSupportScreen extends StatelessWidget {
  const VendorSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      ('How do I get more orders?', 'Keep your pricing competitive and stay available.'),
      ('How do I set my own prices?', 'Go to Profile → Pricing and disable system pricing.'),
      ('How do I pause orders?', 'Enable Vacation mode in Profile.'),
      ('When do payouts happen?', 'Payout schedule is configurable (placeholder).'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.chat_bubble_outline),
                title: Text('Chat support'),
                subtitle: Text('Coming soon'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('Email us'),
                subtitle: Text('support@labaduh.com (placeholder)'),
              ),
            ),
            const SizedBox(height: 18),
            const Text('FAQs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...faqs.map((f) => Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [Text(f.$2, style: const TextStyle(color: Colors.black54))],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
