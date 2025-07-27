import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import '../services/voice_navigation_service.dart';
import '../services/audio_manager_service.dart';
import '../services/screen_transition_manager.dart';

class AppScaffold extends StatefulWidget {
  final int selectedIndex;
  final Widget child;
  final Function(int)? onTabChanged;

  const AppScaffold({
    super.key,
    required this.selectedIndex,
    required this.child,
    this.onTabChanged,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late FlutterTts tts;
  final VoiceNavigationService _voiceNavigationService =
      VoiceNavigationService();
  final AudioManagerService _audioManagerService = AudioManagerService();
  final ScreenTransitionManager _screenTransitionManager =
      ScreenTransitionManager();

  StreamSubscription<String>? _screenNavigationSubscription;
  StreamSubscription<String>? _audioControlSubscription;
  StreamSubscription<String>? _screenActivationSubscription;
  StreamSubscription<String>? _transitionSubscription;

  @override
  void initState() {
    super.initState();
    tts = FlutterTts();
    _initializeVoiceNavigation();
  }

  Future<void> _initializeVoiceNavigation() async {
    // Listen to screen navigation commands
    _screenNavigationSubscription = _voiceNavigationService
        .screenNavigationStream
        .listen((screen) {
          _handleScreenNavigation(screen);
        });

    // Listen to audio control events
    _audioControlSubscription = _audioManagerService.audioControlStream.listen((
      event,
    ) {
      debugPrint('AppScaffold audio control event: $event');
    });

    // Listen to screen activation events
    _screenActivationSubscription = _audioManagerService.screenActivationStream
        .listen((screenId) {
          debugPrint('Screen activated: $screenId');
        });

    // Listen to transition events
    _transitionSubscription = _screenTransitionManager.transitionStream.listen((
      event,
    ) {
      debugPrint('Transition event: $event');
    });
  }

    void _handleScreenNavigation(String screen) {
    debugPrint('AppScaffold handling navigation to: $screen');
    
    // Use screen transition manager for smooth navigation
    _screenTransitionManager.handleVoiceNavigation(screen).then((_) {
      // Update UI after transition
      switch (screen) {
        case 'home':
          debugPrint('AppScaffold: Switching to home tab (index 0)');
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(0);
          }
          break;
        case 'map':
          debugPrint('AppScaffold: Switching to map tab (index 1)');
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(1);
          }
          break;
        case 'discover':
          debugPrint('AppScaffold: Switching to discover tab (index 2)');
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(2);
          }
          break;
        case 'downloads':
          debugPrint('AppScaffold: Switching to downloads tab (index 3)');
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(3);
          }
          break;
        case 'help':
          debugPrint('AppScaffold: Switching to help tab (index 4)');
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(4);
          }
          break;
        default:
          debugPrint('AppScaffold: Unknown screen: $screen, defaulting to home');
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(0);
          }
          break;
      }
    }).catchError((error) {
      debugPrint('AppScaffold: Error during navigation: $error');
    });
  }

  Future<void> _speakTabInfo(int index) async {
    String message;
    switch (index) {
      case 0:
        message =
            "Home. This is your main dashboard. You can access all features from here. Say 'go to map' for location tracking and tour guide features, 'go to discover' for tours, 'go to downloads' for offline content with audio playback, or 'go to help' for assistance. Navigate back and forth seamlessly between screens.";
        break;
      case 1:
        message =
            "Map. Interactive map with real-time location tracking and voice-guided tour narration. Say 'tell me about my surroundings', 'what are the great places here', 'what facilities are nearby', or 'give me local tips' for rich tour guide information. Use 'zoom in/out' or 'center map' for navigation.";
        break;
      case 2:
        message =
            "Discover. Find and start tours for nearby attractions using your location. Say 'find tours' to discover available tours or 'start tour' to begin exploring. Each screen's audio player becomes active when you visit it.";
        break;
      case 3:
        message =
            "Downloads. Listen to tours you have saved for offline use. Say 'play tour' followed by the tour name to start listening, 'stop tour' to pause, 'download all' to get available content, or 'delete downloads' to free space. Audio playback is available for downloaded tours.";
        break;
      case 4:
        message =
            "Help and Support. Get tips, FAQs, and voice command help. Say 'voice commands' to hear available commands, 'read all topics' for comprehensive help, or 'accessibility help' for special assistance. Say 'go back' to return to the previous screen.";
        break;
      default:
        message = "Tab selected.";
    }
    await tts.speak(message);
  }

  void _onItemTapped(int index) {
    _speakTabInfo(index);
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(index);
    }
  }

  @override
  void dispose() {
    _screenNavigationSubscription?.cancel();
    _audioControlSubscription?.cancel();
    _screenActivationSubscription?.cancel();
    _transitionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        iconSize: 24,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
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
}
