import 'package:flutter/material.dart';

class VendorSettingsScreen extends StatelessWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Settings')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Placeholder screen'),
      ),
    );
  }
}
