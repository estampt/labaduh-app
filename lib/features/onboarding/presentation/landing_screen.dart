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

              /// 🔵 BIGGER, CRISP LOGO
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/lottie/images/labaduh_logo.png',
                    width: 220,          // 👈 control size here
                    height: 220,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

              /*
              const SizedBox(height: 16),

              const Text(
                'Login or create an account to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
              */
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
