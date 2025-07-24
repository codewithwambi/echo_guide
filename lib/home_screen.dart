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
      print('AppScaffold audio control event: $event');
    });

    // Listen to screen activation events
    _screenActivationSubscription = _audioManagerService.screenActivationStream
        .listen((screenId) {
          print('Screen activated: $screenId');
        });

    // Listen to transition events
    _transitionSubscription = _screenTransitionManager.transitionStream.listen((
      event,
    ) {
      print('Transition event: $event');
    });
  }

  void _handleScreenNavigation(String screen) {
    print('Home screen handling navigation to: $screen');
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
          print('Setting tab to help (index 4)');
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

  // Enhanced voice interaction state
  bool _isVoiceInitialized = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _voiceStatus = 'Initializing...';

  // Home screen specific voice command state
  bool _isHomeVoiceEnabled = true;
  bool _isWelcomeMessageEnabled = true;
  bool _isQuickAccessEnabled = true;
  String _lastSpokenFeature = '';
  int _commandCount = 0;

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

      // Initialize TTS with enhanced handlers
      await _initTTS();

      // Initialize speech recognition
      await _initSpeechToText();

      // Register with audio manager
      _audioManagerService.registerScreen('home', tts, speech);

      // Initialize voice navigation
      _isVoiceInitialized = await _voiceNavigationService.initialize();
      if (_isVoiceInitialized) {
        await _voiceNavigationService.startContinuousListening();
        setState(() {
          _voiceStatus = 'Voice navigation ready';
          _isListening = true;
        });
      }

      // Listen to voice status updates
      _voiceStatusSubscription = _voiceNavigationService.voiceStatusStream
          .listen((status) {
            setState(() {
              _voiceStatus = status;
              if (status.startsWith('listening_started')) {
                _isListening = true;
              } else if (status.startsWith('listening_stopped')) {
                _isListening = false;
              }
            });
          });

      // Listen to audio status updates
      _audioStatusSubscription = _audioManagerService.audioStatusStream.listen((
        status,
      ) {
        print('Home screen audio status: $status');
      });

      // Listen to transition status updates
      _transitionStatusSubscription = _screenTransitionManager
          .transitionStatusStream
          .listen((status) {
            print('Home screen transition status: $status');
          });

      // Listen to navigation commands
      _navigationCommandSubscription = _voiceNavigationService
          .navigationCommandStream
          .listen((command) {
            print('Home screen navigation command: $command');
          });

      // Listen to home-specific voice commands
      _homeCommandSubscription = _voiceNavigationService.homeCommandStream
          .listen((command) {
            _handleHomeVoiceCommand(command);
          });

      // Activate home screen audio
      await _audioManagerService.activateScreenAudio('home');
      await _screenTransitionManager.navigateToScreen('home');

      // Welcome message with automatic listening
      Future.delayed(const Duration(seconds: 2), () {
        _speakWelcomeMessage();
      });
    } catch (e) {
      print('Error initializing home screen services: $e');
      setState(() {
        _voiceStatus = 'Error initializing voice navigation';
      });
    }
  }

  Future<void> _initTTS() async {
    try {
      await tts.setLanguage("en-US");
      await tts.setSpeechRate(0.5);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);

      // Set completion handler to automatically start listening
      tts.setCompletionHandler(() async {
        setState(() {
          _isSpeaking = false;
          _isProcessing = false;
        });
        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // let state update
        if (!_isListening && !_isSpeaking && !_isProcessing) {
          print("Starting listening after TTS");
          _startAutoListening();
        } else {
          print("Not starting listening. Conditions not met.");
        }
      });

      tts.setStartHandler(() {
        setState(() {
          _isSpeaking = true;
        });
      });

      tts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        setState(() {
          _isSpeaking = false;
        });
      });
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  Future<void> _initSpeechToText() async {
    try {
      _speechEnabled = await speech.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
          _handleSpeechError();
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      print('Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      print('Error initializing speech recognition: $e');
      _speechEnabled = false;
    }
    setState(() {});
  }

  void _handleSpeechError() {
    if (!_isSpeaking) {
      _speakAndWaitForResponse(
        "Sorry, I couldn't understand you clearly. Let me repeat the home options. "
        "Say 'welcome message' for app introduction, 'quick access' for navigation options, "
        "'voice settings' for configuration, 'status' for system info, or 'help' for assistance. "
        "For navigation, say 'go to' followed by map, discover, downloads, or help. "
        "Which option would you like?",
      );
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await tts.stop();
    }

    setState(() {
      _isProcessing = true;
      _isSpeaking = true;
    });

    try {
      await tts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
      setState(() {
        _isSpeaking = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _speakAndWaitForResponse(String text) async {
    await _speak(text);
    // The TTS completion handler will automatically start listening again
  }

  void _startAutoListening() {
    if (!_speechEnabled || _isProcessing || _isSpeaking || _isListening) {
      print(
        'Cannot start listening: speechEnabled=$_speechEnabled, processing=$_isProcessing, speaking=$_isSpeaking, listening=$_isListening',
      );
      return;
    }

    setState(() {
      _isListening = true;
      _isProcessing = false;
      _lastWords = '';
    });

    print('Starting to listen...');

    try {
      speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords.toLowerCase();
          });

          print('Recognized: ${result.recognizedWords}');

          if (result.finalResult) {
            print('Final result: ${result.recognizedWords}');

            if (_lastWords.trim().isEmpty) {
              _speakAndWaitForResponse(
                "Sorry, I didn't hear anything. Please try again. "
                "Say 'welcome message' for app introduction, 'quick access' for navigation options, "
                "'voice settings' for configuration, 'status' for system info, or 'help' for assistance. "
                "Which option would you like?",
              );
            } else {
              _processVoiceCommand(_lastWords);
            }
          }
        },
        listenFor: const Duration(seconds: 15), // Longer listening time
        pauseFor: const Duration(seconds: 3), // Pause before auto-ending
        partialResults: true,
        localeId: "en_US",
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
      );
    } catch (e) {
      print('Error starting listening: $e');
      setState(() {
        _isListening = false;
      });
      _speakAndWaitForResponse(
        "There was a problem starting the microphone. Please try again.",
      );
    }
  }

  void _stopListening() {
    if (_isListening) {
      speech.stop();
      setState(() {
        _isListening = false;
      });
      print('Stopped listening');
    }
  }

  void _processVoiceCommand(String command) {
    _stopListening();
    command = command.trim();
    print('Processing command: $command');

    // Limit command frequency to prevent spam
    if (_commandCount > 10) {
      _commandCount = 0;
      return;
    }
    _commandCount++;

    if (command.contains('welcome message') || command.contains('welcome')) {
      _handleWelcomeCommand();
    } else if (command.contains('quick access') || command.contains('quick')) {
      _handleQuickAccessCommand();
    } else if (command.contains('voice settings') ||
        command.contains('settings')) {
      _handleVoiceSettingsCommand();
    } else if (command.contains('status')) {
      _handleStatusCommand();
    } else if (command.contains('help')) {
      _handleHelpCommand();
    } else if (command.contains('go to')) {
      _handleNavigationCommand(command);
    } else {
      // Unknown command - provide helpful feedback
      _speakAndWaitForResponse(
        "I didn't understand that home command. Say 'welcome message' for app introduction, "
        "'quick access' for navigation options, 'voice settings' for configuration, "
        "'status' for system info, or 'help' for assistance. "
        "For navigation, say 'go to' followed by map, discover, downloads, or help.",
      );
    }
  }

  void _handleNavigationCommand(String command) {
    if (command.contains('home')) {
      _speakAndWaitForResponse("You are already on the home screen.");
    } else if (command.contains('map')) {
      _speakAndWaitForResponse(
        "Navigating to map screen for location tracking and voice-guided navigation.",
      );
      if (mounted) {
        setState(() => _selectedIndex = 1);
      }
    } else if (command.contains('discover')) {
      _speakAndWaitForResponse(
        "Navigating to discover screen to find tours and attractions.",
      );
      if (mounted) {
        setState(() => _selectedIndex = 2);
      }
    } else if (command.contains('downloads')) {
      _speakAndWaitForResponse(
        "Navigating to downloads screen to manage offline content.",
      );
      if (mounted) {
        setState(() => _selectedIndex = 3);
      }
    } else if (command.contains('help')) {
      _speakAndWaitForResponse(
        "Navigating to help and support screen for voice command assistance.",
      );
      if (mounted) {
        setState(() => _selectedIndex = 4);
      }
    } else {
      _speakAndWaitForResponse(
        "I didn't understand the navigation destination. Please say 'go to' followed by map, discover, downloads, or help.",
      );
    }
  }

  void _speakWelcomeMessage() {
    _speakAndWaitForResponse(
      "Welcome to EchoPath! Your voice-guided navigation companion. "
      "I'm here to help you explore the world around you with comprehensive audio guidance. "
      "You can navigate to different screens, discover tours, access offline content, and get help anytime. "
      "Each screen has its own voice commands for seamless interaction. "
      "Say 'quick access' for navigation options or 'help' for assistance. "
      "After I finish speaking, I'll automatically listen for your commands.",
    );
  }

  @override
  void dispose() {
    _voiceStatusSubscription?.cancel();
    _audioStatusSubscription?.cancel();
    _transitionStatusSubscription?.cancel();
    _navigationCommandSubscription?.cancel();
    _homeCommandSubscription?.cancel();
    _audioManagerService.unregisterScreen('home');
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Use screen transition manager for smooth navigation
    _screenTransitionManager.handleTabChange(index);
  }

  // Enhanced navigation method for seamless transitions from any screen
  Future<void> _navigateToScreen(String screen) async {
    try {
      // Use screen transition manager for seamless navigation
      await _screenTransitionManager.handleVoiceNavigation(screen);

      // Update tab index based on screen for UI consistency
      switch (screen) {
        case 'home':
          setState(() => _selectedIndex = 0);
          break;
        case 'map':
          setState(() => _selectedIndex = 1);
          break;
        case 'discover':
          setState(() => _selectedIndex = 2);
          break;
        case 'downloads':
          setState(() => _selectedIndex = 3);
          break;
        case 'help':
          setState(() => _selectedIndex = 4);
          break;
      }
    } catch (e) {
      print('Error navigating to screen $screen: $e');
      _speakAndWaitForResponse(
        "Sorry, there was an error navigating to $screen. Please try again.",
      );
    }
  }

  // Handle home-specific voice commands
  Future<void> _handleHomeVoiceCommand(String command) async {
    print('🎤 Home voice command received: $command');

    // Limit command frequency to prevent spam
    if (_commandCount > 10) {
      _commandCount = 0;
      return;
    }
    _commandCount++;

    if (command.startsWith('welcome')) {
      await _handleWelcomeCommand();
    } else if (command.startsWith('quick_access')) {
      await _handleQuickAccessCommand();
    } else if (command.startsWith('voice_settings')) {
      await _handleVoiceSettingsCommand();
    } else if (command.startsWith('status')) {
      await _handleStatusCommand();
    } else if (command.startsWith('help')) {
      await _handleHelpCommand();
    } else {
      // Unknown command - provide helpful feedback
      _speakAndWaitForResponse(
        "I didn't understand that home command. Say 'welcome message' for app introduction, "
        "'quick access' for navigation options, 'voice settings' for configuration, "
        "'status' for system info, or 'help' for assistance.",
      );
    }
  }

  // Home command handlers
  Future<void> _handleWelcomeCommand() async {
    _speakAndWaitForResponse(
      "Welcome to EchoPath! Your voice-guided navigation companion. "
      "I'm here to help you explore the world around you with comprehensive audio guidance. "
      "You can navigate to different screens, discover tours, access offline content, and get help anytime. "
      "Each screen has its own voice commands for seamless interaction. "
      "Say 'quick access' for navigation options or 'help' for assistance.",
    );
  }

  Future<void> _handleQuickAccessCommand() async {
    _speakAndWaitForResponse(
      "Quick access options: Say 'go to map' for location tracking and tour guide features, "
      "'go to discover' to find and start tours, 'go to downloads' to access your saved offline content, "
      "or 'go to help' for assistance. You can also say 'voice settings' to configure your voice preferences, "
      "'status' to check current system status, or 'help' for comprehensive command list.",
    );
  }

  Future<void> _handleVoiceSettingsCommand() async {
    _speakAndWaitForResponse(
      "Voice settings available. You can say 'stop listening' to pause voice recognition, "
      "'start listening' to resume, 'stop talking' to mute narration, 'resume talking' to continue narration. "
      "For navigation, say 'go to' followed by the screen name. Each screen has its own voice commands for enhanced interaction. "
      "Say 'help' anytime for available commands.",
    );
  }

  Future<void> _handleStatusCommand() async {
    String status = """
    Current system status:
    Voice recognition: ${_isListening ? 'Active' : 'Inactive'}
    Current screen: Home
    Navigation ready: ${_isVoiceInitialized ? 'Yes' : 'No'}
    Audio management: Active
    Screen transitions: Enabled
    
    Available features:
    - Voice-guided navigation between all screens
    - Location tracking and tour guide features
    - Tour discovery and audio tours
    - Offline content management
    - Comprehensive help and support
    """;

    _speakAndWaitForResponse(status);
  }

  Future<void> _handleHelpCommand() async {
    _speakAndWaitForResponse(
      "Home screen help. You can say 'welcome message' for app introduction, "
      "'quick access' for fast navigation options, 'voice settings' for voice configuration, "
      "'status' for system information, or 'help' to hear this message again. "
      "For navigation, say 'go to' followed by map, discover, downloads, or help. "
      "Each screen has its own voice commands for seamless interaction.",
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
          // Home tab content
          Column(
            children: [
              // Voice status indicator
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      _isListening
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isListening ? Colors.green : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color: _isListening ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isListening ? 'Listening...' : 'Ready to Listen',
                        style: TextStyle(
                          color: _isListening ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isListening && _lastWords.isNotEmpty)
                      Expanded(
                        child: Text(
                          'Heard: "$_lastWords"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Welcome to EchoPath!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FloatingActionButton.extended(
                        heroTag: 'speak_options',
                        onPressed: () async {
                          _speakAndWaitForResponse(
                            "Voice navigation available. Say 'go to map' for location tracking, "
                            "'go to discover' for tours, 'go to downloads' for saved content, "
                            "or 'go to help' for assistance. You can also say 'help' anytime for all available commands. "
                            "Only the active screen will have audio to ensure clear communication. "
                            "Smooth transitions are enabled for seamless navigation.",
                          );
                        },
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Voice Commands'),
                        backgroundColor: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton.extended(
                        heroTag: 'voice_map',
                        onPressed: () async {
                          _speakAndWaitForResponse(
                            "Navigating to Map screen for location tracking and voice-guided navigation.",
                          );
                          await _screenTransitionManager.navigateToScreen(
                            'map',
                            transitionMessage: "Switching to Map screen",
                          );
                          setState(() {
                            _selectedIndex = 1; // Map tab
                          });
                        },
                        icon: const Icon(Icons.map),
                        label: const Text("Go to Map"),
                        backgroundColor: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton.extended(
                        heroTag: 'voice_discover',
                        onPressed: () async {
                          _speakAndWaitForResponse(
                            "Navigating to Discover screen to find tours and attractions. "
                            "Audio player will be activated for seamless tour discovery.",
                          );

                          // Ensure map audio is deactivated before navigating to discover
                          await _audioManagerService.deactivateScreenAudio(
                            'map',
                          );

                          await _screenTransitionManager.navigateToScreen(
                            'discover',
                            transitionMessage:
                                "Switching to Discover screen with audio activation",
                          );
                          setState(() {
                            _selectedIndex = 2; // Discover tab
                          });
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text("Go to Discover"),
                        backgroundColor: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton.extended(
                        heroTag: 'voice_downloads',
                        onPressed: () async {
                          _speakAndWaitForResponse(
                            "Navigating to Downloads screen to manage offline content.",
                          );
                          await _screenTransitionManager.navigateToScreen(
                            'downloads',
                            transitionMessage: "Switching to Downloads screen",
                          );
                          setState(() {
                            _selectedIndex = 3; // Downloads tab
                          });
                        },
                        icon: const Icon(Icons.download),
                        label: const Text("Go to Downloads"),
                        backgroundColor: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton.extended(
                        heroTag: 'voice_help',
                        onPressed: () async {
                          _speakAndWaitForResponse(
                            "Navigating to Help and Support screen for voice command assistance.",
                          );
                          await _screenTransitionManager.navigateToScreen(
                            'help',
                            transitionMessage:
                                "Switching to Help and Support screen",
                          );
                          setState(() {
                            _selectedIndex = 4; // Help tab
                          });
                        },
                        icon: const Icon(Icons.help),
                        label: const Text("Go to Help"),
                        backgroundColor: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Map, Discover, Downloads, Help & Support tabs
          const MapScreen(),
          const TourDiscoveryScreen(),
          const DownloadsScreen(),
          const HelpAndSupportScreen(),
        ],
      ),
    );
  }
}
