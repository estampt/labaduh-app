import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderMatchingScreen extends StatefulWidget {
  const OrderMatchingScreen({super.key});

  @override
  State<OrderMatchingScreen> createState() => _OrderMatchingScreenState();
}

class _OrderMatchingScreenState extends State<OrderMatchingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.go('/c/order/tracking');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finding Partner')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Finding the best laundry partner near you…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('This usually takes a few seconds.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
