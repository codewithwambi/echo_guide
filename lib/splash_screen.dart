import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen.dart'; // Replace with your actual home screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Use post-frame callback to ensure context is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!_navigated && mounted) {
          _navigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Welcome to Echo Guide',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
