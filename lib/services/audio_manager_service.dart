// ignore_for_file: empty_catches

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AudioManagerService {
  static final AudioManagerService _instance = AudioManagerService._internal();
  factory AudioManagerService() => _instance;
  AudioManagerService._internal();

  String? _activeScreenId;
  final Map<String, FlutterTts> _screenTtsInstances = {};
  final Map<String, stt.SpeechToText> _screenSpeechInstances = {};
  final StreamController<String> _audioControlController =
      StreamController<String>.broadcast();
  final StreamController<String> _screenActivationController =
      StreamController<String>.broadcast();
  final StreamController<String> _audioStatusController =
      StreamController<String>.broadcast();
  final StreamController<String> _narrationControlController =
      StreamController<String>.broadcast();

  // Debounce timer for audio status updates
  Timer? _audioStatusDebounceTimer;
  String? _lastAudioStatus;

  // Audio transition management
  Timer? _transitionTimer;
  bool _isTransitioning = false;
  final List<String> _pendingAudioQueue = [];

  // Narration control management
  final Map<String, bool> _narrationEnabled = {};
  final Map<String, Timer?> _narrationTimers = {};
  final Map<String, Duration> _narrationIntervals = {};
  final Map<String, bool> _narrationPaused = {};
  final Map<String, int> _narrationPriorities = {};
  final Map<String, DateTime?> _lastUserInteraction = {};
  static const Duration _userInteractionTimeout = Duration(seconds: 30);

  // Streams for UI to listen to
  Stream<String> get audioControlStream => _audioControlController.stream;
  Stream<String> get screenActivationStream =>
      _screenActivationController.stream;
  Stream<String> get audioStatusStream => _audioStatusController.stream;
  Stream<String> get narrationControlStream =>
      _narrationControlController.stream;

  // Initialize the service
  Future<void> initialize() async {
    _audioStatusController.add('initialized');
  }

  // Register a screen for audio management
  void registerScreen(
    String screenId,
    FlutterTts tts,
    stt.SpeechToText speech,
  ) {
    _screenTtsInstances[screenId] = tts;
    _screenSpeechInstances[screenId] = speech;
    _audioStatusController.add('registered:$screenId');
  }

  // Unregister a screen
  void unregisterScreen(String screenId) {
    _screenTtsInstances.remove(screenId);
    _screenSpeechInstances.remove(screenId);
    if (_activeScreenId == screenId) {
      _activeScreenId = null;
    }
    _audioStatusController.add('unregistered:$screenId');
  }

  // Activate audio for a specific screen with smooth transition and verification
  Future<void> activateScreenAudio(String screenId) async {
    // Prevent infinite loops by checking if already active
    if (_activeScreenId == screenId && !_isTransitioning) {
      debugPrint('Audio already active for screen: $screenId');
      return;
    }

    if (_isTransitioning) {
      _pendingAudioQueue.add('activate:$screenId');
      return;
    }

    _isTransitioning = true;
    _audioStatusController.add('transitioning:$screenId');

    try {
      // Deactivate audio for previously active screen
      if (_activeScreenId != null && _activeScreenId != screenId) {
        await _deactivateScreenAudio(_activeScreenId!);

        // Special handling for map screen deactivation
        if (_activeScreenId == 'map') {
          await _handleMapScreenDeactivation();
        }

        // Reduced delay for smoother transition
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Activate audio for new screen
      _activeScreenId = screenId;
      _audioControlController.add('activated:$screenId');
      _screenActivationController.add(screenId);

      // Throttle status updates to reduce frame skipping
      Future.delayed(const Duration(milliseconds: 300), () {
        _addDebouncedAudioStatus('activated:$screenId');
      });

      // Verify activation
      _verifyScreenActivation(screenId);
    } catch (e) {
      _audioStatusController.add('error:activation:$screenId');
    } finally {
      _isTransitioning = false;

      // Process any pending audio operations
      if (_pendingAudioQueue.isNotEmpty) {
        final nextOperation = _pendingAudioQueue.removeAt(0);
        _processPendingAudioOperation(nextOperation);
      }
    }
  }

  // Handle map screen deactivation specifically with complete silence
  Future<void> _handleMapScreenDeactivation() async {
    try {
      // Force stop map TTS with multiple attempts
      final mapTts = _screenTtsInstances['map'];
      if (mapTts != null) {
        await mapTts.stop();
        await Future.delayed(const Duration(milliseconds: 50));
        await mapTts.stop(); // Second attempt
      }

      // Force stop map speech recognition
      final mapSpeech = _screenSpeechInstances['map'];
      if (mapSpeech != null) {
        await mapSpeech.stop();
        await Future.delayed(const Duration(milliseconds: 50));
        await mapSpeech.stop(); // Second attempt
      }

      // Extended delay to ensure complete silence
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {}
  }

  // Process pending audio operations
  void _processPendingAudioOperation(String operation) {
    if (operation.startsWith('activate:')) {
      final screenId = operation.split(':')[1];
      activateScreenAudio(screenId);
    } else if (operation.startsWith('speak:')) {
      final parts = operation.split(':');
      if (parts.length >= 3) {
        final screenId = parts[1];
        final text = parts.sublist(2).join(':');
        speakIfActive(screenId, text);
      }
    }
  }

  // Deactivate audio for a specific screen
  Future<void> deactivateScreenAudio(String screenId) async {
    if (_activeScreenId == screenId) {
      await _deactivateScreenAudio(screenId);
      _activeScreenId = null;
      _audioControlController.add('deactivated:$screenId');
      _audioStatusController.add('deactivated:$screenId');
    }
  }

  // Internal method to deactivate screen audio
  Future<void> _deactivateScreenAudio(String screenId) async {
    final tts = _screenTtsInstances[screenId];
    final speech = _screenSpeechInstances[screenId];

    if (tts != null) {
      try {
        await tts.stop();
      } catch (e) {}
    }

    if (speech != null) {
      try {
        await speech.stop();
      } catch (e) {}
    }
  }

  // Check if a screen has active audio
  bool isScreenAudioActive(String screenId) {
    return _activeScreenId == screenId;
  }

  // Get the currently active screen
  String? get activeScreenId => _activeScreenId;

  // Add debounced audio status to prevent rapid updates
  void _addDebouncedAudioStatus(String status) {
    // Cancel previous timer
    _audioStatusDebounceTimer?.cancel();

    // Only update if status has changed
    if (_lastAudioStatus != status) {
      _lastAudioStatus = status;

      // Increased debounce time to reduce buffer issues
      _audioStatusDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _audioStatusController.add(status);
      });
    }
  }

  // Speak text only if the screen is active with strict audio isolation
  Future<void> speakIfActive(String screenId, String text) async {
    if (_isTransitioning) {
      _pendingAudioQueue.add('speak:$screenId:$text');
      return;
    }

    // STRICT CHECK: Only allow audio from the currently active screen
    if (!isScreenAudioActive(screenId)) {
      _audioStatusController.add('blocked:$screenId');
      return;
    }

    final tts = _screenTtsInstances[screenId];
    if (tts != null) {
      try {
        // Immediately stop ALL other TTS instances to prevent background audio
        await _forceStopAllOtherTtsInstances(screenId);

        // Small delay to ensure complete audio isolation
        await Future.delayed(const Duration(milliseconds: 150));

        // Configure TTS for better accent and tone support
        await _configureTtsForScreen(tts, screenId);

        await tts.speak(text);
        _audioStatusController.add('spoke:$screenId');
      } catch (e) {
        _audioStatusController.add('error:speak:$screenId');
      }
    } else {
      _audioStatusController.add('error:no_tts:$screenId');
    }
  }

  // Centralized method to handle immediate speech interruption
  Future<void> interruptAndSpeak(String screenId, String text) async {
    try {
      // Immediately stop all audio
      await stopAllAudio();

      // Small delay to ensure clean stop
      await Future.delayed(const Duration(milliseconds: 150));

      // Speak the new text
      await speakIfActive(screenId, text);
    } catch (e) {}
  }

  // Enhanced method to handle screen-specific narration
  Future<void> narrateForScreen(
    String screenId,
    String text, {
    bool interrupt = false,
  }) async {
    if (interrupt) {
      await interruptAndSpeak(screenId, text);
    } else {
      await speakIfActive(screenId, text);
    }
  }

  // Configure TTS for different tones and accents based on screen
  Future<void> _configureTtsForScreen(FlutterTts tts, String screenId) async {
    try {
      switch (screenId) {
        case 'discover':
          // More enthusiastic tone for tour discovery
          await tts.setPitch(1.1);
          await tts.setSpeechRate(0.45);
          // Use default voice instead of specific voice name
          break;
        case 'map':
          // Calm, informative tone for map guidance
          await tts.setPitch(1.0);
          await tts.setSpeechRate(0.5);
          // Use default voice instead of specific voice name
          break;
        case 'downloads':
          // Clear, helpful tone for downloads
          await tts.setPitch(1.05);
          await tts.setSpeechRate(0.48);
          // Use default voice instead of specific voice name
          break;
        case 'help':
          // Patient, instructional tone for help
          await tts.setPitch(0.95);
          await tts.setSpeechRate(0.42);
          // Use default voice instead of specific voice name
          break;
        default:
          // Default configuration for home and other screens
          await tts.setPitch(1.0);
          await tts.setSpeechRate(0.5);
        // Use default voice instead of specific voice name
      }
    } catch (e) {}
  }

  // Force stop ALL other TTS instances for strict audio isolation
  Future<void> _forceStopAllOtherTtsInstances(String activeScreenId) async {
    final stopPromises = <Future<void>>[];

    for (final entry in _screenTtsInstances.entries) {
      if (entry.key != activeScreenId) {
        stopPromises.add(_forceStopTtsInstance(entry.key, entry.value));
      }
    }

    // Force stop all other TTS instances concurrently
    await Future.wait(stopPromises);
  }

  // Force stop a single TTS instance with retry
  Future<void> _forceStopTtsInstance(String screenId, FlutterTts tts) async {
    try {
      // Multiple stop attempts to ensure complete silence
      await tts.stop();
      await Future.delayed(const Duration(milliseconds: 50));
      await tts.stop(); // Second attempt
    } catch (e) {}
  }

  // Start listening only if the screen is active
  Future<void> startListeningIfActive(
    String screenId,
    Function(dynamic) onResult,
  ) async {
    if (isScreenAudioActive(screenId)) {
      final speech = _screenSpeechInstances[screenId];
      if (speech != null) {
        try {
          await speech.listen(
            onResult: onResult,
            listenFor: const Duration(seconds: 10),
            pauseFor: const Duration(seconds: 3),
            listenOptions: stt.SpeechListenOptions(
              cancelOnError: false,
              listenMode: stt.ListenMode.confirmation,
              partialResults: false,
            ),
          );
          _audioStatusController.add('listening_started:$screenId');
        } catch (e) {
          _audioStatusController.add('error:listening:$screenId');
        }
      }
    }
  }

  // Stop listening for a specific screen
  Future<void> stopListening(String screenId) async {
    final speech = _screenSpeechInstances[screenId];
    if (speech != null) {
      try {
        await speech.stop();
        _audioStatusController.add('listening_stopped:$screenId');
      } catch (e) {
        _audioStatusController.add('error:stop_listening:$screenId');
      }
    }
  }

  // Stop all audio across all screens
  Future<void> stopAllAudio() async {
    // Prevent rapid calls to stopAllAudio
    if (_isTransitioning) {
      debugPrint('Audio transition already in progress, skipping stopAllAudio');
      return;
    }

    _isTransitioning = true;
    _pendingAudioQueue.clear();

    try {
      // Create a copy of the keys to avoid concurrent modification
      List<String> screenIds = List.from(_screenTtsInstances.keys);

      for (final screenId in screenIds) {
        await _deactivateScreenAudio(screenId);
      }
      _activeScreenId = null;
      _audioControlController.add('all_stopped');
      _addDebouncedAudioStatus('all_stopped');
    } finally {
      _isTransitioning = false;
    }
  }

  // Get TTS instance for a screen
  FlutterTts? getTtsForScreen(String screenId) {
    return _screenTtsInstances[screenId];
  }

  // Get Speech instance for a screen
  stt.SpeechToText? getSpeechForScreen(String screenId) {
    return _screenSpeechInstances[screenId];
  }

  // Check if audio transition is in progress
  bool get isTransitioning => _isTransitioning;

  // Get pending audio operations count
  int get pendingOperationsCount => _pendingAudioQueue.length;

  // Narration control methods
  void enableNarration(
    String screenId, {
    Duration? interval,
    int priority = 1,
  }) {
    _narrationEnabled[screenId] = true;
    _narrationIntervals[screenId] = interval ?? const Duration(seconds: 30);
    _narrationPriorities[screenId] = priority;
    _narrationPaused[screenId] = false;

    _narrationControlController.add('enabled:$screenId');

    // Start narration timer if screen is active
    if (_activeScreenId == screenId) {
      _startNarrationTimer(screenId);
    }
  }

  void disableNarration(String screenId) {
    _narrationEnabled[screenId] = false;
    _stopNarrationTimer(screenId);

    _narrationControlController.add('disabled:$screenId');
  }

  void pauseNarration(String screenId) {
    _narrationPaused[screenId] = true;
    _narrationControlController.add('paused:$screenId');
  }

  void resumeNarration(String screenId) {
    _narrationPaused[screenId] = false;
    _narrationControlController.add('resumed:$screenId');
  }

  void setNarrationInterval(String screenId, Duration interval) {
    _narrationIntervals[screenId] = interval;

    // Restart timer with new interval if currently running
    if (_narrationEnabled[screenId] == true && _activeScreenId == screenId) {
      _stopNarrationTimer(screenId);
      _startNarrationTimer(screenId);
    }
  }

  void setNarrationPriority(String screenId, int priority) {
    _narrationPriorities[screenId] = priority;
  }

  void recordUserInteraction(String screenId) {
    _lastUserInteraction[screenId] = DateTime.now();
  }

  // Check if should pause narration due to recent user interaction
  bool _shouldPauseForUserInteraction(String screenId) {
    final lastInteraction = _lastUserInteraction[screenId];
    if (lastInteraction == null) return false;

    final timeSinceInteraction = DateTime.now().difference(lastInteraction);
    return timeSinceInteraction < _userInteractionTimeout;
  }

  // Start narration timer for a screen
  void _startNarrationTimer(String screenId) {
    _stopNarrationTimer(screenId); // Stop existing timer

    final interval =
        _narrationIntervals[screenId] ?? const Duration(seconds: 30);
    _narrationTimers[screenId] = Timer.periodic(interval, (timer) {
      _triggerNarration(screenId);
    });
  }

  // Stop narration timer for a screen
  void _stopNarrationTimer(String screenId) {
    _narrationTimers[screenId]?.cancel();
    _narrationTimers[screenId] = null;
  }

  // Trigger narration for a screen
  void _triggerNarration(String screenId) {
    // Only narrate if screen is active and narration is enabled
    if (_activeScreenId != screenId || _narrationEnabled[screenId] != true) {
      return;
    }

    // Check if narration is paused
    if (_narrationPaused[screenId] == true) {
      return;
    }

    // Check if should pause due to recent user interaction
    if (_shouldPauseForUserInteraction(screenId)) {
      return;
    }

    // Check if audio manager is transitioning
    if (_isTransitioning) {
      return;
    }

    // Emit narration trigger event
    _narrationControlController.add('trigger:$screenId');
  }

  // Get narration status
  bool isNarrationEnabled(String screenId) =>
      _narrationEnabled[screenId] ?? false;
  bool isNarrationPaused(String screenId) =>
      _narrationPaused[screenId] ?? false;
  Duration getNarrationInterval(String screenId) =>
      _narrationIntervals[screenId] ?? const Duration(seconds: 30);
  int getNarrationPriority(String screenId) =>
      _narrationPriorities[screenId] ?? 1;

  // Verify screen activation
  void _verifyScreenActivation(String screenId) {
    if (_activeScreenId == screenId) {
    } else {}
  }

  // Dispose resources
  void dispose() {
    stopAllAudio();
    _transitionTimer?.cancel();

    // Stop all narration timers
    for (final screenId in _narrationTimers.keys) {
      _stopNarrationTimer(screenId);
    }

    _audioControlController.close();
    _screenActivationController.close();
    _audioStatusController.close();
    _narrationControlController.close();
  }
}
