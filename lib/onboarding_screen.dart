import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // <--- Import FlutterTts
import 'login_screen.dart'; // Ensure this exists

// Convert OnboardingScreen to a StatefulWidget to manage FlutterTts lifecycle
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key}); // Good practice with const Key

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late FlutterTts tts; // Declare as late to initialize in initState

  @override
  void initState() {
    super.initState();
    tts = FlutterTts(); // Initialize FlutterTts here
    _initTts(); // Setup TTS language
    _speakTutorial(); // Start speaking the tutorial
  }

  Future<void> _initTts() async {
    // You can add error handling here for setLanguage
    await tts.setLanguage("en-US");
    // Optionally set pitch, rate, etc.
    // await tts.setPitch(1.0);
    // await tts.setSpeechRate(0.5);
  }

  Future<void> _speakTutorial() async {
    // No need for tts != null check since it's late and initialized in initState
    await tts.speak(
        "Tap anywhere to continue. This app helps you discover nearby places through voice. "
        "Use commands like 'What's near me?' or download tours for offline use.");
  }

  @override
  void dispose() {
    tts.stop(); // Stop any ongoing speech and release resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Stop TTS speech immediately when user taps to navigate
        tts.stop();
        Navigator.pushReplacement(
          context,
          // --- FIX: Removed 'const' here ---
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text( // Made const as text doesn't change
                "Welcome to EchoPath 👋",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 20), // Made const
              ElevatedButton(
                onPressed: () {
                  // Stop TTS speech immediately when user taps button
                  tts.stop();
                  Navigator.pushReplacement(
                    context,
                    // --- FIX: Removed 'const' here ---
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: const Text("Continue"), // Made const
              )
            ],
          ),
        ),
      ),
    );
  }
}