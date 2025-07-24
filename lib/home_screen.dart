import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:developer' as developer;

import "tour_discovery_screen.dart";
import "downloads_screen.dart";
import "help_and_support_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = [
    const TourDiscoveryScreen(),
    const DownloadsScreen(),
    const HelpAndSupportScreen(),
  ]; // Track current tab index

  late FlutterTts tts;
  late stt.SpeechToText speech;

  @override
  void initState() {
    super.initState();

    // Defer all heavy work until after first frame
    Future.microtask(() async {
      tts = FlutterTts();
      speech = stt.SpeechToText();

      await _initTts();
      await _initSpeechToText();
      await _speakGreeting();
    });
  }

  Future<void> _initTts() async {
    try {
      await tts.setLanguage("en-US");
    } catch (e) {
      developer.log("TTS Init Error: $e", name: 'TTS');
    }
  }

  Future<void> _initSpeechToText() async {
    try {
      bool available = await speech.initialize(
        onError:
            (val) => developer.log('STT Error: $val', name: 'SpeechToText'),
        onStatus:
            (val) => developer.log('STT Status: $val', name: 'SpeechToText'),
      );
      if (!available) {
        developer.log(
          'Speech recognition not available.',
          name: 'SpeechToText',
        );
      }
    } catch (e) {
      developer.log("STT Init Error: $e", name: 'SpeechToText');
    }
  }

  Future<void> _speakGreeting() async {
    if (mounted) {
      try {
        await tts.speak("Welcome to EchoPath. What would you like to do?");
      } catch (e) {
        developer.log("TTS Speak Error: $e", name: 'TTS');
      }
    }
  }

  @override
  void dispose() {
    tts.stop();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue ,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        iconSize: 24,
        onTap:_onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help & Support',
          ),
        ],       
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
