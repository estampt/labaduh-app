import 'package:flutter/material.dart';

class VendorHomeScreen extends StatelessWidget {
  const VendorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Home')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Vendor is approved ✅\n\nNext: add Vendor UI shell (Orders/Queue/Earnings/Profile).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
