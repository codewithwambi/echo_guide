import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'services/audio_manager_service.dart';
import 'services/screen_transition_manager.dart';
import 'services/voice_navigation_service.dart';
import 'package:vibration/vibration.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  late FlutterTts tts;
  late SpeechToText speech;
  late AudioManagerService _audioManagerService;
  late ScreenTransitionManager _screenTransitionManager;
  late VoiceNavigationService _voiceNavigationService;

  StreamSubscription? _audioControlSubscription;
  StreamSubscription? _screenActivationSubscription;
  StreamSubscription? _transitionSubscription;
  StreamSubscription? _helpCommandSubscription;
  StreamSubscription? _screenNavigationSubscription;

  // Help screen specific voice command state
  bool _isNarrating = false;
  int _currentTopicIndex = 0; // Track current topic for next functionality
  bool _isPaused = false; // Track pause state

  final List<Map<String, String>> _helpTopics = [
    {
      'title': 'Quick Navigation',
      'description':
          'Master seamless navigation between all app sections with voice commands',
      'commands':
          'Say "go to map" or "explore" for location services, "go to discover" or "show tours" for attractions, "go to downloads" or "my content" for offline access, "go to help" or "assistance" for support',
      'detailed_help':
          'Navigate effortlessly through the app using natural voice commands. From the home screen, you can access any section instantly. Use phrases like "take me to map", "open discover", "show downloads", or "access help". You can also use context-based commands like "I want to explore" for map, "show me tours" for discover, "my offline content" for downloads, or "I need help" for assistance. The app remembers your preferences and provides quick access to frequently used sections.',
    },
    {
      'title': 'Map Exploration',
      'description':
          'Discover and explore your surroundings with detailed location-based guidance',
      'commands':
          'Say "describe surroundings" for area overview, "find restaurants" for dining, "emergency services" for safety, "transportation" for travel options, "shopping" for amenities, "navigate to [place name]" for directions',
      'detailed_help':
          'The map screen provides comprehensive location-based exploration designed for accessibility. Get real-time descriptions of your surroundings, find nearby places by category, and receive navigation assistance. Use voice commands to explore different areas: ask for restaurants, hotels, hospitals, banks, shopping centers, and more. The app provides distance information, directional guidance, and safety alerts. For blind users, the map offers immersive narration with spatial awareness, movement detection, and detailed environmental descriptions. Say "describe surroundings" for a comprehensive area overview, or ask for specific categories like "find restaurants" or "emergency services".',
    },
    {
      'title': 'Tour Discovery',
      'description':
          'Find and experience fascinating tours with immersive audio narration',
      'commands':
          'Say "browse tours" to see available options, "tour one" through "tour four" to select, "start tour" to begin, "tour details" for information, "next attraction" to continue, "previous attraction" to go back',
      'detailed_help':
          'The tour discovery section offers curated experiences with detailed descriptions and immersive narration. Browse through available tours, each with comprehensive information about attractions, historical context, and accessibility features. Select tours using voice commands like "tour one" through "tour four", or use natural language like "show me the first tour". Once selected, get detailed information about the tour, including duration, difficulty level, accessibility features, and highlights. Start tours with voice commands and receive step-by-step guidance through each attraction. The app provides rich audio descriptions, historical context, and practical information to enhance your experience.',
    },
    {
      'title': 'My Content',
      'description':
          'Access and manage your downloaded tours and offline content library',
      'commands':
          'Say "play tour" to start playback, "pause tour" to stop, "resume tour" to continue, "download all" to save content, "delete tour" to remove, "tour list" to see available content, "tour progress" for status',
      'detailed_help':
          'The downloads section manages your offline content library, allowing you to access tours and audio guides without internet connection. Download tours for offline use and organize your content library. Play downloaded tours with full audio narration, ambient sounds, and interactive features. Control playback with voice commands: play, pause, resume, skip, and repeat sections. The app tracks your progress through tours and provides status updates. Manage your library by downloading new content, deleting old tours, and organizing your collection. All downloaded content includes full accessibility features, ensuring you can enjoy tours offline with complete voice guidance.',
    },
    {
      'title': 'Voice Control',
      'description':
          'Master voice commands and audio control for seamless app interaction',
      'commands':
          'Say "stop talking" to pause narration, "resume talking" to continue, "speak faster" or "speak slower" to adjust speed, "repeat" to hear again, "volume up" or "volume down" to adjust audio',
      'detailed_help':
          'Voice control is the primary interface for app interaction, designed for accessibility and ease of use. Control all app functions through natural voice commands without needing to touch the screen. Adjust speech settings in real-time: change speed, volume, and pitch to suit your preferences. Use commands like "speak faster" or "speak slower" to adjust narration speed, or "volume up" and "volume down" for audio control. The app recognizes natural language patterns and provides contextual responses. Voice commands work across all screens and adapt to your current context. The system learns your preferences and provides personalized responses. All voice interactions include haptic feedback for confirmation.',
    },
    {
      'title': 'Quick Help',
      'description':
          'Get immediate assistance and comprehensive support for all app features',
      'commands':
          'Say "help" for general assistance, "tutorial" for guided learning, "accessibility" for features, "contact support" for help, "app guide" for comprehensive information, "troubleshooting" for issues',
      'detailed_help':
          'The help section provides comprehensive assistance and support for all app features. Access detailed tutorials, accessibility guides, troubleshooting information, and contact support. Get step-by-step guidance for using any feature, from basic navigation to advanced voice commands. The help system includes interactive tutorials that walk you through each feature with voice guidance. Find solutions to common issues, learn about accessibility features, and get tips for optimal app usage. Contact support directly through voice commands for personalized assistance. The help content is regularly updated and includes user feedback and common questions. All help content is fully accessible with voice narration and includes practical examples.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initServices();
    _initTTS();
    _initSpeechToText();
    _registerWithAudioManager();
    _startAutomaticNarration();
  }

  Future<void> _initServices() async {
    _audioManagerService = AudioManagerService();
    _screenTransitionManager = ScreenTransitionManager();
    _voiceNavigationService = VoiceNavigationService();
  }

  Future<void> _initTTS() async {
    tts = FlutterTts();
    try {
      await tts.setLanguage("en-US");
      await tts.setSpeechRate(0.5);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
    } catch (e) {
      developer.log("TTS Init Error: $e", name: 'TTS');
    }
  }

  Future<void> _initSpeechToText() async {
    speech = SpeechToText();
    try {
      bool available = await speech.initialize(
        onError: (error) {
          developer.log("STT Error: ${error.errorMsg}", name: 'SpeechToText');
        },
        onStatus: (status) {
          developer.log("STT Status: $status", name: 'SpeechToText');
        },
      );
      if (available) {
        developer.log("STT Available", name: 'SpeechToText');
      }
    } catch (e) {
      developer.log("STT Init Error: $e", name: 'SpeechToText');
    }
  }

  Future<void> _registerWithAudioManager() async {
    _audioManagerService.registerScreen('help', tts, speech);

    _audioControlSubscription = _audioManagerService.audioControlStream.listen(
      (event) {},
    );

    _screenActivationSubscription = _audioManagerService.screenActivationStream
        .listen((screenId) {});

    _transitionSubscription = _screenTransitionManager.transitionStream.listen(
      (event) {},
    );

    // Listen to help-specific voice commands
    _helpCommandSubscription = _voiceNavigationService.helpCommandStream.listen(
      (command) {
        _handleHelpVoiceCommand(command);
      },
    );

    // Listen to screen navigation commands
    _screenNavigationSubscription = _voiceNavigationService
        .screenNavigationStream
        .listen((screen) {
          _handleScreenNavigation(screen);
        });
  }

  Future<void> _startAutomaticNarration() async {
    setState(() {
      _isNarrating = true;
    });

    // Enhanced welcome message for blind users
    String welcomeMessage = "Welcome to your comprehensive assistance hub! ";
    welcomeMessage +=
        "I'm your personal guide to mastering all features of EchoPath, your voice-powered navigation companion. ";
    welcomeMessage +=
        "You have ${_helpTopics.length} detailed help topics available, each designed to enhance your experience. ";
    welcomeMessage +=
        "Say 'select one' through 'select six' to explore different topics, or simply say 'one', 'two', 'three', 'four', 'five', 'six'. ";
    welcomeMessage +=
        "You can also use natural language like 'select navigation', 'select map', 'select tour', 'select content', 'select voice', or 'select assistance'. ";
    welcomeMessage +=
        "Each topic provides comprehensive information, practical examples, and step-by-step guidance. ";
    welcomeMessage +=
        "Say 'menu' to hear all topics, 'help' for all commands, 'detailed help' for comprehensive information, or 'go back' to return.";

    await _audioManagerService.speakIfActive('help', welcomeMessage);

    // Brief pause for user to process
    await Future.delayed(Duration(seconds: 1));

    // Present interactive assistance options
    await _speakAssistanceOptions();

    setState(() {
      _isNarrating = false;
    });
  }

  Future<void> _speakAssistanceOptions() async {
    String assistance =
        "Here's your comprehensive interactive assistance menu: ";
    assistance +=
        "I can help you master quick navigation, explore maps with detailed guidance, discover fascinating tours, manage your content library, control voice interactions, and get immediate support. ";
    assistance +=
        "Each topic provides detailed explanations, practical examples, and step-by-step instructions. ";
    assistance +=
        "Say 'select one' through 'select six' for specific help topics, or simply say 'one', 'two', 'three', 'four', 'five', 'six'. ";
    assistance +=
        "Use natural language like 'select navigation', 'select map', 'select tour', 'select content', 'select voice', or 'select assistance'. ";
    assistance +=
        "Say 'pause' to stop, 'play' to continue, 'next' for next topic, 'previous' for previous topic, 'menu' to see all topics, or 'go back' to return. ";
    assistance +=
        "You can also say 'repeat' to hear this again, 'status' to check current topic, 'detailed help' for comprehensive information, or 'help' for all commands.";

    await _audioManagerService.speakIfActive('help', assistance);
  }

  Future<void> _speakAllTopics() async {
    String allTopics = "Here are your interactive assistance options: ";
    for (int i = 0; i < _helpTopics.length; i++) {
      final topic = _helpTopics[i];
      allTopics +=
          "${i + 1}. ${topic['title']}: ${topic['description']}. ${topic['commands']}. ";
    }
    allTopics +=
        "Say 'select one' through 'select six' for specific help, or just say 'one', 'two', 'three', 'four', 'five', 'six'. ";
    allTopics +=
        "Say 'pause' to stop, 'play' to continue, 'next' for next topic, 'previous' for previous topic, 'status' to check current topic, or 'go back' to return.";

    await _audioManagerService.speakIfActive('help', allTopics);
  }

  Future<void> _speakTopicDetails(int index) async {
    if (index >= 0 && index < _helpTopics.length) {
      final topic = _helpTopics[index];

      // Enhanced speech narration with comprehensive information
      String message = "Help topic selected: ${topic['title']}. ";
      message += "${topic['description']}. ";
      message += "Available commands: ${topic['commands']}. ";

      // Add topic-specific guidance
      switch (index) {
        case 0: // Quick Navigation
          message +=
              "This section helps you move between different parts of the app using voice commands. ";
          message +=
              "You can navigate to any screen from anywhere in the app. ";
          break;
        case 1: // Map Exploration
          message +=
              "The map screen provides location-based exploration with detailed descriptions. ";
          message +=
              "Perfect for discovering nearby places and getting directions. ";
          break;
        case 2: // Tour Discovery
          message +=
              "Find and experience guided tours with immersive audio narration. ";
          message +=
              "Each tour includes historical context and accessibility information. ";
          break;
        case 3: // My Content
          message +=
              "Manage your downloaded tours and offline content library. ";
          message += "Access your content without internet connection. ";
          break;
        case 4: // Voice Control
          message += "Master voice commands for seamless app interaction. ";
          message += "Control all features through natural speech. ";
          break;
        case 5: // Quick Help
          message += "Get immediate assistance and comprehensive support. ";
          message += "Includes tutorials and troubleshooting guides. ";
          break;
      }

      message +=
          "Say 'detailed help' for comprehensive information, 'pause' to stop, 'play' to continue, 'next' for next topic, 'previous' for previous topic, 'repeat' to hear again, 'menu' to see all topics, or 'go back' to return.";

      await _audioManagerService.speakIfActive('help', message);
    } else {
      await _audioManagerService.speakIfActive(
        'help',
        "Topic not available. Say 'menu' to see all available topics, or 'one' through 'six' to select a specific topic.",
      );
    }
  }

  // Enhanced detailed help narration for comprehensive information
  Future<void> _speakDetailedTopicHelp(int index) async {
    if (index >= 0 && index < _helpTopics.length) {
      final topic = _helpTopics[index];
      String detailedMessage = "Comprehensive help for: ${topic['title']}. ";
      detailedMessage += "${topic['description']}. ";
      detailedMessage += "Available commands: ${topic['commands']}. ";
      detailedMessage += "${topic['detailed_help']} ";
      detailedMessage +=
          "Say 'pause' to stop, 'play' to continue, 'next' for next topic, 'previous' for previous topic, 'repeat' to hear again, 'menu' to see all topics, or 'go back' to return.";

      await _audioManagerService.speakIfActive('help', detailedMessage);
    } else {
      await _audioManagerService.speakIfActive(
        'help',
        "Topic not available. Say 'menu' to see all available topics, or 'one' through 'six' to select a specific topic.",
      );
    }
  }

  // Enhanced card content narration for immediate feedback
  Future<void> _speakCardContent(int index) async {
    if (index >= 0 && index < _helpTopics.length) {
      final topic = _helpTopics[index];
      String cardContent = "Card ${index + 1}: ${topic['title']}. ";
      cardContent += "${topic['description']}. ";
      cardContent += "Commands: ${topic['commands']}. ";
      cardContent +=
          "Tap again for detailed information or say 'detailed help' for comprehensive guidance.";

      await _audioManagerService.speakIfActive('help', cardContent);
    }
  }

  // Handle screen navigation from voice commands
  void _handleScreenNavigation(String screen) {
    debugPrint('Help screen handling navigation to: $screen');
    // Use screen transition manager for smooth navigation
    _screenTransitionManager.handleVoiceNavigation(screen);
  }

  // Enhanced voice commands for blind users
  Future<void> _handleHelpVoiceCommand(String command) async {
    // Enhanced topic selection with natural language
    if (command.contains('select') || command.contains('choose')) {
      if (command.contains('one') ||
          command.contains('1') ||
          command.contains('first') ||
          command.contains('navigation')) {
        await _selectAndSpeakTopic(0);
      } else if (command.contains('two') ||
          command.contains('2') ||
          command.contains('second') ||
          command.contains('map')) {
        await _selectAndSpeakTopic(1);
      } else if (command.contains('three') ||
          command.contains('3') ||
          command.contains('third') ||
          command.contains('tour') ||
          command.contains('discovery')) {
        await _selectAndSpeakTopic(2);
      } else if (command.contains('four') ||
          command.contains('4') ||
          command.contains('fourth') ||
          command.contains('content') ||
          command.contains('downloads')) {
        await _selectAndSpeakTopic(3);
      } else if (command.contains('five') ||
          command.contains('5') ||
          command.contains('fifth') ||
          command.contains('voice') ||
          command.contains('control')) {
        await _selectAndSpeakTopic(4);
      } else if (command.contains('six') ||
          command.contains('6') ||
          command.contains('sixth') ||
          command.contains('quick') ||
          command.contains('assistance')) {
        await _selectAndSpeakTopic(5);
      } else {
        await _speakAllTopics();
      }
    }
    // Direct number commands for quick access
    else if (command == 'one' || command == '1' || command == 'first') {
      await _selectAndSpeakTopic(0);
    } else if (command == 'two' || command == '2' || command == 'second') {
      await _selectAndSpeakTopic(1);
    } else if (command == 'three' || command == '3' || command == 'third') {
      await _selectAndSpeakTopic(2);
    } else if (command == 'four' || command == '4' || command == 'fourth') {
      await _selectAndSpeakTopic(3);
    } else if (command == 'five' || command == '5' || command == 'fifth') {
      await _selectAndSpeakTopic(4);
    } else if (command == 'six' || command == '6' || command == 'sixth') {
      await _selectAndSpeakTopic(5);
    }
    // Enhanced playback controls
    else if (command.contains('pause') ||
        command.contains('stop') ||
        command.contains('halt') ||
        command.contains('silence')) {
      await _pauseNarration();
    } else if (command.contains('play') ||
        command.contains('resume') ||
        command.contains('continue') ||
        command.contains('unpause') ||
        command.contains('start')) {
      await _resumeNarration();
    }
    // Enhanced navigation
    else if (command.contains('next') ||
        command.contains('forward') ||
        command.contains('skip')) {
      await _nextTopic();
    } else if (command.contains('previous') ||
        command.contains('back') ||
        command.contains('last')) {
      await _previousTopic();
    }
    // Enhanced information and help
    else if (command.contains('repeat') ||
        command.contains('again') ||
        command.contains('say again') ||
        command.contains('read')) {
      await _repeatCurrentTopic();
    } else if (command.contains('detailed help') ||
        command.contains('comprehensive') ||
        command.contains('full details') ||
        command.contains('complete information')) {
      await _speakDetailedTopicHelp(_currentTopicIndex);
    } else if (command.contains('help') ||
        command.contains('assistance') ||
        command.contains('guide') ||
        command.contains('options')) {
      await _speakAssistanceOptions();
    } else if (command.contains('menu') ||
        command.contains('list') ||
        command.contains('all topics') ||
        command.contains('topics')) {
      await _speakAllTopics();
    } else if (command.contains('current') ||
        command.contains('what') ||
        command.contains('status')) {
      await _speakCurrentTopicStatus();
    }
    // Enhanced navigation
    else if (command.contains('go back') ||
        command.contains('return') ||
        command.contains('exit') ||
        command.contains('home')) {
      await _navigateBack();
    }
    // Unknown command - provide contextual help
    else {
      await _provideContextualHelp();
    }
  }

  Future<void> _navigateBack() async {
    await _audioManagerService.speakIfActive(
      'help',
      "Returning to your adventure hub.",
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Enhanced topic selection and speaking for blind users
  Future<void> _selectAndSpeakTopic(int index) async {
    if (index >= 0 && index < _helpTopics.length) {
      _currentTopicIndex = index;
      final topic = _helpTopics[index];

      // Provide immediate feedback and speak topic details
      await _audioManagerService.speakIfActive(
        'help',
        "Selected: ${topic['title']}. ${topic['description']} ${topic['commands']}",
      );

      // Provide additional controls after a brief pause
      await Future.delayed(Duration(seconds: 2));
      await _audioManagerService.speakIfActive(
        'help',
        "Say 'detailed help' for comprehensive information, 'next' for next topic, 'previous' for previous topic, 'repeat' to hear again, 'menu' to see all topics, or 'go back' to return.",
      );
    } else {
      await _audioManagerService.speakIfActive(
        'help',
        "Topic not available. Say 'menu' to see all available topics, or 'one' through 'six' to select a specific topic.",
      );
    }
  }

  // Enhanced contextual help for blind users
  Future<void> _provideContextualHelp() async {
    String helpMessage =
        "I didn't understand that command. Here's what you can do: ";

    if (_currentTopicIndex >= 0 && _currentTopicIndex < _helpTopics.length) {
      final topic = _helpTopics[_currentTopicIndex];
      helpMessage += "You have ${topic['title']} selected. ";
      helpMessage +=
          "Say 'detailed help' for comprehensive information, 'repeat' to hear it again, 'next' for next topic, or 'previous' for previous topic. ";
    } else {
      helpMessage +=
          "No topic selected. Say 'one' through 'six' to choose a topic, or 'menu' to see all options. ";
    }

    helpMessage +=
        "You can also say 'pause' to stop, 'play' to continue, 'help' for all commands, or 'go back' to return.";

    await _audioManagerService.speakIfActive('help', helpMessage);
  }

  // Enhanced current topic status
  Future<void> _speakCurrentTopicStatus() async {
    if (_currentTopicIndex >= 0 && _currentTopicIndex < _helpTopics.length) {
      final topic = _helpTopics[_currentTopicIndex];
      String statusMessage = "Current topic: ${topic['title']}. ";
      statusMessage += "${topic['description']} ";
      statusMessage +=
          "Say 'detailed help' for comprehensive information, 'repeat' to hear the full details, 'next' for next topic, 'previous' for previous topic, or 'menu' to see all topics.";

      await _audioManagerService.speakIfActive('help', statusMessage);
    } else {
      await _audioManagerService.speakIfActive(
        'help',
        "No topic currently selected. Say 'one' through 'six' to choose a topic, or 'menu' to see all available topics.",
      );
    }
  }

  // Enhanced user control methods for blind users
  Future<void> _pauseNarration() async {
    await _audioManagerService.stopAllAudio();
    setState(() {
      _isPaused = true;
      _isNarrating = false;
    });
    await _audioManagerService.speakIfActive(
      'help',
      "Narration paused. Say 'play' to continue, 'next' for next topic, 'previous' for previous topic, 'menu' to see all topics, or 'go back' to return.",
    );
  }

  Future<void> _resumeNarration() async {
    setState(() {
      _isPaused = false;
      _isNarrating = true;
    });

    if (_currentTopicIndex >= 0 && _currentTopicIndex < _helpTopics.length) {
      await _speakTopicDetails(_currentTopicIndex);
    } else {
      await _speakAllTopics();
    }

    setState(() {
      _isNarrating = false;
    });
  }

  Future<void> _nextTopic() async {
    if (_helpTopics.isNotEmpty) {
      _currentTopicIndex = (_currentTopicIndex + 1) % _helpTopics.length;
      setState(() {
        _isPaused = false;
        _isNarrating = true;
      });

      final topic = _helpTopics[_currentTopicIndex];
      String navigationMessage = "Moved to next topic: ${topic['title']}. ";
      navigationMessage += "${topic['description']} ";
      navigationMessage +=
          "Say 'detailed help' for comprehensive information, 'repeat' to hear full details, 'next' to continue, 'previous' to go back, or 'menu' to see all topics.";

      await _audioManagerService.speakIfActive('help', navigationMessage);

      setState(() {
        _isNarrating = false;
      });
    } else {
      await _audioManagerService.speakIfActive(
        'help',
        "No topics available. Say 'menu' to see all topics, or 'go back' to return.",
      );
    }
  }

  Future<void> _previousTopic() async {
    if (_helpTopics.isNotEmpty) {
      _currentTopicIndex =
          (_currentTopicIndex - 1 + _helpTopics.length) % _helpTopics.length;
      setState(() {
        _isPaused = false;
        _isNarrating = true;
      });

      final topic = _helpTopics[_currentTopicIndex];
      String navigationMessage = "Moved to previous topic: ${topic['title']}. ";
      navigationMessage += "${topic['description']} ";
      navigationMessage +=
          "Say 'detailed help' for comprehensive information, 'repeat' to hear full details, 'next' to continue, 'previous' to go back, or 'menu' to see all topics.";

      await _audioManagerService.speakIfActive('help', navigationMessage);

      setState(() {
        _isNarrating = false;
      });
    } else {
      await _audioManagerService.speakIfActive(
        'help',
        "No topics available. Say 'menu' to see all topics, or 'go back' to return.",
      );
    }
  }

  Future<void> _repeatCurrentTopic() async {
    if (_currentTopicIndex >= 0 && _currentTopicIndex < _helpTopics.length) {
      setState(() {
        _isPaused = false;
        _isNarrating = true;
      });

      await _speakTopicDetails(_currentTopicIndex);

      setState(() {
        _isNarrating = false;
      });
    } else {
      await _audioManagerService.speakIfActive(
        'help',
        "No topic selected. Say 'one' through 'six' to choose a topic, or 'menu' to see all options.",
      );
    }
  }

  @override
  void dispose() {
    tts.stop();
    speech.stop();
    _audioControlSubscription?.cancel();
    _screenActivationSubscription?.cancel();
    _transitionSubscription?.cancel();
    _helpCommandSubscription?.cancel();
    _audioManagerService.unregisterScreen('help');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Assistance"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isNarrating ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              if (_isNarrating) {
                _audioManagerService.stopAllAudio();
                setState(() {
                  _isNarrating = false;
                });
              } else {
                _speakAllTopics();
              }
            },
            tooltip: _isNarrating ? 'Stop Narration' : 'Start Narration',
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              final navigator = Navigator.of(context);
              _audioManagerService
                  .speakIfActive('help', "Returning to your adventure hub.")
                  .then((_) {
                    if (mounted) {
                      navigator.pop();
                    }
                  });
            },
            tooltip: 'Go Home',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status indicator and control panel
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  _isNarrating ? Icons.record_voice_over : Icons.volume_up,
                  color: _isNarrating ? Colors.green : Colors.white70,
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isPaused
                        ? "Narration paused - Topic ${_currentTopicIndex + 1}"
                        : _isNarrating
                        ? "Providing assistance..."
                        : "Your personal guide is ready to help",
                    style: TextStyle(
                      color:
                          _isPaused
                              ? Colors.orange
                              : _isNarrating
                              ? Colors.green
                              : Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Pause/Play button
                    IconButton(
                      onPressed: () async {
                        if (_isPaused) {
                          await _resumeNarration();
                        } else {
                          await _pauseNarration();
                        }
                      },
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: _isPaused ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                      tooltip: _isPaused ? 'Play' : 'Pause',
                    ),
                    // Repeat button
                    IconButton(
                      onPressed: () async {
                        await _repeatCurrentTopic();
                      },
                      icon: Icon(Icons.replay, color: Colors.purple, size: 24),
                      tooltip: 'Repeat Topic',
                    ),
                    // Previous button
                    IconButton(
                      onPressed: () async {
                        await _previousTopic();
                      },
                      icon: Icon(
                        Icons.skip_previous,
                        color: Colors.blue,
                        size: 24,
                      ),
                      tooltip: 'Previous Topic',
                    ),
                    // Next button
                    IconButton(
                      onPressed: () async {
                        await _nextTopic();
                      },
                      icon: Icon(Icons.skip_next, color: Colors.blue, size: 24),
                      tooltip: 'Next Topic',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Assistance topics list with tour-style UX
          Expanded(
            child: ListView.builder(
              itemCount: _helpTopics.length,
              itemBuilder: (context, index) {
                final topic = _helpTopics[index];
                final isCurrentTopic = index == _currentTopicIndex;
                return Card(
                  color: isCurrentTopic ? Colors.blue[900] : Colors.grey[900],
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isCurrentTopic ? Colors.orange : Colors.blue,
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      topic['title']!,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          topic['description']!,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          topic['commands']!,
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      // Enhanced haptic feedback and vibration
                      try {
                        if (await Vibration.hasVibrator()) {
                          // Double vibration pattern for help topic selection
                          Vibration.vibrate(duration: 80);
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );
                          Vibration.vibrate(duration: 60);
                        }
                      } catch (e) {
                        // Ignore vibration errors
                      }

                      // Stop any ongoing TTS
                      await tts.stop();

                      // Update current topic index
                      setState(() {
                        _currentTopicIndex = index;
                      });

                      // Provide immediate feedback with card content
                      await _speakCardContent(index);

                      // Brief pause for user to process
                      await Future.delayed(const Duration(milliseconds: 800));

                      // Speak comprehensive topic details
                      await _speakTopicDetails(index);
                    },
                    trailing: Icon(Icons.help_outline, color: Colors.blue),
                  ),
                );
              },
            ),
          ),

          // Enhanced voice control tips panel for blind users
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Text(
                  "🎤 Voice Control Tips",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Tap cards for enhanced narration • Say 'select one' through 'select six' for topics • 'detailed help' for comprehensive information • 'pause' to stop • 'play' to continue • 'next' for next topic • 'previous' for previous topic • 'menu' to see all topics • 'status' to check current topic",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  "Natural commands: 'select navigation', 'select map', 'select tour', 'what's current', 'help' for all commands • Enhanced haptic feedback on tap",
                  style: TextStyle(color: Colors.blue[300], fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
