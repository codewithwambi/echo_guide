import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import FlutterTts

class HelpSupportScreen extends StatefulWidget {
  // It's good practice for public widgets to have a const constructor with a Key.
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late FlutterTts tts; // Declare as late to initialize in initState

  @override
  void initState() {
    super.initState();
    tts = FlutterTts(); // Initialize FlutterTts
    _initAndSpeakHelpText(); // Call method to set up TTS and speak
  }

  Future<void> _initAndSpeakHelpText() async {
    await tts.setLanguage("en-US");
    // Ensure speech stops if the widget is unmounted quickly after this
    // although for short phrases, it's less critical.
    if (mounted) { // Good practice to check mounted before performing UI actions or
                   // continuing async operations that depend on the widget being in the tree.
      await tts.speak(
          "Here are tips on using EchoPath. You can say things like 'What's near me?' or 'Start audio tour'");
    }
  }

  @override
  void dispose() {
    tts.stop(); // Stop any ongoing speech when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DO NOT call tts.speak() directly here in the build method.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Voice Help"), // Make title const
        backgroundColor: Colors.black, // Match Scaffold background
        foregroundColor: Colors.white, // Ensure back button and title are visible
      ),
      body: Center(
        child: Column(
          children: const [ // Make children const if all are const
            ListTile(
              title: Text("Quick Tips", style: TextStyle(color: Colors.white)),
              subtitle: Text("Use voice to explore", style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              title: Text("FAQs", style: TextStyle(color: Colors.white)),
              subtitle: Text("How to use voice commands", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}