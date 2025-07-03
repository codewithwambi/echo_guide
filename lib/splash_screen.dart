import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'onboarding_screen.dart'; // Replace with your actual next screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speakWelcome();
    _navigateToNext();
  }

  Future<void> _speakWelcome() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(
      "Welcome to EchoPath. Your voice-guided journey begins here.",
    );
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return; // ✅ Prevents context errors
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assistant_navigation,
              color: Colors.lightBlueAccent,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'EchoPath',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Voice-powered tour guide',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
