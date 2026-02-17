import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy placeholder screen.
/// If any old flow still navigates to `/v/home` expecting this screen,
/// keep it but immediately forward to the real vendor dashboard shell.
///
/// NOTE: With the updated router, `/v/home` should be handled by vendorShellRoutes.
/// This file is kept as a safety net if any code references VendorHomeScreen directly.
class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame navigation to avoid build context issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/v/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      //appBar: AppBar(title: Text('Vendor Home')),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
