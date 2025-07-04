import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'map_screen.dart'; // New GPS-enabled map screen

class LocationGuidanceScreen extends StatefulWidget {
  const LocationGuidanceScreen({super.key});

  @override
  State<LocationGuidanceScreen> createState() => _LocationGuidanceScreenState();
}

class _LocationGuidanceScreenState extends State<LocationGuidanceScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords.toLowerCase());

        if (_recognizedText.contains('continue') || _recognizedText.contains('next')) {
          _speech.stop();
          _goToMap();
        }
      });
    }
  }

  void _goToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Voice Command'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Location-Based Guidance',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Say "continue" to view nearby sites.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _startListening,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _isListening ? Colors.redAccent : Colors.blueAccent,
                  child: const Icon(Icons.mic, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(_recognizedText, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
