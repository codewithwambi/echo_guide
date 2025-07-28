import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

import "tour_discovery_screen.dart";
import "downloads_screen.dart";
import "help_and_support_screen.dart";
import "screens/map_screen.dart";
import "services/voice_navigation_service.dart";
import "services/audio_manager_service.dart";
import "services/screen_transition_manager.dart";

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
    debugPrint('Home screen handling navigation to: $screen');
    // Use screen transition manager for smooth navigation
    _screenTransitionManager.handleVoiceNavigation(screen).then((_) {
      // Update UI after transition
      switch (screen) {
        case 'home':
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(0);
          }
          break;
        case 'map':
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(1);
          }
          break;
        case 'discover':
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(2);
          }
          break;
        case 'downloads':
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(3);
          }
          break;
        case 'help':
          debugPrint('Setting tab to help (index 4)');
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(4);
          }
          break;
      }
    });
  }

  Future<void> _speakTabInfo(int index) async {
    String message;
    switch (index) {
      case 0:
        message =
            "Home - Navigation hub. Say 'go to map' for location tracking, 'go to discover' for tours, 'go to downloads' for offline content, 'go to help' for assistance.";
        break;
      case 1:
        message =
            "Map - Interactive exploration. Say 'tell me about my surroundings' to describe area, 'what are the great places here' to discover places, 'what facilities are nearby' for facilities.";
        break;
      case 2:
        message =
            "Discover - Tour exploration. Say 'find tours' to search, 'start tour' followed by tour name, 'describe tour' for details.";
        break;
      case 3:
        message =
            "Downloads - Offline content. Say 'play tour' followed by tour name, 'stop tour' to pause, 'download all' to get all tours.";
        break;
      case 4:
        message =
            "Assistance - Help and support. Say 'read all topics' for commands, 'go back' to return, 'help' for assistance.";
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
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.tour), label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Help&Support',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late FlutterTts tts;
  late stt.SpeechToText speech;
  final VoiceNavigationService _voiceNavigationService =
      VoiceNavigationService();
  final AudioManagerService _audioManagerService = AudioManagerService();
  final ScreenTransitionManager _screenTransitionManager =
      ScreenTransitionManager();

  StreamSubscription<String>? _voiceStatusSubscription;
  StreamSubscription<String>? _audioStatusSubscription;
  StreamSubscription<String>? _transitionStatusSubscription;
  StreamSubscription<String>? _navigationCommandSubscription;
  StreamSubscription<String>? _homeCommandSubscription;
  StreamSubscription<String>? _screenNavigationSubscription;

  bool _isListening = false;
  String _voiceStatus = 'Initializing...';
  bool _isNarrating = false;

  // Enhanced blind user features
  String _currentNarrationMode = 'detailed';
  double _narrationSpeed = 0.8;
  final List<String> _recentlyMentionedFeatures = [];
  final int _maxRecentlyMentioned = 5;

  // Audio isolation management
  bool _isHomeScreenActive = true;
  bool _isAudioIsolated = false;
  Timer? _audioIsolationTimer;
  final Duration _audioIsolationDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize TTS and speech recognition
      tts = FlutterTts();
      speech = stt.SpeechToText();

      // Configure TTS for optimal blind user experience
      await _configureTTSForBlindUsers();

      // Register with audio manager for HOME SCREEN ONLY
      _audioManagerService.registerScreen('home', tts, speech);

      // Voice navigation is already initialized globally in main.dart
      setState(() {
        _voiceStatus = 'Global voice navigation active';
        _isListening = true;
      });

      // Listen to voice status updates
      _voiceStatusSubscription = _voiceNavigationService.voiceStatusStream
          .listen((status) {
            setState(() {
              // Only show positive status messages, filter out errors
              if (!status.toLowerCase().contains('error') &&
                  !status.toLowerCase().contains('failed') &&
                  !status.toLowerCase().contains('busy') &&
                  !status.toLowerCase().contains('timeout')) {
                _voiceStatus = status;
              }
              if (status.startsWith('listening_started')) {
                _isListening = true;
              } else if (status.startsWith('listening_stopped')) {
                _isListening = false;
              }
            });
          });

      // Listen to audio status updates with enhanced isolation
      _audioStatusSubscription = _audioManagerService.audioStatusStream.listen((
        status,
      ) {
        debugPrint('Home screen audio status: $status');
        _handleAudioStatusUpdate(status);
      });

      // Listen to transition status updates
      _transitionStatusSubscription = _screenTransitionManager
          .transitionStatusStream
          .listen((status) {
            debugPrint('Home screen transition status: $status');
          });

      // Listen to navigation commands
      _navigationCommandSubscription = _voiceNavigationService
          .navigationCommandStream
          .listen((command) {
            debugPrint('Home screen navigation command: $command');
          });

      // Listen to home-specific voice commands
      _homeCommandSubscription = _voiceNavigationService.homeCommandStream
          .listen((command) {
            _handleHomeVoiceCommand(command);
          });

      // Listen to screen navigation commands
      _screenNavigationSubscription = _voiceNavigationService
          .screenNavigationStream
          .listen((screen) {
            _handleScreenNavigation(screen);
          });

      // Listen to tab navigation commands
      _voiceNavigationService.homeCommandStream.listen((command) {
        _handleTabNavigationCommand(command);
      });

      // Activate home screen audio ONLY
      await _audioManagerService.activateScreenAudio('home');
      await _screenTransitionManager.navigateToScreen('home');

      // Start enhanced welcome narration for blind users
      await _startEnhancedWelcomeNarration();
    } catch (e) {
      debugPrint('Error initializing home screen services: $e');
      setState(() {
        _voiceStatus = 'Voice navigation ready';
      });
    }
  }

  // Configure TTS for optimal blind user experience
  Future<void> _configureTTSForBlindUsers() async {
    await tts.setLanguage("en-US");
    await tts.setPitch(1.0);
    await tts.setSpeechRate(_narrationSpeed);
    await tts.setVolume(1.0);

    // Use default voice instead of specific voice name to avoid configuration errors
    try {
      // Get available voices and use the first English voice
      final voices = await tts.getVoices;
      if (voices != null) {
        for (var voice in voices) {
          if (voice['locale'] == 'en-US') {
            await tts.setVoice(voice);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error setting TTS voice, using default: $e');
      // Continue with default voice if specific voice fails
    }
  }

  // Handle audio status updates with isolation management
  void _handleAudioStatusUpdate(String status) {
    if (status.startsWith('activated:home')) {
      _isHomeScreenActive = true;
      _isAudioIsolated = true;
      _audioIsolationTimer?.cancel();
      debugPrint('Home screen audio activated and isolated');
    } else if (status.startsWith('deactivated:home')) {
      _isHomeScreenActive = false;
      _isAudioIsolated = false;
      debugPrint('Home screen audio deactivated');
    } else if (status.startsWith('blocked:home')) {
      // Another screen is trying to speak, ensure home screen audio is isolated
      _ensureHomeScreenAudioIsolation();
    } else if (status.startsWith('transitioning:')) {
      // Screen transition in progress, prepare for audio isolation
      _prepareAudioIsolation();
    }
  }

  // Ensure home screen audio is properly isolated
  void _ensureHomeScreenAudioIsolation() {
    if (_isHomeScreenActive && !_isAudioIsolated) {
      _audioIsolationTimer?.cancel();
      _audioIsolationTimer = Timer(_audioIsolationDelay, () {
        // Add a small delay to prevent rapid calls
        Future.delayed(const Duration(milliseconds: 100), () {
          _forceHomeScreenAudioIsolation();
        });
      });
    }
  }

  // Prepare audio isolation during transitions
  void _prepareAudioIsolation() {
    _audioIsolationTimer?.cancel();
    _audioIsolationTimer = Timer(_audioIsolationDelay, () {
      if (_isHomeScreenActive) {
        _forceHomeScreenAudioIsolation();
      }
    });
  }

  // Force home screen audio isolation
  Future<void> _forceHomeScreenAudioIsolation() async {
    // Prevent rapid calls to audio isolation
    if (_isAudioIsolated) {
      debugPrint('Audio isolation already active, skipping');
      return;
    }

    try {
      // Stop any ongoing TTS from other screens
      await _audioManagerService.stopAllAudio();

      // Small delay to ensure complete audio isolation
      await Future.delayed(const Duration(milliseconds: 200));

      // Reactivate home screen audio
      await _audioManagerService.activateScreenAudio('home');

      _isAudioIsolated = true;
      debugPrint('Home screen audio isolation enforced');
    } catch (e) {
      debugPrint('Error enforcing home screen audio isolation: $e');
    }
  }

  // Enhanced welcome narration specifically for blind users
  Future<void> _startEnhancedWelcomeNarration() async {
    setState(() {
      _isNarrating = true;
    });

    // Ensure audio isolation before speaking
    _ensureHomeScreenAudioIsolation();

    String welcomeMessage = """
    Welcome to EchoPath, your voice-powered navigation companion designed for seamless accessibility. 
    You're now on the home screen, your central command center for exploring the app. 
    
    Here's what you can do from here:
    
    Global Navigation Commands:
    - Say 'go to map' to explore your surroundings and find nearby places with detailed descriptions
    - Say 'go to discover' to browse available tours and attractions with immersive narration
    - Say 'go to downloads' to access offline content and saved tours for offline use
    - Say 'go to help' for comprehensive assistance and support
    
    Alternative Navigation Phrases:
    - Say 'take me to map', 'open discover', 'show downloads', or 'access help'
    - Say 'I want to explore', 'show me tours', 'my offline content', or 'I need help'
    - Say 'where am I', 'find attractions', 'saved content', or 'support'
    
    Home screen specific commands:
    - Say 'describe home screen' for a detailed overview of this screen
    - Say 'what can I do' to hear all available options
    - Say 'navigation commands' to hear all available navigation options
    - Say 'available screens' to learn about each screen's features
    - Say 'repeat instructions' to hear these instructions again
    - Say 'adjust speech speed' to change how fast I speak
    - Say 'recent features' to hear recently mentioned options
    
    Voice control:
    - Say 'stop' to pause any narration
    - Say 'continue' to resume narration
    - Say 'speak faster' or 'speak slower' to adjust speech speed
    
    What would you like to explore first? I'm here to guide you through every step of your journey.
    """;

    await _audioManagerService.speakIfActive('home', welcomeMessage);

    setState(() {
      _isNarrating = false;
    });
  }

  // Add feature to recently mentioned list
  void _addToRecentlyMentioned(String feature) {
    _recentlyMentionedFeatures.remove(feature); // Remove if already exists
    _recentlyMentionedFeatures.insert(0, feature); // Add to beginning

    if (_recentlyMentionedFeatures.length > _maxRecentlyMentioned) {
      _recentlyMentionedFeatures.removeLast();
    }
  }

  // Get recently mentioned features
  List<String> getRecentlyMentionedFeatures() {
    return List.from(_recentlyMentionedFeatures);
  }

  // Adjust narration speed
  void _adjustNarrationSpeed(double speed) {
    _narrationSpeed = speed.clamp(0.5, 1.5);
    tts.setSpeechRate(_narrationSpeed);
  }

  // Toggle narration mode
  void _toggleNarrationMode() {
    switch (_currentNarrationMode) {
      case 'brief':
        _currentNarrationMode = 'detailed';
        break;
      case 'detailed':
        _currentNarrationMode = 'immersive';
        break;
      case 'immersive':
        _currentNarrationMode = 'brief';
        break;
    }
  }

  @override
  void dispose() {
    _voiceStatusSubscription?.cancel();
    _audioStatusSubscription?.cancel();
    _transitionStatusSubscription?.cancel();
    _navigationCommandSubscription?.cancel();
    _homeCommandSubscription?.cancel();
    _audioIsolationTimer?.cancel();
    _audioManagerService.unregisterScreen('home');
    super.dispose();
  }

  void _onTabChanged(int index) {
    debugPrint('Home screen: Tab changed to index $index');
    setState(() {
      _selectedIndex = index;
    });

    // Let AppScaffold handle the navigation, don't call screen transition manager here
    // This prevents conflicts between AppScaffold and home screen navigation
  }

  // Enhanced navigation method with descriptive feedback for blind users
  Future<void> _navigateToScreen(String screen) async {
    try {
      debugPrint('Home screen: Navigating to $screen');

      // Ensure home screen audio is isolated before navigation
      _ensureHomeScreenAudioIsolation();

      String feedback = "";
      switch (screen) {
        case 'map':
          feedback = """
          Taking you to the interactive map screen. 
          Here you can explore your surroundings with comprehensive voice guidance. 
          I'll describe nearby places, provide distance information, and guide you through navigation. 
          Say 'describe surroundings' for immersive area descriptions, 'navigate to' followed by a place name for directions, 
          or ask about specific categories like restaurants, hotels, or emergency services.
          """;
          _addToRecentlyMentioned('Map exploration');
          break;
        case 'discover':
          feedback = """
          Opening the tour discovery section. 
          Browse through amazing tours and attractions with detailed descriptions. 
          I'll help you find tours based on your interests, provide detailed information about each destination, 
          and guide you through the booking process. Say 'find tours' to search, 'describe tour' for details, 
          or 'start tour' to begin your adventure.
          """;
          _addToRecentlyMentioned('Tour discovery');
          break;
        case 'downloads':
          feedback = """
          Accessing your downloads section. 
          Here you can find offline content, saved tours, and audio guides for use without internet. 
          I'll help you manage your downloads, play offline tours, and organize your content. 
          Say 'play tour' followed by tour name, 'download all' to get all tours, or 'show downloads' to see what you have.
          """;
          _addToRecentlyMentioned('Downloads management');
          break;
        case 'help':
          feedback = """
          Opening the help and support section. 
          Get comprehensive assistance, learn about all features, and find answers to your questions. 
          I'll guide you through tutorials, explain voice commands, and provide troubleshooting help. 
          Say 'read all topics' for complete guidance, 'help with navigation' for specific assistance, 
          or 'go back' to return to the main menu.
          """;
          _addToRecentlyMentioned('Help and support');
          break;
        case 'home':
          feedback = """
          You're already on the home screen. 
          This is your central navigation hub where you can access all main sections of the app. 
          From here, you can explore maps, discover tours, manage downloads, and get help. 
          Say 'what can I do' to hear all available options, or choose a destination to explore.
          """;
          break;
      }

      // Ensure audio isolation before speaking
      await _forceHomeScreenAudioIsolation();
      await _audioManagerService.speakIfActive('home', feedback);

      // Let AppScaffold handle the actual navigation, don't call screen transition manager here
      // This prevents conflicts between AppScaffold and home screen navigation
    } catch (e) {
      debugPrint('Error navigating to screen $screen: $e');
      await _audioManagerService.speakIfActive(
        'home',
        "I encountered an issue with navigation. Please try again, or say 'help' for assistance.",
      );
    }
  }

  // Handle screen navigation from voice commands
  void _handleScreenNavigation(String screen) {
    debugPrint('Home screen handling navigation to: $screen');
    // Use enhanced screen transition manager for smooth navigation
    _screenTransitionManager.handleVoiceNavigationEnhanced(screen).then((_) {
      // Update UI after transition
      switch (screen) {
        case 'home':
          _onTabChanged(0);
          break;
        case 'map':
          _onTabChanged(1);
          break;
        case 'discover':
          _onTabChanged(2);
          break;
        case 'downloads':
          _onTabChanged(3);
          break;
        case 'help':
          debugPrint('Setting tab to help (index 4)');
          _onTabChanged(4);
          break;
      }
    });
  }

  // Enhanced voice command handler with comprehensive blind user support
  Future<void> _handleHomeVoiceCommand(String command) async {
    debugPrint('🎤 Home voice command received: $command');

    // Ensure audio isolation before processing any command
    _ensureHomeScreenAudioIsolation();

    // Enhanced navigation commands with natural language support - use global voice navigation
    if (command.contains('go to map') ||
        command.contains('map') ||
        command.contains('explore') ||
        command.contains('surroundings') ||
        command.contains('location') ||
        command.contains('where am i') ||
        command.contains('take me to map') ||
        command.contains('open map') ||
        command.contains('show map') ||
        command.contains('i want to explore')) {
      // Use global voice navigation service for seamless navigation
      await _voiceNavigationService.navigateGlobally('map');
    } else if (command.contains('go to discover') ||
        command.contains('discover') ||
        command.contains('tours') ||
        command.contains('attractions') ||
        command.contains('places to visit') ||
        command.contains('what to see') ||
        command.contains('take me to discover') ||
        command.contains('open discover') ||
        command.contains('show discover') ||
        command.contains('show me tours') ||
        command.contains('find attractions')) {
      await _voiceNavigationService.navigateGlobally('discover');
    } else if (command.contains('go to downloads') ||
        command.contains('downloads') ||
        command.contains('offline') ||
        command.contains('saved') ||
        command.contains('library') ||
        command.contains('take me to downloads') ||
        command.contains('open downloads') ||
        command.contains('show downloads') ||
        command.contains('my offline content') ||
        command.contains('saved content')) {
      await _voiceNavigationService.navigateGlobally('downloads');
    } else if (command.contains('go to help') ||
        command.contains('help') ||
        command.contains('support') ||
        command.contains('assistance') ||
        command.contains('take me to help') ||
        command.contains('open help') ||
        command.contains('show help') ||
        command.contains('access help') ||
        command.contains('i need help')) {
      await _voiceNavigationService.navigateGlobally('help');
    } else if (command.contains('go home') ||
        command.contains('home') ||
        command.contains('main menu') ||
        command.contains('dashboard') ||
        command.contains('take me home') ||
        command.contains('return home') ||
        command.contains('main menu') ||
        command.contains('return to main')) {
      await _voiceNavigationService.navigateGlobally('home');
    }
    // Enhanced blind user specific commands
    else if (command.contains('describe home screen') ||
        command.contains('what is home screen') ||
        command.contains('home screen overview')) {
      await _describeHomeScreen();
    } else if (command.contains('what can i do') ||
        command.contains('available options') ||
        command.contains('show options') ||
        command.contains('list features')) {
      await _describeAvailableOptions();
    } else if (command.contains('repeat instructions') ||
        command.contains('repeat') ||
        command.contains('say again')) {
      await _startEnhancedWelcomeNarration();
    } else if (command.contains('speak faster') ||
        command.contains('increase speed')) {
      _adjustNarrationSpeed(_narrationSpeed + 0.1);
      await _audioManagerService.speakIfActive(
        'home',
        'Speech speed increased',
      );
    } else if (command.contains('speak slower') ||
        command.contains('decrease speed')) {
      _adjustNarrationSpeed(_narrationSpeed - 0.1);
      await _audioManagerService.speakIfActive(
        'home',
        'Speech speed decreased',
      );
    } else if (command.contains('adjust speech speed') ||
        command.contains('change speed')) {
      await _audioManagerService.speakIfActive(
        'home',
        'Say "speak faster" to increase speed or "speak slower" to decrease speed.',
      );
    } else if (command.contains('recent features') ||
        command.contains('recently mentioned') ||
        command.contains('last mentioned')) {
      await _narrateRecentFeatures();
    } else if (command.contains('navigation commands') ||
        command.contains('global commands') ||
        command.contains('available commands') ||
        command.contains('voice commands')) {
      await _narrateGlobalNavigationCommands();
    } else if (command.contains('screen options') ||
        command.contains('available screens') ||
        command.contains('what screens') ||
        command.contains('which screens')) {
      await _narrateAvailableScreens();
    } else if (command.contains('change narration mode') ||
        command.contains('toggle narration')) {
      _toggleNarrationMode();
      await _audioManagerService.speakIfActive(
        'home',
        'Narration mode changed to $_currentNarrationMode',
      );
    } else if (command.contains('stop') ||
        command.contains('pause') ||
        command.contains('quiet')) {
      await tts.stop();
      await _audioManagerService.speakIfActive('home', 'Narration paused');
    } else if (command.contains('continue') || command.contains('resume')) {
      await _audioManagerService.speakIfActive(
        'home',
        'Narration resumed. What would you like to explore?',
      );
    }
    // Handle unknown commands with helpful suggestions
    else {
      await _provideHelpfulResponse(command);
    }
  }

  // Handle tab navigation commands from global voice navigation
  void _handleTabNavigationCommand(String command) {
    debugPrint('🎤 Tab navigation command received: $command');

    switch (command) {
      case 'switch_to_home_tab':
        setState(() => _selectedIndex = 0);
        break;
      case 'switch_to_map_tab':
        setState(() => _selectedIndex = 1);
        break;
      case 'switch_to_discover_tab':
        setState(() => _selectedIndex = 2);
        break;
      case 'switch_to_downloads_tab':
        setState(() => _selectedIndex = 3);
        break;
      case 'switch_to_help_tab':
        setState(() => _selectedIndex = 4);
        break;
    }
  }

  // Describe home screen in detail for blind users
  Future<void> _describeHomeScreen() async {
    await _forceHomeScreenAudioIsolation();

    String description = """
    You're on the EchoPath home screen, your central command center. 
    This screen serves as the main navigation hub for the entire application. 
    
    Current screen features:
    - Navigation menu with 5 main sections: Home, Map, Discover, Downloads, and Help
    - Voice command interface that responds to natural language
    - Accessibility features optimized for blind users
    - Real-time voice feedback and guidance
    
    Available sections:
    1. Home (current): Your central hub and command center
    2. Map: Interactive exploration with location-based services
    3. Discover: Tour and attraction discovery with detailed descriptions
    4. Downloads: Offline content management and playback
    5. Help: Comprehensive assistance and support
    
    Voice commands are active and ready. Say 'what can I do' to hear all available options.
    """;

    await _audioManagerService.speakIfActive('home', description);
  }

  // Describe all available options
  Future<void> _describeAvailableOptions() async {
    await _forceHomeScreenAudioIsolation();

    String options = """
    Here are all the things you can do from the home screen:
    
    Global Navigation Commands:
    - 'Go to map' - Explore your surroundings and find nearby places
    - 'Go to discover' - Browse tours and attractions
    - 'Go to downloads' - Access offline content and saved tours
    - 'Go to help' - Get assistance and support
    
    Alternative Navigation Phrases:
    - 'Take me to map', 'Open map', 'Show map', 'I want to explore'
    - 'Take me to discover', 'Open discover', 'Show me tours', 'Find attractions'
    - 'Take me to downloads', 'Open downloads', 'My offline content', 'Saved content'
    - 'Take me to help', 'Open help', 'Access help', 'I need help'
    - 'Take me home', 'Return home', 'Main menu', 'Return to main'
    
    Home screen specific commands:
    - 'Describe home screen' - Get a detailed overview of this screen
    - 'What can I do' - Hear all available options (this command)
    - 'Navigation commands' - Hear all available navigation options
    - 'Available screens' - Learn about each screen's features
    - 'Repeat instructions' - Hear the welcome message again
    - 'Speak faster' or 'Speak slower' - Adjust speech speed
    - 'Recent features' - Hear recently mentioned options
    - 'Change narration mode' - Switch between brief, detailed, and immersive modes
    
    Voice control:
    - 'Stop' or 'Pause' - Stop current narration
    - 'Continue' or 'Resume' - Resume narration
    
    Each section has its own specialized voice commands. I'll guide you through them when you navigate to different screens.
    """;

    await _audioManagerService.speakIfActive('home', options);
  }

  // Narrate recent features
  Future<void> _narrateRecentFeatures() async {
    await _forceHomeScreenAudioIsolation();

    List<String> recentFeatures = getRecentlyMentionedFeatures();

    if (recentFeatures.isNotEmpty) {
      String narration = 'Recently mentioned features: ';
      narration += recentFeatures.join(', ');
      narration +=
          '. Say "go to" followed by any feature name to navigate there.';

      await _audioManagerService.speakIfActive('home', narration);
    } else {
      await _audioManagerService.speakIfActive(
        'home',
        'No features have been mentioned recently. Try saying "what can I do" to explore available options.',
      );
    }
  }

  // Narrate global navigation commands available from home screen
  Future<void> _narrateGlobalNavigationCommands() async {
    await _forceHomeScreenAudioIsolation();

    String navigationCommands = """
    Here are the global navigation commands you can use from the home screen:
    
    Primary Navigation Commands:
    - 'Go to map' or 'Map' - Navigate to the interactive map screen for location exploration
    - 'Go to discover' or 'Discover' - Navigate to tour discovery and attraction browsing
    - 'Go to downloads' or 'Downloads' - Navigate to offline content and saved tours
    - 'Go to help' or 'Help' - Navigate to assistance and support section
    - 'Go home' or 'Home' - Return to this home screen (you're already here)
    
    Alternative Navigation Phrases:
    - 'Take me to map' - Navigate to map screen
    - 'Open discover' - Open tour discovery
    - 'Show downloads' - Show offline content
    - 'Access help' - Access support section
    - 'Return home' - Return to home screen
    
    Natural Language Navigation:
    - 'I want to explore' - Takes you to the map screen
    - 'Show me tours' - Takes you to discover section
    - 'My offline content' - Takes you to downloads
    - 'I need help' - Takes you to help section
    - 'Main menu' - Returns to home screen
    
    Context-Based Navigation:
    - 'Where am I' - Takes you to map for location information
    - 'Find attractions' - Takes you to discover for tour browsing
    - 'Saved content' - Takes you to downloads for offline access
    - 'Support' - Takes you to help for assistance
    
    Just say any of these commands and I'll navigate you to the appropriate screen.
    """;

    await _audioManagerService.speakIfActive('home', navigationCommands);
  }

  // Narrate available screens with detailed descriptions
  Future<void> _narrateAvailableScreens() async {
    await _forceHomeScreenAudioIsolation();

    String availableScreens = """
    Here are all the screens available in EchoPath:
    
    1. Home Screen (Current):
       - Your central navigation hub and command center
       - Access all main sections of the app
       - Voice command interface for seamless navigation
       - Quick access to all features
    
    2. Map Screen:
       - Interactive location-based exploration
       - Real-time surroundings description
       - Find nearby places, restaurants, hotels, and services
       - Navigation assistance and distance information
       - Emergency services and safety information
       - Voice-guided exploration for blind users
    
    3. Discover Screen:
       - Browse available tours and attractions
       - Detailed tour descriptions and information
       - Search for specific destinations
       - Tour booking and reservation features
       - Immersive narration of tour experiences
       - Voice-guided tour discovery
    
    4. Downloads Screen:
       - Access offline content and saved tours
       - Play downloaded audio guides
       - Manage offline content library
       - Ambient sound playback
       - Offline tour navigation
       - Voice-controlled content management
    
    5. Help & Support Screen:
       - Comprehensive assistance and tutorials
       - Voice command help and guidance
       - Troubleshooting and FAQ
       - Accessibility features explanation
       - User guide and tips
       - Contact support information
    
    Each screen has its own specialized voice commands and features. Say 'navigation commands' to hear how to move between screens.
    """;

    await _audioManagerService.speakIfActive('home', availableScreens);
  }

  // Provide helpful response for unknown commands
  Future<void> _provideHelpfulResponse(String command) async {
    await _forceHomeScreenAudioIsolation();

    String response = """
    I didn't understand that command. 
    
    Here are some things you can try:
    - Say 'go to map' to explore your surroundings
    - Say 'go to discover' to find tours and attractions
    - Say 'go to downloads' to access offline content
    - Say 'go to help' for assistance
    - Say 'what can I do' to hear all available options
    - Say 'describe home screen' for a detailed overview
    - Say 'navigation commands' to hear all available navigation options
    - Say 'available screens' to learn about each screen's features
    
    You can also say 'repeat instructions' to hear the welcome message again.
    """;

    await _audioManagerService.speakIfActive('home', response);
  }

  // Optimized navigation card builder to prevent overflow
  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: _selectedIndex,
      onTabChanged: _onTabChanged,
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          // Enhanced Home tab content for blind users
          Scaffold(
            key: const ValueKey('home_content'),
            backgroundColor: Colors.grey[50],
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Enhanced header with accessibility features
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  _isListening ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isListening
                                      ? 'Voice Active'
                                      : 'Voice Inactive',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _voiceStatus,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              if (_isNarrating) {
                                await _audioManagerService.stopAllAudio();
                                setState(() => _isNarrating = false);
                              } else {
                                await _startEnhancedWelcomeNarration();
                              }
                            },
                            icon: Icon(
                              _isNarrating ? Icons.pause : Icons.play_arrow,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App title
                    const Text(
                      "EchoPath",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your Navigation Companion",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Navigation cards with flexible layout to prevent overflow
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2, // Slightly taller cards
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildNavigationCard(
                                  title: "Map",
                                  subtitle: "Explore surroundings",
                                  icon: Icons.explore,
                                  color: Colors.green,
                                  onTap:
                                      () async =>
                                          await _navigateToScreen('map'),
                                ),
                                _buildNavigationCard(
                                  title: "Tours",
                                  subtitle: "Discover tours",
                                  icon: Icons.tour,
                                  color: Colors.orange,
                                  onTap:
                                      () async =>
                                          await _navigateToScreen('discover'),
                                ),
                                _buildNavigationCard(
                                  title: "Downloads",
                                  subtitle: "Offline content",
                                  icon: Icons.library_books,
                                  color: Colors.purple,
                                  onTap:
                                      () async =>
                                          await _navigateToScreen('downloads'),
                                ),
                                _buildNavigationCard(
                                  title: "Help",
                                  subtitle: "Get assistance",
                                  icon: Icons.support_agent,
                                  color: Colors.red,
                                  onTap:
                                      () async =>
                                          await _navigateToScreen('help'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Simple voice commands panel with compact design
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mic,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Voice Commands",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Try: 'explore surroundings', 'discover tours', 'my downloads', or 'help'",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Other screens with unique keys to prevent hero tag conflicts
          const MapScreen(key: ValueKey('map_screen')),
          const TourDiscoveryScreen(key: ValueKey('discover_screen')),
          const DownloadsScreen(key: ValueKey('downloads_screen')),
          const HelpAndSupportScreen(key: ValueKey('help_screen')),
        ],
      ),
    );
  }
}
