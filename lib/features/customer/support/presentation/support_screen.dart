import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      ('How do pickups work?', 'Choose your services, pickup time, and we match you to a laundry partner.'),
      ('How are prices computed?', 'Each service has its own KG/piece bucket. Total includes delivery + service fee.'),
      ('Can I walk in instead?', 'Yes. Select Walk-in in Pickup & Delivery.'),
      ('What if my laundry exceeds base KG?', 'Excess per KG is added according to the vendor/system pricing.'),
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
                trailing: Icon(Icons.chevron_right),
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
            const Text('FAQs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
