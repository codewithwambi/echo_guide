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
    debugPrint("DEBUG: SplashScreen initState called");

    // Use post-frame callback to ensure context is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("DEBUG: Starting 3 second delay in SplashScreen");
      Future.delayed(const Duration(seconds: 3), () {
        debugPrint("DEBUG: 3 second delay finished in SplashScreen");
        if (!_navigated && mounted) {
          _navigated = true;
          debugPrint("DEBUG: Navigating to OnboardingScreen from SplashScreen");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG: SplashScreen build called");
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
