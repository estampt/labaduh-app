import 'package:flutter/material.dart';

class VendorHoursScreen extends StatelessWidget {
  const VendorHoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operating hours')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text('Placeholder screen'),
            SizedBox(height: 8),
            Text('Next: create weekly schedule + holiday overrides.'),
          ],
        ),
      ),
    );
  }
}
