import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// For basic logging in development, use `developer.log` instead of `print`.
// For production, consider a dedicated logging framework (e.g., 'logger' package).
import 'dart:developer' as developer;

// --- IMPORTANT ---
// Ensure these files exist in your 'lib' folder and define the respective classes:
// - 'tour_discovery_screen.dart' should define 'TourDiscoveryScreen'
// - 'downloads_screen.dart' should define 'DownloadsScreen'
// - 'help_&_support_screen.dart' should define 'HelpSupportScreen'
// If you rename 'help_&_support_screen.dart' (recommended), update the import path here.
import "tour_discovery_screen.dart";
import "downloads_screen.dart";
import "help_and_support_screen.dart"; // Keeping this as given, but consider renaming the file.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // Good practice: const constructor with Key

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterTts tts; // Declared late, initialized in initState
  late stt.SpeechToText speech; // Declared late, initialized in initState

  @override
  void initState() {
    super.initState();
    tts = FlutterTts(); // Initialize TTS
    speech = stt.SpeechToText(); // Initialize STT

    _initTts(); // Setup TTS language
    _initSpeechToText(); // Setup STT (optional, based on need)
    _speakGreeting(); // Call greeting here, only once
  }

  Future<void> _initTts() async {
    await tts.setLanguage("en-US");
    // Further TTS settings can go here (pitch, rate, etc.)
  }

  Future<void> _initSpeechToText() async {
    // You might want to request permissions here
    bool available = await speech.initialize(
      // --- FIX: Replaced print() with developer.log() ---
      onError: (val) => developer.log('STT Error: $val', name: 'SpeechToText'),
      onStatus: (val) => developer.log('STT Status: $val', name: 'SpeechToText'),
    );
    if (!available) {
      // --- FIX: Replaced print() with developer.log() ---
      developer.log('Speech recognition not available on this device.', name: 'SpeechToText');
      // Optionally show a SnackBar or AlertDialog to the user
    }
  }

  Future<void> _speakGreeting() async {
    // It's good practice to check if the widget is still mounted before performing
    // UI-related actions after an await, especially for longer async operations.
    if (mounted) {
      await tts.speak("Welcome to EchoPath. What would you like to do?");
    }
  }

  @override
  void dispose() {
    // Crucial: Dispose of resources when the widget is removed
    tts.stop(); // Stop any ongoing speech
    // --- FIX: Removed tts.acm.stop() - 'acm' is not a public getter ---
    speech.stop(); // Stop any ongoing speech recognition
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The build method should be "pure" - avoid side effects like speakGreeting() here.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text( // Added const for static Text
              "Main Menu",
              style: TextStyle(color: Colors.white, fontSize: 28),
            ),
            const SizedBox(height: 20), // Added const for static SizedBox
            ElevatedButton(
              onPressed: () {
                tts.stop(); // Stop speech before navigating
                Navigator.push(
                  context,
                  // --- FIX: Removed 'const' for TourDiscoveryScreen() ---
                  MaterialPageRoute(builder: (_) => TourDiscoveryScreen()),
                );
              },
              child: const Text("Discover Nearby Tours"), // Added const for static Text
            ),
            ElevatedButton(
              onPressed: () {
                tts.stop(); // Stop speech before navigating
                Navigator.push(
                  context,
                  // --- FIX: Removed 'const' for DownloadsScreen() ---
                  MaterialPageRoute(builder: (_) => DownloadsScreen()),
                );
              },
              child: const Text("My Downloads"), // Added const for static Text
            ),
            ElevatedButton(
              onPressed: () {
                tts.stop(); // Stop speech before navigating
                Navigator.push(
                  context,
                  // --- FIX: Removed 'const' for HelpSupportScreen() ---
                  MaterialPageRoute(builder: (_) => HelpAndSupportScreen()),
                );
              },
              child: const Text("Voice Command Help"), // Added const for static Text
            ),
          ],
        ),
      ),
    );
  }
}