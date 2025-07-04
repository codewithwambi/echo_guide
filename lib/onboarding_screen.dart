import 'package:flutter/material.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: OnboardingScreen initState");

    // Auto-navigate to HomeScreen after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      debugPrint("DEBUG: Auto navigating to HomeScreen");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG: OnboardingScreen build");

    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "👋 Welcome to EchoPath!\n\nTap anywhere to continue...",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
