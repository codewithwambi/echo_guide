import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import FlutterTts

class HelpAndSupportScreen extends StatefulWidget {
  // It's good practice for public widgets to have a const constructor with a Key.
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  late FlutterTts tts; // Declare as late to initialize in initState

  @override
  void initState() {
    super.initState();
    tts = FlutterTts(); // Initialize FlutterTts
    _initAndSpeakHelpText(); // Call method to set up TTS and speak
  }

  Future<void> _initAndSpeakHelpText() async {
    await tts.setLanguage("en-US");
    // You might want to set other TTS parameters here, e.g., speed, pitch
    // await tts.setSpeechRate(0.5);
    // await tts.setPitch(1.0);

    // Ensure speech stops if the widget is unmounted quickly after this
    if (mounted) {
      await tts.speak(
          "Here are tips on using EchoPath. You can say things like 'What's near me?' or 'Start audio tour'");
    }
  }

  @override
  void dispose() {
    tts.stop(); // Stop any ongoing speech when the widget is disposed
    // Removed: tts.shutdown(); // This method is not defined for FlutterTts
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
        elevation: 0, // AppBar typically looks better with no shadow on dark themes
      ),
      body: const Center( // Can make Center const
        child: Column(
          children: [ // ListTiles are also const, so the whole column's children can be const
            ListTile(
              title: Text("Quick Tips", style: TextStyle(color: Colors.white)),
              subtitle: Text("Use voice to explore", style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              title: Text("FAQs", style: TextStyle(color: Colors.white)),
              subtitle: Text("How to use voice commands", style: TextStyle(color: Colors.grey)),
            ),
            // You can add more ListTiles or other widgets here for additional content.
          ],
        ),
      ),
    );
  }
}