import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart'; // Import the flutter_tts package
import 'onboarding_screen.dart'; // Replace with your actual home screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // Good practice with const Key

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late FlutterTts tts; // Declared as late, initialized in initState

  @override
  void initState() {
    super.initState();
    tts = FlutterTts(); // Initialize FlutterTts here
    _initTts(); // Initialize TTS settings
    _speakIntro();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) { // Essential check before navigation
        Navigator.pushReplacement(
          context,
          // --- FIX for 'const_with_non_const' ---
          // Removed 'const' because OnboardingScreen's constructor isn't const.
          // If OnboardingScreen can be const, add 'const' to its constructor.
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      }
    });
  }

  Future<void> _initTts() async {
    await tts.setLanguage("en-US");
    // You can add more settings here, e.g.:
    // await tts.setPitch(1.0);
    // await tts.setSpeechRate(0.5);
  }

  Future<void> _speakIntro() async {
    // --- FIX for 'unnecessary_null_comparison' ---
    // Removed 'if (tts != null)' because 'tts' is 'late' and guaranteed to be initialized.
    await tts.speak("Welcome to EchoPath. Your journey begins here.");
  }

  @override
  void dispose() {
    tts.stop(); // Stop TTS to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold( // This can remain const if its children are const
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, color: Colors.blueAccent, size: 100),
            SizedBox(height: 20),
            Text("EchoPath", style: TextStyle(color: Colors.white, fontSize: 28)),
            Text("Voice powered tour guide", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}