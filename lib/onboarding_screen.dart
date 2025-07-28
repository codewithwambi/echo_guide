import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  late FlutterTts tts;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    tts = FlutterTts();

    // Initialize TTS and then speak tutorial
    Future.microtask(() async {
      await _initTts();
      await _speakTutorial();
      // Automatically navigate to home after tutorial for blind users
      await _autoNavigateToHome();
    });
  }

  Future<void> _initTts() async {
    await tts.setLanguage("en-US");
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5); // Slow down for accessibility
  }

  Future<void> _speakTutorial() async {
    await tts.speak(
      "Welcome to EchoPath. "
      "This app helps you discover nearby places through voice. "
      "Use commands like 'go to map' for location tracking, 'go to discover' for tours, "
      "'go to downloads' for offline content, or 'go to help' for assistance. "
      "Navigating to home screen in 3 seconds.",
    );
  }

  Future<void> _autoNavigateToHome() async {
    // Wait for tutorial to complete, then auto-navigate
    await Future.delayed(const Duration(seconds: 3));
    if (!_navigated && mounted) {
      setState(() {
        _navigated = true;
      });
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 180, 87, 87),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to EchoPath 👋",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your accessible tour guide. Navigating to home screen automatically.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.volume_up),
              label: Text("Replay onboarding instructions"),
              onPressed: _speakTutorial,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
