import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoadingScreenLottie extends StatefulWidget {
  const LoadingScreenLottie({super.key});

  @override
  State<LoadingScreenLottie> createState() => _LoadingScreenLottieState();
}

class _LoadingScreenLottieState extends State<LoadingScreenLottie> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.go('/role');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/loading.json',
              width: 180,
              repeat: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
