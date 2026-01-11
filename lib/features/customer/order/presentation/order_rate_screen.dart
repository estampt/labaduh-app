import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderRateScreen extends StatefulWidget {
  const OrderRateScreen({super.key});

  @override
  State<OrderRateScreen> createState() => _OrderRateScreenState();
}

class _OrderRateScreenState extends State<OrderRateScreen> {
  int rating = 5;
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Experience')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('How was your order?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final v = i + 1;
                return IconButton(
                  onPressed: () => setState(() => rating = v),
                  icon: Icon(v <= rating ? Icons.star : Icons.star_border),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                hintText: 'Tell us what went well or what we can improve…',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => context.go('/c/orders'),
                child: const Text('Submit'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
