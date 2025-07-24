import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'audio_guide_screen.dart';
import 'services/audio_manager_service.dart';
import 'services/screen_transition_manager.dart';
import 'services/voice_navigation_service.dart';

class TourDiscoveryScreen extends StatefulWidget {
  const TourDiscoveryScreen({super.key});

  @override
  State<TourDiscoveryScreen> createState() => _TourDiscoveryScreenState();
}

class _TourDiscoveryScreenState extends State<TourDiscoveryScreen> {
  late FlutterTts tts;
  late SpeechToText speech;
  late AudioManagerService _audioManagerService;
  late ScreenTransitionManager _screenTransitionManager;
  late VoiceNavigationService _voiceNavigationService;

  StreamSubscription? _audioControlSubscription;
  StreamSubscription? _screenActivationSubscription;
  StreamSubscription? _transitionSubscription;
  StreamSubscription? _voiceStatusSubscription;
  StreamSubscription? _navigationCommandSubscription;
  StreamSubscription? _discoverCommandSubscription;

  // Enhanced voice interaction state
  bool _isVoiceInitialized = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _voiceStatus = 'Initializing...';
  String locationInfo = "Fetching nearby attractions...";
  bool _isLoading = true;
  bool _isAudioActive = false;

  // Tour discovery state
  List<Map<String, dynamic>> _availableTours = [];
  String? _selectedTour;
  bool _isStartingTour = false;

  // Discover screen specific voice command state
  bool _isDiscoverVoiceEnabled = true;
  bool _isTourDiscoveryMode = false;
  bool _isPlaceExplorationMode = false;
  bool _isDetailedTourInfo = false;
  String _lastSpokenTour = '';
  int _commandCount = 0;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      // Initialize services
      _audioManagerService = AudioManagerService();
      _screenTransitionManager = ScreenTransitionManager();
      _voiceNavigationService = VoiceNavigationService();

      // Initialize TTS and speech recognition
      tts = FlutterTts();
      speech = SpeechToText();

      await _initTTS();
      await _initSpeechToText();
      await _registerWithAudioManager();
      await _initializeVoiceNavigation();
      await _fetchLocation();

      // Activate audio for discover screen
      await _activateDiscoverAudio();
    } catch (e) {
      print('Error initializing tour discovery screen services: $e');
      setState(() {
        _voiceStatus = 'Error initializing services';
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
      developer.log("TTS Init Error: $e", name: 'TTS');
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
        "Sorry, I couldn't understand you clearly. Let me repeat the tour discovery options. "
            "Say 'find tours' to discover available tours, 'start tour' followed by tour name to begin, "
            "'refresh' to update location, 'tour details' for more information, 'go back' to return to previous screen, "
            "or 'help' for assistance. Which option would you like?",
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
                    "Say 'find tours' to discover available tours, 'start tour' followed by tour name to begin, "
                    "'refresh' to update location, 'tour details' for more information, 'go back' to return to previous screen, "
                    "or 'help' for assistance. Which option would you like?",
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

    if (command.contains('find tours') || command.contains('discover tours')) {
      _handleFindToursCommand();
    } else if (command.contains('start tour') ||
        command.contains('begin tour')) {
      _handleStartTourCommand(command);
    } else if (command.contains('refresh') || command.contains('update')) {
      _handleRefreshCommand();
    } else if (command.contains('tour details') ||
        command.contains('details')) {
      _handleTourDetailsCommand();
    } else if (command.contains('go back') || command.contains('back')) {
      _handleGoBackCommand();
    } else if (command.contains('help')) {
      _handleHelpCommand();
    } else if (command.contains('go to')) {
      _handleNavigationCommand(command);
    } else {
      // Unknown command - provide helpful feedback
      _speakAndWaitForResponse(
        "I didn't understand that tour discovery command. Say 'find tours' to discover available tours, "
            "'start tour' followed by tour name to begin, 'refresh' to update location, 'tour details' for more information, "
            "'go back' to return to previous screen, or 'help' for assistance. "
            "For navigation, say 'go to' followed by home, map, downloads, or help.",
      );
    }
  }

  void _handleFindToursCommand() {
    _speakAndWaitForResponse(
      "Finding available tours near your location. I'll search for attractions and guided tours in your area.",
    );
    _fetchLocation();
  }

  void _handleStartTourCommand(String command) {
    // Extract tour name from command
    String tourName = '';
    if (command.contains('start tour')) {
      tourName = command.split('start tour').last.trim();
    } else if (command.contains('begin tour')) {
      tourName = command.split('begin tour').last.trim();
    }

    if (tourName.isNotEmpty) {
      _startTour(tourName);
    } else {
      _speakAndWaitForResponse(
        "Please specify which tour you'd like to start. Say 'start tour' followed by the tour name, "
            "such as 'start tour Murchison Falls' or 'start tour Kasubi Tombs'.",
      );
    }
  }

  void _handleRefreshCommand() {
    _speakAndWaitForResponse(
      "Refreshing your location and updating available tours. This may take a moment.",
    );
    _fetchLocation();
  }

  void _handleTourDetailsCommand() {
    if (_availableTours.isNotEmpty) {
      String details = "Available tours: ";
      for (int i = 0; i < _availableTours.length; i++) {
        details +=
        "${i + 1}. ${_availableTours[i]['name']} - ${_availableTours[i]['description']}. ";
      }
      _speakAndWaitForResponse(details);
    } else {
      _speakAndWaitForResponse(
        "No tours are currently available. Say 'refresh' to update your location and search for nearby attractions.",
      );
    }
  }

  void _handleGoBackCommand() {
    _speakAndWaitForResponse("Navigating back to previous screen.");
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleHelpCommand() {
    _speakAndWaitForResponse(
      "Tour discovery help. You can say 'find tours' to discover available tours, "
          "'start tour' followed by tour name to begin exploring, 'refresh' to update your location, "
          "'tour details' for more information about available tours, 'go back' to return to previous screen, "
          "or 'help' to hear this message again. For navigation, say 'go to' followed by home, map, downloads, or help.",
    );
  }

  void _handleNavigationCommand(String command) {
    if (command.contains('home')) {
      _speakAndWaitForResponse("Navigating to home screen.");
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (command.contains('map')) {
      _speakAndWaitForResponse("Navigating to map screen.");
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (command.contains('downloads')) {
      _speakAndWaitForResponse("Navigating to downloads screen.");
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (command.contains('help')) {
      _speakAndWaitForResponse("Navigating to help and support screen.");
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      _speakAndWaitForResponse(
        "I didn't understand the navigation destination. Please say 'go to' followed by home, map, downloads, or help.",
      );
    }
  }

  Future<void> _activateDiscoverAudio() async {
    try {
      // Ensure map audio is deactivated first
      await _audioManagerService.deactivateScreenAudio('map');

      // Activate discover screen audio
      await _audioManagerService.activateScreenAudio('discover');
      setState(() {
        _isAudioActive = true;
      });

      // Speak welcome message
      await _speakWelcome();
    } catch (e) {
      print('Error activating discover audio: $e');
    }
  }

  Future<void> _registerWithAudioManager() async {
    _audioManagerService.registerScreen('discover', tts, speech);

    _audioControlSubscription = _audioManagerService.audioControlStream.listen((
        event,
        ) {
      print('Discover screen audio control event: $event');
    });

    _screenActivationSubscription = _audioManagerService.screenActivationStream
        .listen((screenId) {
      print('Discover screen activation event: $screenId');
    });

    _transitionSubscription = _screenTransitionManager.transitionStream.listen((
        event,
        ) {
      print('Discover screen transition event: $event');
    });
  }

  Future<void> _initializeVoiceNavigation() async {
    // Listen to discover-specific voice commands
    _discoverCommandSubscription = _voiceNavigationService.discoverCommandStream
        .listen((command) {
      _handleDiscoverVoiceCommand(command);
    });

    // Listen to voice status updates
    _voiceStatusSubscription = _voiceNavigationService.voiceStatusStream.listen(
          (status) {
        setState(() {
          _voiceStatus = status;
          if (status.startsWith('listening_started')) {
            _isListening = true;
          } else if (status.startsWith('listening_stopped')) {
            _isListening = false;
          }
        });
      },
    );

    // Listen to navigation commands
    _navigationCommandSubscription = _voiceNavigationService
        .navigationCommandStream
        .listen((command) {
      print('Discover screen navigation command: $command');
      _handleNavigationCommand(command);
    });
  }

  // Handle discover-specific voice commands
  Future<void> _handleDiscoverVoiceCommand(String command) async {
    print('🎤 Discover voice command received: $command');

    // Limit command frequency to prevent spam
    if (_commandCount > 10) {
      _commandCount = 0;
      return;
    }
    _commandCount++;

    if (command.startsWith('find_tours')) {
      _handleFindToursCommand();
    } else if (command.startsWith('start_tour:')) {
      String tourName = command.split(':').last;
      _startTour(tourName);
    } else if (command == 'refresh_location') {
      _handleRefreshCommand();
    } else if (command == 'tour_details') {
      _handleTourDetailsCommand();
    } else if (command == 'go_back') {
      _handleGoBackCommand();
    } else if (command == 'help') {
      _handleHelpCommand();
    } else {
      // Unknown command - provide helpful feedback
      _speakAndWaitForResponse(
        "I didn't understand that discover command. Say 'find tours' to discover available tours, "
            "'start tour' followed by tour name to begin, 'refresh' to update location, 'tour details' for more information, "
            "'go back' to return to previous screen, or 'help' for assistance.",
      );
    }
  }

  Future<void> _speakWelcome() async {
    if (mounted) {
      try {
        _speakAndWaitForResponse(
          "Welcome to Tour Discovery. I'll help you find and start guided tours of nearby attractions. "
              "Say 'find tours' to discover available tours, 'start tour' followed by tour name to begin exploring, "
              "'refresh' to update your location, 'tour details' for more information about available tours, "
              "'go back' to return to previous screen, or 'help' for assistance. "
              "After I finish speaking, I'll automatically listen for your commands.",
        );
      } catch (e) {
        developer.log("TTS Speak Error: $e", name: 'TTS');
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true;
      locationInfo = "Fetching nearby attractions...";
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationInfo =
            "Location permission denied. Using default location.";
            _isLoading = false;
          });
          _loadDefaultTours();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationInfo =
          "Location permission permanently denied. Using default location.";
          _isLoading = false;
        });
        _loadDefaultTours();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        locationInfo =
        "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });

      // Simulate finding nearby tours based on location
      await _findNearbyTours(position);
    } catch (e) {
      print('Error fetching location: $e');
      setState(() {
        locationInfo = "Error getting location. Using default tours.";
        _isLoading = false;
      });
      _loadDefaultTours();
    }
  }

  Future<void> _findNearbyTours(Position position) async {
    // Simulate API call delay
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _availableTours = [
        {
          'name': 'Murchison Falls National Park',
          'description': 'Explore the magnificent waterfall and wildlife',
          'distance': '2.3 km',
          'duration': '2-3 hours',
          'rating': 4.8,
          'category': 'Nature',
        },
        {
          'name': 'Kasubi Tombs',
          'description': 'Royal burial site of Buganda kings',
          'distance': '1.1 km',
          'duration': '1-2 hours',
          'rating': 4.5,
          'category': 'Cultural',
        },
        {
          'name': 'Bwindi Impenetrable Forest',
          'description': 'Home to endangered mountain gorillas',
          'distance': '5.7 km',
          'duration': '4-6 hours',
          'rating': 4.9,
          'category': 'Wildlife',
        },
        {
          'name': 'Lake Victoria Tour',
          'description': 'Explore Africa\'s largest lake',
          'distance': '3.2 km',
          'duration': '2-3 hours',
          'rating': 4.3,
          'category': 'Nature',
        },
      ];
      _isLoading = false;
    });

    _speakAndWaitForResponse(
      "Found ${_availableTours.length} tours near your location. "
          "Say 'tour details' to hear about each tour, or 'start tour' followed by the tour name to begin exploring.",
    );
  }

  void _loadDefaultTours() {
    setState(() {
      _availableTours = [
        {
          'name': 'Murchison Falls National Park',
          'description': 'Explore the magnificent waterfall and wildlife',
          'distance': 'Default location',
          'duration': '2-3 hours',
          'rating': 4.8,
          'category': 'Nature',
        },
        {
          'name': 'Kasubi Tombs',
          'description': 'Royal burial site of Buganda kings',
          'distance': 'Default location',
          'duration': '1-2 hours',
          'rating': 4.5,
          'category': 'Cultural',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _startTour(String tourName) async {
    final tour = _availableTours.firstWhere(
          (t) => t['name'].toLowerCase().contains(tourName.toLowerCase()),
      orElse: () => _availableTours.isNotEmpty ? _availableTours[0] : {},
    );

    if (tour.isEmpty) {
      _speakAndWaitForResponse(
        "Tour '$tourName' not found. Say 'tour details' to hear available tours, or 'find tours' to search again.",
      );
      return;
    }

    setState(() {
      _selectedTour = tour['name'];
      _isStartingTour = true;
    });

    _speakAndWaitForResponse(
      "Starting tour: ${tour['name']}. ${tour['description']} "
          "This tour typically takes ${tour['duration']} and is rated ${tour['rating']} stars. "
          "You'll be guided through the experience with audio narration.",
    );

    // Simulate tour loading
    await Future.delayed(Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isStartingTour = false;
      });

      // Navigate to audio guide screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AudioGuideScreen()),
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
    _voiceStatusSubscription?.cancel();
    _navigationCommandSubscription?.cancel();
    _discoverCommandSubscription?.cancel();
    _audioManagerService.unregisterScreen('discover');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Tour Discovery"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.home), onPressed: _handleGoBackCommand),
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () async {
              _speakAndWaitForResponse(
                "Tour discovery screen. You can say 'find tours' to discover available tours, "
                    "'start tour' followed by tour name to begin, 'refresh' to update location, "
                    "'tour details' for more information, 'go back' to return to previous screen, or 'help' for assistance.",
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Voice status indicator
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color:
              _isListening
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey[900],
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
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          // Location info
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              color: Colors.blue[900],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📍 Location Info",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      locationInfo,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.search),
                    label: Text("Find Tours"),
                    onPressed: _handleFindToursCommand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text("Refresh"),
                    onPressed: _handleRefreshCommand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tours list
          Expanded(
            child:
            _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Finding nearby tours...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
                : _availableTours.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No tours found nearby",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Try refreshing your location",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _availableTours.length,
              itemBuilder: (context, index) {
                final tour = _availableTours[index];
                final isSelected = _selectedTour == tour['name'];

                return Card(
                  color:
                  isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.grey[900],
                  margin: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.explore,
                      color: isSelected ? Colors.blue : Colors.green,
                    ),
                    title: Text(
                      tour['name']!,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white,
                        fontWeight:
                        isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour['description']!,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 16,
                            ),
                            Text(
                              " ${tour['rating']} • ${tour['distance']} • ${tour['duration']}",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed:
                      _isStartingTour
                          ? null
                          : () => _startTour(tour['name']),
                      child:
                      _isStartingTour && isSelected
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : Text("Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
