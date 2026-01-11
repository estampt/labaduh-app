import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoadingScreenLabaduhLottie extends StatefulWidget {
  const LoadingScreenLabaduhLottie({super.key});

  @override
  State<LoadingScreenLabaduhLottie> createState() => _LoadingScreenLabaduhLottieState();
}

class _LoadingScreenLabaduhLottieState extends State<LoadingScreenLabaduhLottie> {
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
        child: Lottie.asset(
          'lottie/labaduh_logo.json',
          width: 260,
          repeat: true,
        ),
      ),
    );
  }
}
