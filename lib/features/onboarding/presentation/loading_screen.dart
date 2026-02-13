import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int _step = 0;

  final _messages = [
    'Sending your order…',
    'Finding laundry partners…',
    'Matching the best vendor…',
  ];

  @override
  void initState() {
    super.initState();

    // Step animation text
    Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (!mounted) return;

      setState(() {
        _step++;
        if (_step >= _messages.length) {
          _step = _messages.length - 1;
        }
      });
    });

    // Total duration: 2.5 sec
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (!mounted) return;

      Navigator.pop(context); // Return to caller
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_step],
                  key: ValueKey(_messages[_step]),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Please wait a moment',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
