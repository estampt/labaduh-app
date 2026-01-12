import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.local_laundry_service, size: 72),
              const SizedBox(height: 14),
              const Text(
                'Labaduh',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Laundry made easy.\nLogin or create an account to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Sign up'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/role'),
                child: const Text('Choose role (optional)'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
