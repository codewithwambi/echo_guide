import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'login_screen.dart';

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
    _initTts().then((_) => _speakTutorial());

    // Fallback navigation in case user doesn't tap
    Future.delayed(Duration(seconds: 8), () {
      if (!_navigated && mounted) _goToLogin();
    });
  }

  void _goToLogin() {
    if (_navigated) return;
    _navigated = true;

    tts.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _initTts() async {
    await tts.setLanguage("en-US");
  }

  Future<void> _speakTutorial() async {
    await tts.speak(
        "Tap anywhere to continue. This app helps you discover nearby places through voice. "
        "Use commands like 'What's near me?' or download tours for offline use.");
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goToLogin,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Welcome to EchoPath 👋",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _goToLogin,
                child: const Text("Continue"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
