import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'services/audio_manager_service.dart';
import 'services/screen_transition_manager.dart';
import 'services/voice_navigation_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late FlutterTts tts;
  late SpeechToText speech;
  late AudioManagerService _audioManagerService;
  late ScreenTransitionManager _screenTransitionManager;
  late VoiceNavigationService _voiceNavigationService;

  // Audio players for real ambient sound playback
  late AudioPlayer _ambientPlayer;
  late AudioPlayer _tourPlayer;

  StreamSubscription? _audioControlSubscription;
  StreamSubscription? _screenActivationSubscription;
  StreamSubscription? _transitionSubscription;

  StreamSubscription? _navigationCommandSubscription;
  StreamSubscription? _downloadsCommandSubscription;
  StreamSubscription? _screenNavigationSubscription;

  bool _isNarrating = false;

  // Downloads screen specific voice command state
  int _currentTourIndex = 0; // Track current tour for next functionality

  // Enhanced playback state
  bool _isPaused = false;
  String _pausedTour = '';
  double _playbackProgress = 0.0;
  Timer? _progressTimer;

  // Audio playback state
  bool _isPlaying = false;
  String? _currentlyPlaying;
  Timer? _playbackTimer;

  // Ambient sound state
  bool _isAmbientMode = false;
  bool _isAmbientPlaying = false;
  int _currentAmbientIndex = 0;
  double _ambientVolume = 0.7;
  bool _isAmbientLoop = true;

  final List<Map<String, dynamic>> _downloads = [
    {
      'name': 'Murchison Falls',
      'status': 'Downloaded',
      'size': '45.2 MB',
      'duration': '15:30',
      'description':
          'Explore the magnificent Murchison Falls, one of Uganda\'s most spectacular natural wonders.',
      'audioUrl': 'murchison_falls_audio.mp3',
      'ambientSounds': [
        {
          'name': 'Waterfall Ambience',
          'description': 'The powerful roar of Murchison Falls',
          'duration': '5:00',
          'file': 'murchison_waterfall_ambient.mp3',
        },
        {
          'name': 'Forest Birds',
          'description': 'Chirping birds and forest sounds',
          'duration': '4:30',
          'file': 'murchison_birds_ambient.mp3',
        },
        {
          'name': 'River Flow',
          'description': 'Gentle river sounds and water flow',
          'duration': '6:15',
          'file': 'murchison_river_ambient.mp3',
        },
      ],
    },
    {
      'name': 'Kasubi Tombs',
      'status': 'Downloaded',
      'size': '32.1 MB',
      'duration': '12:45',
      'description':
          'Discover the royal tombs of the Buganda kingdom, a UNESCO World Heritage site.',
      'audioUrl': 'kasubi_tombs_audio.mp3',
      'ambientSounds': [
        {
          'name': 'Traditional Drums',
          'description': 'Traditional Buganda drumming and music',
          'duration': '3:45',
          'file': 'kasubi_drums_ambient.mp3',
        },
        {
          'name': 'Cultural Chants',
          'description': 'Traditional chants and cultural sounds',
          'duration': '4:20',
          'file': 'kasubi_chants_ambient.mp3',
        },
        {
          'name': 'Sacred Silence',
          'description': 'Peaceful atmosphere of the sacred site',
          'duration': '5:10',
          'file': 'kasubi_silence_ambient.mp3',
        },
      ],
    },
    {
      'name': 'Bwindi Impenetrable Forest',
      'status': 'Downloading...',
      'size': '67.8 MB',
      'duration': '22:15',
      'description':
          'Experience the mystical Bwindi forest, home to endangered mountain gorillas.',
      'audioUrl': 'bwindi_forest_audio.mp3',
      'ambientSounds': [
        {
          'name': 'Gorilla Sounds',
          'description': 'Distant gorilla calls and movements',
          'duration': '4:15',
          'file': 'bwindi_gorillas_ambient.mp3',
        },
        {
          'name': 'Forest Ambience',
          'description': 'Dense forest sounds and wildlife',
          'duration': '6:30',
          'file': 'bwindi_forest_ambient.mp3',
        },
        {
          'name': 'Mountain Stream',
          'description': 'Flowing mountain streams and water',
          'duration': '5:45',
          'file': 'bwindi_stream_ambient.mp3',
        },
      ],
    },
    {
      'name': 'Lake Victoria Tour',
      'status': 'Available',
      'size': '28.9 MB',
      'duration': '18:20',
      'description':
          'Journey around Africa\'s largest lake, exploring its islands and fishing communities.',
      'audioUrl': 'lake_victoria_audio.mp3',
      'ambientSounds': [
        {
          'name': 'Lake Waves',
          'description': 'Gentle waves lapping against the shore',
          'duration': '4:50',
          'file': 'lake_victoria_waves_ambient.mp3',
        },
        {
          'name': 'Fishing Village',
          'description': 'Sounds of fishing activities and village life',
          'duration': '5:25',
          'file': 'lake_victoria_village_ambient.mp3',
        },
        {
          'name': 'Boat Journey',
          'description': 'Boat engine and water journey sounds',
          'duration': '6:00',
          'file': 'lake_victoria_boat_ambient.mp3',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAudioPlayers();
    _initServices();
  }

  Future<void> _initAudioPlayers() async {
    _ambientPlayer = AudioPlayer();
    _tourPlayer = AudioPlayer();

    // Set up ambient player event listeners
    _ambientPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isAmbientPlaying = state == PlayerState.playing;
        });
      }
    });

    _ambientPlayer.onPlayerComplete.listen((event) {
      if (mounted && _isAmbientLoop) {
        // Loop the ambient sound
        _playCurrentAmbientSound();
      } else {
        setState(() {
          _isAmbientPlaying = false;
        });
      }
    });

    // Set up tour player event listeners
    _tourPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _tourPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlaying = null;
          _playbackProgress = 0.0;
        });
        _audioManagerService.speakIfActive(
          'downloads',
          "Tour playback completed. Say 'play another tour' or 'go back' to return to home.",
        );
      }
    });
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
      await _activateDownloadsAudio();
    } catch (e) {
      debugPrint('Error initializing downloads screen: $e');
    }
  }

  Future<void> _activateDownloadsAudio() async {
    try {
      // Activate downloads screen audio
      await _audioManagerService.activateScreenAudio('downloads');

      // Start automatic narration
      await _startAutomaticNarration();
    } catch (e) {
      debugPrint('Error activating downloads audio: $e');
    }
  }

  Future<void> _startAutomaticNarration() async {
    setState(() {
      _isNarrating = true;
    });

    // Enhanced welcome message for blind users
    String welcomeMessage = "Welcome to your downloads screen! ";
    welcomeMessage +=
        "You have access to immersive tour experiences with authentic ambient sounds. ";

    // Count available tours
    int downloadedTours =
        _downloads.where((tour) => tour['status'] == 'Downloaded').length;
    int totalTours = _downloads.length;

    welcomeMessage +=
        "You have $downloadedTours out of $totalTours tours downloaded and ready to play. ";

    if (downloadedTours > 0) {
      welcomeMessage +=
          "Say 'select one' through 'select four' to choose a tour, or just say 'one', 'two', 'three', 'four'. ";
      welcomeMessage +=
          "You can also say 'select murchison', 'select kasubi', 'select bwindi', or 'select lake victoria'. ";
      welcomeMessage +=
          "Once selected, say 'play' to start the tour immediately. ";
    } else {
      welcomeMessage +=
          "Say 'download all' to get all tours ready for offline listening. ";
    }

    welcomeMessage +=
        "Say 'list tours' to hear all options, 'help' for complete instructions, or 'go back' to return to the main menu.";

    await _audioManagerService.speakIfActive('downloads', welcomeMessage);

    // Brief pause for user to process
    await Future.delayed(Duration(seconds: 1));

    // Narrate available downloads with enhanced descriptions
    await _speakAvailableDownloads();

    setState(() {
      _isNarrating = false;
    });
  }

  Future<void> _speakAvailableDownloads() async {
    int downloadedCount =
        _downloads.where((d) => d['status'] == 'Downloaded').length;
    int availableCount =
        _downloads.where((d) => d['status'] == 'Available').length;

    String downloadList = "Here are your available tours: ";

    for (int i = 0; i < _downloads.length; i++) {
      final download = _downloads[i];
      String status =
          download['status'] == 'Downloaded'
              ? 'ready to play'
              : download['status'];
      String tourInfo =
          "${i + 1}. ${download['name']}, $status, ${download['duration']}. ${download['description']} ";

      // Add ambient sound information
      if (download['status'] == 'Downloaded' &&
          download['ambientSounds'] != null) {
        List<Map<String, dynamic>> ambientSounds =
            List<Map<String, dynamic>>.from(download['ambientSounds']);
        tourInfo +=
            "Includes ${ambientSounds.length} ambient sounds for immersive experience. ";
      }

      downloadList += tourInfo;
    }

    downloadList +=
        "Summary: $downloadedCount tours ready to play, $availableCount available for download. ";
    downloadList +=
        "Say 'select one' through 'select four' to choose a tour, 'play' to start current tour, 'next' or 'previous' to navigate, 'ambient' for background sounds, 'help' for all commands, or 'go back' to return.";

    await _audioManagerService.speakIfActive('downloads', downloadList);
  }

  Future<void> _initTTS() async {
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
    _audioManagerService.registerScreen('downloads', tts, speech);

    _audioControlSubscription = _audioManagerService.audioControlStream.listen(
      (event) {},
    );

    _screenActivationSubscription = _audioManagerService.screenActivationStream
        .listen((screenId) {});

    _transitionSubscription = _screenTransitionManager.transitionStream.listen(
      (event) {},
    );
  }

  Future<void> _initializeVoiceNavigation() async {
    // Listen to downloads-specific voice commands
    _downloadsCommandSubscription = _voiceNavigationService
        .downloadsCommandStream
        .listen((command) {
          _handleDownloadsVoiceCommand(command);
        });

    // Listen to screen navigation commands
    _screenNavigationSubscription = _voiceNavigationService
        .screenNavigationStream
        .listen((screen) {
          _handleScreenNavigation(screen);
        });

    // Listen to navigation commands
    _navigationCommandSubscription = _voiceNavigationService
        .navigationCommandStream
        .listen((command) {
          _handleNavigationCommand(command);
        });

    // Listen to navigation commands for tour actions
    _voiceNavigationService.navigationCommandStream.listen((command) {
      _handleTourCommand(command);
    });
  }

  void _handleNavigationCommand(String command) {
    if (command.startsWith('navigated:')) {
      String screen = command.split(':')[1];
      if (screen == 'downloads') {
        // We're now on downloads screen, activate audio
        _activateDownloadsAudio();
      }
    } else if (command == 'back') {
      _navigateBack();
    }
  }

  void _handleTourCommand(String command) {
    if (command.startsWith('play_tour:')) {
      String tourName = command.split(':')[1];
      _playTour(tourName);
    } else if (command == 'stop_tour') {
      _stopPlayback();
    } else if (command == 'download_all') {
      _downloadAll();
    } else if (command == 'delete_downloads') {
      _deleteDownloads();
    }
  }

  // Handle screen navigation from voice commands
  void _handleScreenNavigation(String screen) {
    debugPrint('Downloads screen handling navigation to: $screen');
    // Use screen transition manager for smooth navigation
    _screenTransitionManager.handleVoiceNavigation(screen);
  }

  // Enhanced voice commands for blind users
  Future<void> _handleDownloadsVoiceCommand(String command) async {
    // Enhanced tour selection with natural language
    if (command.contains('select') || command.contains('choose')) {
      if (command.contains('one') ||
          command.contains('1') ||
          command.contains('first') ||
          command.contains('murchison')) {
        await _selectAndPlayTour(0);
      } else if (command.contains('two') ||
          command.contains('2') ||
          command.contains('second') ||
          command.contains('kasubi')) {
        await _selectAndPlayTour(1);
      } else if (command.contains('three') ||
          command.contains('3') ||
          command.contains('third') ||
          command.contains('bwindi')) {
        await _selectAndPlayTour(2);
      } else if (command.contains('four') ||
          command.contains('4') ||
          command.contains('fourth') ||
          command.contains('lake') ||
          command.contains('victoria')) {
        await _selectAndPlayTour(3);
      } else {
        await _speakAvailableDownloads();
      }
    }
    // Direct number commands for quick access
    else if (command == 'one' || command == '1' || command == 'first') {
      await _selectAndPlayTour(0);
    } else if (command == 'two' || command == '2' || command == 'second') {
      await _selectAndPlayTour(1);
    } else if (command == 'three' || command == '3' || command == 'third') {
      await _selectAndPlayTour(2);
    } else if (command == 'four' || command == '4' || command == 'fourth') {
      await _selectAndPlayTour(3);
    }
    // Enhanced playback controls
    else if (command.contains('play') ||
        command.contains('start') ||
        command.contains('begin')) {
      if (command.contains('current') || command.contains('selected')) {
        await _handlePlayCurrentTourCommand();
      } else if (_currentTourIndex >= 0) {
        await _handlePlayCurrentTourCommand();
      } else {
        await _audioManagerService.speakIfActive(
          'downloads',
          "No tour selected. Say 'select one' through 'select four' to choose a tour first, or 'list tours' to hear all options.",
        );
      }
    }
    // Enhanced pause controls
    else if (command.contains('pause') ||
        command.contains('stop') ||
        command.contains('halt')) {
      if (command.contains('pause') || command.contains('temporary')) {
        await _handlePauseTourCommand();
      } else {
        await _stopPlayback();
      }
    }
    // Enhanced resume controls
    else if (command.contains('resume') ||
        command.contains('continue') ||
        command.contains('unpause') ||
        command.contains('restart')) {
      await _resumePlayback();
    }
    // Enhanced navigation
    else if (command.contains('next') ||
        command.contains('forward') ||
        command.contains('skip')) {
      await _nextTour();
    } else if (command.contains('previous') ||
        command.contains('back') ||
        command.contains('last')) {
      await _previousTour();
    }
    // Enhanced status and information
    else if (command.contains('status') ||
        command.contains('what') ||
        command.contains('current') ||
        command.contains('playing')) {
      await _handlePlaybackStatusCommand();
    } else if (command.contains('list') ||
        command.contains('show') ||
        command.contains('tours') ||
        command.contains('options')) {
      await _speakAvailableDownloads();
    } else if (command.contains('repeat') ||
        command.contains('again') ||
        command.contains('read')) {
      await _speakAvailableDownloads();
    }
    // Enhanced download management
    else if (command.contains('download') || command.contains('get')) {
      if (command.contains('all') || command.contains('everything')) {
        await _downloadAll();
      } else {
        await _audioManagerService.speakIfActive(
          'downloads',
          "Say 'download all' to get all tours, or 'list tours' to see what's available.",
        );
      }
    } else if (command.contains('delete') ||
        command.contains('remove') ||
        command.contains('clear')) {
      await _deleteDownloads();
    }
    // Enhanced volume and speed controls
    else if (command.contains('volume') ||
        command.contains('loud') ||
        command.contains('quiet')) {
      await _handleVolumeControlCommand(command);
    } else if (command.contains('speed') ||
        command.contains('fast') ||
        command.contains('slow')) {
      await _handleSpeedControlCommand(command);
    }
    // Enhanced navigation
    else if (command.contains('go back') ||
        command.contains('return') ||
        command.contains('exit') ||
        command.contains('home')) {
      await _navigateBack();
    }
    // Enhanced help
    else if (command.contains('help') ||
        command.contains('assist') ||
        command.contains('guide')) {
      await _handleDownloadsHelpCommand();
    }
    // Enhanced ambient sound controls
    else if (command.contains('ambient') ||
        command.contains('atmosphere') ||
        command.contains('background') ||
        command.contains('sound') ||
        command.contains('ambient volume') ||
        command.contains('loop ambient')) {
      await _handleAmbientSoundCommand(command);
    }
    // Enhanced silence controls
    else if (command.contains('silence') ||
        command.contains('quiet') ||
        command.contains('mute') ||
        command.contains('stop talking')) {
      await _audioManagerService.stopAllAudio();
    }
    // Unknown command - provide helpful feedback
    else {
      await _provideContextualHelp();
    }
  }

  // Enhanced tour selection and playback for blind users
  Future<void> _selectAndPlayTour(int index) async {
    if (index >= 0 && index < _downloads.length) {
      _currentTourIndex = index;
      final tour = _downloads[index];

      if (tour['status'] == 'Downloaded') {
        // Provide immediate feedback and start playing
        await _audioManagerService.speakIfActive(
          'downloads',
          "Selected and starting ${tour['name']}. ${tour['description']}",
        );
        _playTour(tour['name']);

        // Provide additional controls after a brief pause
        await Future.delayed(Duration(seconds: 2));
        await _audioManagerService.speakIfActive(
          'downloads',
          "Tour is now playing. Say 'pause' to pause, 'stop' to stop, 'next' for next tour, 'previous' for previous tour, 'ambient' for background sounds, or 'status' to check progress.",
        );
      } else {
        await _audioManagerService.speakIfActive(
          'downloads',
          "${tour['name']} is ${tour['status']}. Say 'download all' to get all tours, or 'select' followed by another tour name.",
        );
      }
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Tour not available. Say 'list tours' to hear all options, or 'select' followed by a tour name.",
      );
    }
  }

  // Enhanced contextual help for blind users
  Future<void> _provideContextualHelp() async {
    String helpMessage =
        "I didn't understand that command. Here's what you can do: ";

    if (_currentTourIndex >= 0 && _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      helpMessage += "You have ${tour['name']} selected. ";

      if (_isPlaying) {
        helpMessage +=
            "Tour is currently playing. Say 'pause' to pause, 'stop' to stop, or 'status' to check progress. ";
      } else if (_isPaused) {
        helpMessage +=
            "Tour is paused. Say 'resume' to continue, 'stop' to stop, or 'play' to restart. ";
      } else {
        helpMessage +=
            "Say 'play' to start the tour, 'next' for next tour, or 'previous' for previous tour. ";
      }
    } else {
      helpMessage +=
          "No tour selected. Say 'select one' through 'select four' to choose a tour, or 'list tours' to hear all options. ";
    }

    helpMessage +=
        "You can also say 'ambient' for background sounds, 'volume' to adjust volume, 'speed' to change playback speed, or 'help' for full instructions.";

    await _audioManagerService.speakIfActive('downloads', helpMessage);
  }

  // Downloads command handlers
  Future<void> _handlePlayCurrentTourCommand() async {
    if (_currentTourIndex >= 0 && _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      await _audioManagerService.speakIfActive(
        'downloads',
        "Playing ${tour['name']}. ${tour['description']}",
      );
      _playTour(tour['name']);
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "No tour selected. Say 'one' through 'four' to select a tour first.",
      );
    }
  }

  Future<void> _handleDownloadsHelpCommand() async {
    String helpMessage = "Here are all the voice commands for your downloads: ";

    // Tour selection
    helpMessage +=
        "To select tours, say 'select one' through 'select four', or just say 'one', 'two', 'three', 'four'. ";
    helpMessage +=
        "You can also say 'select murchison', 'select kasubi', 'select bwindi', or 'select lake victoria'. ";

    // Playback controls
    helpMessage +=
        "To control playback, say 'play' or 'start' to begin, 'pause' to pause temporarily, 'stop' to stop completely. ";
    helpMessage +=
        "Say 'resume' or 'continue' to unpause, 'restart' to start over. ";

    // Navigation
    helpMessage +=
        "To navigate, say 'next' or 'forward' for the next tour, 'previous' or 'back' for the previous tour. ";
    helpMessage += "Say 'skip' to jump to the next tour. ";

    // Status and information
    helpMessage +=
        "To get information, say 'status' or 'what's playing' to check current playback. ";
    helpMessage +=
        "Say 'list tours' or 'show options' to hear all available tours. ";
    helpMessage += "Say 'repeat' or 'read again' to hear the tour list again. ";

    // Ambient sounds
    helpMessage +=
        "For ambient sounds, say 'ambient' to start background sounds, 'next ambient' or 'previous ambient' to switch sounds. ";
    helpMessage +=
        "Say 'stop ambient' to stop, 'ambient volume up' or 'down' to adjust volume. ";
    helpMessage +=
        "Say 'list ambient' to hear all ambient options, 'loop ambient' to toggle continuous playback. ";

    // Volume and speed
    helpMessage +=
        "For volume control, say 'volume up' or 'louder' to increase, 'volume down' or 'quieter' to decrease. ";
    helpMessage += "Say 'mute' to silence, 'unmute' to restore sound. ";
    helpMessage +=
        "For speed control, say 'speed up' or 'faster' to increase, 'speed down' or 'slower' to decrease. ";
    helpMessage += "Say 'normal speed' to reset to default. ";

    // Download management
    helpMessage +=
        "To manage downloads, say 'download all' to get all tours, 'delete downloads' to remove them. ";

    // Navigation
    helpMessage +=
        "Say 'go back' or 'return' to go back to the previous screen. ";

    // Contextual help
    helpMessage +=
        "If you're unsure what to say, just ask for 'help' anytime, or say 'what can I do' for suggestions. ";

    await _audioManagerService.speakIfActive('downloads', helpMessage);
  }

  Future<void> _handlePauseTourCommand() async {
    if (_isPlaying && _currentlyPlaying != null) {
      _pausePlayback();
      await _audioManagerService.speakIfActive(
        'downloads',
        "Tour paused. Say 'play' to resume, 'next' for next tour, 'previous' for previous tour, or 'repeat' to hear options.",
      );
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "No tour is currently playing. Say 'one' through 'four' to select a tour, or 'repeat' to hear options.",
      );
    }
  }

  Future<void> _handlePlaybackStatusCommand() async {
    if (_isPlaying && _currentlyPlaying != null) {
      String statusMessage = "Currently playing: $_currentlyPlaying. ";
      statusMessage +=
          "Progress: ${(_playbackProgress * 100).toStringAsFixed(0)}% complete. ";

      if (_isAmbientMode && _isAmbientPlaying) {
        statusMessage += "Ambient sounds are also playing. ";
      }

      statusMessage +=
          "Say 'pause' to pause, 'stop' to stop, 'next' for next tour, or 'status' to check again.";

      await _audioManagerService.speakIfActive('downloads', statusMessage);
    } else if (_isPaused && _pausedTour.isNotEmpty) {
      String statusMessage = "Tour is paused: $_pausedTour. ";
      statusMessage +=
          "Progress: ${(_playbackProgress * 100).toStringAsFixed(0)}% complete. ";
      statusMessage +=
          "Say 'resume' to continue, 'stop' to stop completely, or 'play' to restart.";

      await _audioManagerService.speakIfActive('downloads', statusMessage);
    } else if (_currentTourIndex >= 0 &&
        _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      String statusMessage = "No tour is currently playing. ";
      statusMessage += "You have ${tour['name']} selected. ";
      statusMessage +=
          "Say 'play' to start this tour, 'next' for next tour, 'previous' for previous tour, or 'list tours' to see all options.";

      await _audioManagerService.speakIfActive('downloads', statusMessage);
    } else {
      String statusMessage = "No tour is currently playing or selected. ";
      statusMessage +=
          "Say 'select one' through 'select four' to choose a tour, or 'list tours' to hear all available options.";

      await _audioManagerService.speakIfActive('downloads', statusMessage);
    }
  }

  Future<void> _handleVolumeControlCommand(String command) async {
    if (command.contains('up') ||
        command.contains('increase') ||
        command.contains('louder') ||
        command.contains('higher')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Volume increased. Say 'volume down' to lower it, or 'mute' to silence.",
      );
    } else if (command.contains('down') ||
        command.contains('decrease') ||
        command.contains('quieter') ||
        command.contains('lower')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Volume decreased. Say 'volume up' to raise it, or 'mute' to silence.",
      );
    } else if (command.contains('mute') ||
        command.contains('silence') ||
        command.contains('quiet')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Audio muted. Say 'unmute' or 'volume up' to restore sound.",
      );
    } else if (command.contains('unmute') ||
        command.contains('restore') ||
        command.contains('sound')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Audio restored. Say 'volume up' or 'volume down' to adjust.",
      );
    } else if (command.contains('maximum') ||
        command.contains('full') ||
        command.contains('loudest')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Volume set to maximum. Say 'volume down' to lower it.",
      );
    } else if (command.contains('minimum') || command.contains('lowest')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Volume set to minimum. Say 'volume up' to raise it.",
      );
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Say 'volume up' to increase, 'volume down' to decrease, or 'mute' to silence.",
      );
    }
  }

  Future<void> _handleSpeedControlCommand(String command) async {
    if (command.contains('up') ||
        command.contains('increase') ||
        command.contains('faster') ||
        command.contains('speed up')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Playback speed increased. Say 'speed down' to slow it down, or 'normal speed' to reset.",
      );
    } else if (command.contains('down') ||
        command.contains('decrease') ||
        command.contains('slower') ||
        command.contains('speed down')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Playback speed decreased. Say 'speed up' to make it faster, or 'normal speed' to reset.",
      );
    } else if (command.contains('normal') ||
        command.contains('reset') ||
        command.contains('default')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Playback speed reset to normal. Say 'speed up' to make it faster, or 'speed down' to slow it down.",
      );
    } else if (command.contains('fast') || command.contains('quick')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Playback speed set to fast. Say 'normal speed' to reset, or 'speed down' to slow it down.",
      );
    } else if (command.contains('slow') || command.contains('slowly')) {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Playback speed set to slow. Say 'normal speed' to reset, or 'speed up' to make it faster.",
      );
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Say 'speed up' to make it faster, 'speed down' to slow it down, or 'normal speed' to reset.",
      );
    }
  }

  Future<void> _navigateBack() async {
    await _audioManagerService.speakIfActive(
      'downloads',
      "Going back to previous screen.",
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Ambient sound methods
  Future<void> _handleAmbientSoundCommand(String command) async {
    if (command.contains('ambient') ||
        command.contains('atmosphere') ||
        command.contains('background')) {
      await _toggleAmbientMode();
    } else if (command.contains('next ambient') ||
        command.contains('next sound')) {
      await _nextAmbientSound();
    } else if (command.contains('previous ambient') ||
        command.contains('previous sound')) {
      await _previousAmbientSound();
    } else if (command.contains('stop ambient') ||
        command.contains('stop background')) {
      await _stopAmbientSound();
    } else if (command.contains('ambient volume') ||
        command.contains('background volume')) {
      await _adjustAmbientVolume(command);
    } else if (command.contains('loop ambient') ||
        command.contains('repeat ambient')) {
      await _toggleAmbientLoop();
    } else if (command.contains('list ambient') ||
        command.contains('ambient sounds')) {
      await _listAmbientSounds();
    }
  }

  Future<void> _toggleAmbientMode() async {
    if (_currentTourIndex >= 0 && _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      final ambientSounds = tour['ambientSounds'] as List<dynamic>?;

      if (ambientSounds != null && ambientSounds.isNotEmpty) {
        _isAmbientMode = !_isAmbientMode;

        if (_isAmbientMode) {
          _currentAmbientIndex = 0;
          await _playAmbientSound(ambientSounds[0]);
          await _audioManagerService.speakIfActive(
            'downloads',
            "Ambient mode activated. Playing ${ambientSounds[0]['name']} for ${tour['name']}. Say 'next ambient' to change sounds, 'stop ambient' to stop, or 'list ambient' to hear all options.",
          );
        } else {
          await _stopAmbientSound();
          await _audioManagerService.speakIfActive(
            'downloads',
            "Ambient mode deactivated.",
          );
        }
      } else {
        await _audioManagerService.speakIfActive(
          'downloads',
          "No ambient sounds available for this tour. Select a different tour with 'one' through 'four'.",
        );
      }
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Please select a tour first with 'one' through 'four' to access ambient sounds.",
      );
    }
  }

  Future<void> _playAmbientSound(Map<String, dynamic> ambientSound) async {
    _isAmbientPlaying = true;

    try {
      // Play the actual ambient sound file
      String fileName = ambientSound['file'];
      await _playAmbientSoundFile(fileName);

      await _audioManagerService.speakIfActive(
        'downloads',
        "Playing ${ambientSound['name']}: ${ambientSound['description']}",
      );
    } catch (e) {
      debugPrint('Error playing ambient sound: $e');
      await _audioManagerService.speakIfActive(
        'downloads',
        "Error playing ambient sound. Please try again.",
      );
    }
  }

  Future<void> _playCurrentAmbientSound() async {
    if (_currentTourIndex >= 0 && _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      final ambientSounds = tour['ambientSounds'] as List<dynamic>?;

      if (ambientSounds != null &&
          _currentAmbientIndex >= 0 &&
          _currentAmbientIndex < ambientSounds.length) {
        await _playAmbientSound(ambientSounds[_currentAmbientIndex]);
      }
    }
  }

  Future<void> _nextAmbientSound() async {
    if (_currentTourIndex >= 0 && _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      final ambientSounds = tour['ambientSounds'] as List<dynamic>?;

      if (ambientSounds != null && ambientSounds.isNotEmpty) {
        _currentAmbientIndex =
            (_currentAmbientIndex + 1) % ambientSounds.length;
        await _playAmbientSound(ambientSounds[_currentAmbientIndex]);
        await _audioManagerService.speakIfActive(
          'downloads',
          "Switched to ${ambientSounds[_currentAmbientIndex]['name']}.",
        );
      }
    }
  }

  Future<void> _previousAmbientSound() async {
    if (_currentTourIndex >= 0 && _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      final ambientSounds = tour['ambientSounds'] as List<dynamic>?;

      if (ambientSounds != null && ambientSounds.isNotEmpty) {
        _currentAmbientIndex =
            (_currentAmbientIndex - 1 + ambientSounds.length) %
            ambientSounds.length;
        await _playAmbientSound(ambientSounds[_currentAmbientIndex]);
        await _audioManagerService.speakIfActive(
          'downloads',
          "Switched to ${ambientSounds[_currentAmbientIndex]['name']}.",
        );
      }
    }
  }

  Future<void> _stopAmbientSound() async {
    try {
      await _ambientPlayer.stop();
      _isAmbientPlaying = false;
      _playbackTimer?.cancel();

      await _audioManagerService.speakIfActive(
        'downloads',
        "Ambient sounds stopped.",
      );
    } catch (e) {
      debugPrint('Error stopping ambient sound: $e');
    }
  }

  Future<void> _adjustAmbientVolume(String command) async {
    if (command.contains('up') || command.contains('increase')) {
      _ambientVolume = (_ambientVolume + 0.1).clamp(0.0, 1.0);
      await _ambientPlayer.setVolume(_ambientVolume);
      await _audioManagerService.speakIfActive(
        'downloads',
        "Ambient volume increased to ${(_ambientVolume * 100).round()}%.",
      );
    } else if (command.contains('down') || command.contains('decrease')) {
      _ambientVolume = (_ambientVolume - 0.1).clamp(0.0, 1.0);
      await _ambientPlayer.setVolume(_ambientVolume);
      await _audioManagerService.speakIfActive(
        'downloads',
        "Ambient volume decreased to ${(_ambientVolume * 100).round()}%.",
      );
    } else if (command.contains('mute')) {
      _ambientVolume = 0.0;
      await _ambientPlayer.setVolume(_ambientVolume);
      await _audioManagerService.speakIfActive(
        'downloads',
        "Ambient sounds muted.",
      );
    } else if (command.contains('full') || command.contains('maximum')) {
      _ambientVolume = 1.0;
      await _ambientPlayer.setVolume(_ambientVolume);
      await _audioManagerService.speakIfActive(
        'downloads',
        "Ambient volume set to maximum.",
      );
    }
  }

  Future<void> _toggleAmbientLoop() async {
    _isAmbientLoop = !_isAmbientLoop;
    await _audioManagerService.speakIfActive(
      'downloads',
      _isAmbientLoop
          ? "Ambient sounds will loop continuously."
          : "Ambient sounds will play once.",
    );
  }

  Future<void> _listAmbientSounds() async {
    if (_currentTourIndex >= 0 && _currentTourIndex < _downloads.length) {
      final tour = _downloads[_currentTourIndex];
      final ambientSounds = tour['ambientSounds'] as List<dynamic>?;

      if (ambientSounds != null && ambientSounds.isNotEmpty) {
        String ambientList = "Available ambient sounds for ${tour['name']}: ";
        for (int i = 0; i < ambientSounds.length; i++) {
          final sound = ambientSounds[i];
          ambientList +=
              "${i + 1}. ${sound['name']}, ${sound['description']}, ${sound['duration']}. ";
        }
        ambientList +=
            "Say 'ambient' to start, 'next ambient' to change, or 'stop ambient' to stop.";

        await _audioManagerService.speakIfActive('downloads', ambientList);
      } else {
        await _audioManagerService.speakIfActive(
          'downloads',
          "No ambient sounds available for this tour.",
        );
      }
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "Please select a tour first with 'one' through 'four' to see ambient sounds.",
      );
    }
  }

  // Enhanced navigation methods for blind users
  Future<void> _nextTour() async {
    if (_downloads.isNotEmpty) {
      _currentTourIndex = (_currentTourIndex + 1) % _downloads.length;
      final tour = _downloads[_currentTourIndex];

      String navigationMessage = "Moved to next tour: ${tour['name']}. ";
      navigationMessage += "${tour['description']} ";

      if (tour['status'] == 'Downloaded') {
        navigationMessage += "This tour is ready to play. ";
        navigationMessage +=
            "Say 'play' to start immediately, 'select' to confirm selection, or 'next' to continue browsing.";
      } else {
        navigationMessage += "This tour is ${tour['status']}. ";
        navigationMessage +=
            "Say 'download all' to get all tours, or 'next' to see more options.";
      }

      await _audioManagerService.speakIfActive('downloads', navigationMessage);
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "No tours available. Say 'download all' to get tours, or 'go back' to return.",
      );
    }
  }

  Future<void> _previousTour() async {
    if (_downloads.isNotEmpty) {
      _currentTourIndex =
          (_currentTourIndex - 1 + _downloads.length) % _downloads.length;
      final tour = _downloads[_currentTourIndex];

      String navigationMessage = "Moved to previous tour: ${tour['name']}. ";
      navigationMessage += "${tour['description']} ";

      if (tour['status'] == 'Downloaded') {
        navigationMessage += "This tour is ready to play. ";
        navigationMessage +=
            "Say 'play' to start immediately, 'select' to confirm selection, or 'previous' to continue browsing.";
      } else {
        navigationMessage += "This tour is ${tour['status']}. ";
        navigationMessage +=
            "Say 'download all' to get all tours, or 'previous' to see more options.";
      }

      await _audioManagerService.speakIfActive('downloads', navigationMessage);
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "No tours available. Say 'download all' to get tours, or 'go back' to return.",
      );
    }
  }

  // Audio playback methods
  Future<void> _playTour(String tourName) async {
    final tour = _downloads.firstWhere(
      (d) => d['name'].toLowerCase().contains(tourName.toLowerCase()),
      orElse: () => _downloads[0],
    );

    if (tour['status'] != 'Downloaded') {
      await _audioManagerService.speakIfActive(
        'downloads',
        "${tour['name']} is not downloaded yet. Please download it first.",
      );
      return;
    }

    // Stop any current playback
    _playbackTimer?.cancel();
    _progressTimer?.cancel();

    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _currentlyPlaying = tour['name'];
      _pausedTour = '';
      _playbackProgress = 0.0;
    });

    await _audioManagerService.speakIfActive(
      'downloads',
      "Now playing ${tour['name']}. ${tour['description']}",
    );

    // Start progress tracking
    _startPlaybackProgress();

    // Simulate audio playback with longer duration
    _playbackTimer = Timer(Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlaying = null;
          _playbackProgress = 0.0;
        });
        _audioManagerService.speakIfActive(
          'downloads',
          "Tour playback completed. Say 'play another tour' or 'go back' to return to home.",
        );
      }
    });
  }

  Future<void> _stopPlayback() async {
    _playbackTimer?.cancel();
    _progressTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentlyPlaying = null;
      _pausedTour = '';
      _playbackProgress = 0.0;
    });
    await _audioManagerService.speakIfActive('downloads', "Playback stopped.");
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _progressTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
      _pausedTour = _currentlyPlaying ?? '';
    });
  }

  Future<void> _resumePlayback() async {
    if (_isPaused && _pausedTour.isNotEmpty) {
      setState(() {
        _isPlaying = true;
        _isPaused = false;
        _currentlyPlaying = _pausedTour;
        _pausedTour = '';
      });

      await _audioManagerService.speakIfActive(
        'downloads',
        "Resuming playback of $_currentlyPlaying.",
      );

      _startPlaybackProgress();
    }
  }

  Future<void> _playNextTour() async {
    if (_currentlyPlaying != null) {
      int currentIndex = _downloads.indexWhere(
        (d) => d['name'] == _currentlyPlaying,
      );
      if (currentIndex != -1 && currentIndex < _downloads.length - 1) {
        String nextTour = _downloads[currentIndex + 1]['name'];
        await _playTour(nextTour);
      } else {
        await _audioManagerService.speakIfActive(
          'downloads',
          "No more tours available. This is the last tour in the list.",
        );
      }
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "No tour is currently playing. Say 'play tour' followed by tour name to start.",
      );
    }
  }

  Future<void> _playPreviousTour() async {
    if (_currentlyPlaying != null) {
      int currentIndex = _downloads.indexWhere(
        (d) => d['name'] == _currentlyPlaying,
      );
      if (currentIndex > 0) {
        String previousTour = _downloads[currentIndex - 1]['name'];
        await _playTour(previousTour);
      } else {
        await _audioManagerService.speakIfActive(
          'downloads',
          "No previous tours available. This is the first tour in the list.",
        );
      }
    } else {
      await _audioManagerService.speakIfActive(
        'downloads',
        "No tour is currently playing. Say 'play tour' followed by tour name to start.",
      );
    }
  }

  void _startPlaybackProgress() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _playbackProgress = (_playbackProgress + 0.01).clamp(0.0, 1.0);
        });

        if (_playbackProgress >= 1.0) {
          timer.cancel();
          _stopPlayback();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _downloadAll() async {
    await _audioManagerService.speakIfActive(
      'downloads',
      "Starting download of all available content. This may take a few minutes.",
    );

    // Simulate download process
    for (int i = 0; i < _downloads.length; i++) {
      if (_downloads[i]['status'] == 'Available') {
        setState(() {
          _downloads[i]['status'] = 'Downloading...';
        });

        await Future.delayed(Duration(seconds: 2));

        setState(() {
          _downloads[i]['status'] = 'Downloaded';
        });
      }
    }

    await _audioManagerService.speakIfActive(
      'downloads',
      "All downloads completed successfully. You can now play any tour by saying 'one' through 'four' or 'play tour' followed by the tour name.",
    );
  }

  Future<void> _deleteDownloads() async {
    await _audioManagerService.speakIfActive(
      'downloads',
      "Deleting all downloaded content. This will free up storage space.",
    );

    setState(() {
      for (int i = 0; i < _downloads.length; i++) {
        if (_downloads[i]['status'] == 'Downloaded') {
          _downloads[i]['status'] = 'Available';
        }
      }
    });

    await _audioManagerService.speakIfActive(
      'downloads',
      "All downloads have been deleted. Content is still available for re-download.",
    );
  }

  @override
  void dispose() {
    _ambientPlayer.dispose();
    _tourPlayer.dispose();
    _playbackTimer?.cancel();
    _progressTimer?.cancel();
    tts.stop();
    speech.stop();
    _audioControlSubscription?.cancel();
    _screenActivationSubscription?.cancel();
    _transitionSubscription?.cancel();

    _navigationCommandSubscription?.cancel();
    _downloadsCommandSubscription?.cancel();
    _audioManagerService.unregisterScreen('downloads');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Offline Downloads"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
                _speakAvailableDownloads();
              }
            },
            tooltip: _isNarrating ? 'Stop Narration' : 'Start Narration',
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: _navigateBack,
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
                        ? "Paused - Tour ${_currentTourIndex + 1}"
                        : _isNarrating
                        ? "Narrating offline content..."
                        : "Tap downloads or use voice commands",
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
                          await _resumePlayback();
                        } else {
                          _pausePlayback();
                        }
                      },
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: _isPaused ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                      tooltip: _isPaused ? 'Play' : 'Pause',
                    ),
                    // Next button
                    IconButton(
                      onPressed: () async {
                        await _nextTour();
                      },
                      icon: Icon(Icons.skip_next, color: Colors.blue, size: 24),
                      tooltip: 'Next Tour',
                    ),
                    // Previous button
                    IconButton(
                      onPressed: () async {
                        await _previousTour();
                      },
                      icon: Icon(
                        Icons.skip_previous,
                        color: Colors.blue,
                        size: 24,
                      ),
                      tooltip: 'Previous Tour',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.download),
                        label: Text("Download All"),
                        onPressed: _downloadAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text("Delete All"),
                        onPressed: _deleteDownloads,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isPlaying || _isPaused) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.skip_previous),
                          label: Text("Previous"),
                          onPressed: _playPreviousTour,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                          ),
                          label: Text(_isPaused ? "Resume" : "Pause"),
                          onPressed:
                              _isPaused ? _resumePlayback : _pausePlayback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isPaused ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.skip_next),
                          label: Text("Next"),
                          onPressed: _playNextTour,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Downloads list
          Expanded(
            child: ListView.builder(
              itemCount: _downloads.length,
              itemBuilder: (context, index) {
                final download = _downloads[index];
                final isCurrentlyPlaying =
                    _currentlyPlaying == download['name'];

                return Card(
                  color:
                      isCurrentlyPlaying
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.grey[900],
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
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
                      download['name']!,
                      style: TextStyle(
                        color: isCurrentlyPlaying ? Colors.blue : Colors.white,
                        fontWeight:
                            isCurrentlyPlaying
                                ? FontWeight.bold
                                : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          "${download['status']} • ${download['size']} • ${download['duration']}",
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          download['description']!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Say '${index + 1 == 1
                              ? 'one'
                              : index + 1 == 2
                              ? 'two'
                              : index + 1 == 3
                              ? 'three'
                              : 'four'}' or 'play ${download['name']}' to start",
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (isCurrentlyPlaying)
                          Text(
                            "Now playing...",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (download['status'] == 'Downloading...')
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          )
                        else if (download['status'] == 'Downloaded')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isPaused && _pausedTour == download['name'])
                                IconButton(
                                  icon: Icon(
                                    Icons.play_arrow,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _resumePlayback(),
                                )
                              else if (isCurrentlyPlaying)
                                IconButton(
                                  icon: Icon(Icons.pause, color: Colors.orange),
                                  onPressed: () => _pausePlayback(),
                                )
                              else
                                IconButton(
                                  icon: Icon(
                                    Icons.play_arrow,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _playTour(download['name']),
                                ),
                              if (isCurrentlyPlaying)
                                IconButton(
                                  icon: Icon(Icons.stop, color: Colors.red),
                                  onPressed: () => _stopPlayback(),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Enhanced voice control tips for blind users
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Text(
                  "Voice Commands",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Say 'select one' through 'select four' to choose tours • 'play' to start • 'pause' to pause • 'next' or 'previous' to navigate • 'ambient' for background sounds • 'status' to check progress • 'help' for all commands",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  "Natural commands: 'select murchison', 'play current tour', 'what's playing', 'volume up', 'speed down'",
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

  Future<void> _playAmbientSoundFile(String fileName) async {
    try {
      // Play the actual ambient sound file from assets
      await _ambientPlayer.play(AssetSource('ambient/$fileName'));
      await _ambientPlayer.setVolume(_ambientVolume);
      debugPrint('Playing ambient sound file: $fileName');
    } catch (e) {
      debugPrint('Error playing ambient sound file: $e');
      rethrow;
    }
  }
}
