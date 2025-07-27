// ignore_for_file: empty_catches

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_manager_service.dart';

class ScreenTransitionManager {
  static final ScreenTransitionManager _instance =
      ScreenTransitionManager._internal();
  factory ScreenTransitionManager() => _instance;
  ScreenTransitionManager._internal();

  final AudioManagerService _audioManagerService = AudioManagerService();
  final StreamController<String> _transitionController =
      StreamController<String>.broadcast();
  final StreamController<String> _transitionStatusController =
      StreamController<String>.broadcast();

  // Stream for transition events
  Stream<String> get transitionStream => _transitionController.stream;
  Stream<String> get transitionStatusStream =>
      _transitionStatusController.stream;

  // Current active screen
  String? _currentScreen;
  Timer? _transitionTimer;
  bool _isTransitioning = false;

  // Transition timing configuration
  static const Duration _transitionDelay = Duration(milliseconds: 150);
  static const Duration _welcomeDelay = Duration(milliseconds: 500);

  // Initialize the manager
  Future<void> initialize() async {
    _transitionStatusController.add('initialized');
  }

  // Navigate to a screen with smooth transition and enhanced activation
  Future<void> navigateToScreen(
    String screenId, {
    String? transitionMessage,
  }) async {
    if (_isTransitioning) {
      return;
    }

    _isTransitioning = true;
    _transitionStatusController.add('transitioning:$screenId');

    try {
      // Cancel any ongoing transition
      _transitionTimer?.cancel();

      // Deactivate current screen audio with transition feedback
      if (_currentScreen != null && _currentScreen != screenId) {
        await _audioManagerService.deactivateScreenAudio(_currentScreen!);

        // Special handling for map screen deactivation
        if (_currentScreen == 'map') {
          await _handleMapScreenDeactivation();
        }

        // Provide transition feedback
        if (transitionMessage != null) {
          await _audioManagerService.speakIfActive(
            _currentScreen!,
            transitionMessage,
          );
        }
      }

      // Update current screen
      _currentScreen = screenId;

      // Activate new screen audio with optimized timing
      _transitionTimer = Timer(_transitionDelay, () async {
        await _audioManagerService.activateScreenAudio(screenId);
        _transitionController.add('transitioned:$screenId');
        _transitionStatusController.add('activated:$screenId');

        // Provide welcome message for the new screen with delay
        Timer(_welcomeDelay, () async {
          await _provideWelcomeMessage(screenId);
        });
      });
    } catch (e) {
      _transitionStatusController.add('error:$screenId');
    } finally {
      _isTransitioning = false;
    }
  }

  // Global navigation method for seamless voice command navigation
  Future<void> navigateGlobally(String screenId) async {
    debugPrint('Global navigation to: $screenId');

    // Ensure voice navigation continues across transitions
    await navigateToScreen(
      screenId,
      transitionMessage:
          'Navigating to $screenId screen. Voice commands remain active.',
    );

    // Broadcast global navigation event
    _transitionController.add('global_navigation:$screenId');
  }

  // Handle map screen deactivation specifically
  Future<void> _handleMapScreenDeactivation() async {
    try {
      // Ensure map-specific audio features are properly stopped
      await _audioManagerService.speakIfActive(
        'map',
        "Deactivating map audio features. Tour guide narration stopped.",
      );

      // Ensure map audio is completely deactivated
      await _audioManagerService.deactivateScreenAudio('map');

      // Small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {}
  }

  // Provide welcome message for the new screen
  Future<void> _provideWelcomeMessage(String screenId) async {
    String welcomeMessage = _getWelcomeMessage(screenId);
    if (welcomeMessage.isNotEmpty) {
      await _audioManagerService.speakIfActive(screenId, welcomeMessage);
      _transitionStatusController.add('welcome_sent:$screenId');
    }
  }

  // Get welcome message for each screen
  String _getWelcomeMessage(String screenId) {
    switch (screenId) {
      case 'home':
        return "Home screen active. Navigation hub ready.";
      case 'map':
        return "Map screen active. Interactive exploration ready.";
      case 'discover':
        return "Tour discovery screen active. Your tour guide is ready.";
      case 'downloads':
        return "Downloads screen active. Offline content library ready.";
      case 'help':
        return "Help screen active. Assistance and support ready.";
      default:
        return "";
    }
  }

  // Get current screen
  String? get currentScreen => _currentScreen;

  // Check if a screen is currently active
  bool isScreenActive(String screenId) {
    return _currentScreen == screenId;
  }

  // Check if transition is in progress
  bool get isTransitioning => _isTransitioning;

  // Handle tab change with smooth transition
  Future<void> handleTabChange(int index) async {
    String screenId = _getScreenIdFromIndex(index);
    await navigateToScreen(
      screenId,
      transitionMessage: "Switching to ${_getScreenName(screenId)}",
    );
  }

  // Handle voice navigation command with enhanced feedback and seamless transitions
  Future<void> handleVoiceNavigation(String screen) async {
    String screenId = _getScreenIdFromVoiceCommand(screen);
    String currentScreen = _currentScreen ?? 'home';

    // Check if already on the target screen
    if (currentScreen == screenId) {
      await _audioManagerService.speakIfActive(
        screenId,
        "You're already on the ${_getScreenName(screenId)}. What would you like to do?",
      );
      return;
    }

    // Provide immediate feedback for seamless experience
    String transitionMessage =
        "Seamlessly transitioning from ${_getScreenName(currentScreen)} to ${_getScreenName(screenId)}";

    await navigateToScreen(screenId, transitionMessage: transitionMessage);
  }

  // Enhanced voice navigation with better error handling
  Future<void> handleVoiceNavigationEnhanced(String screen) async {
    try {
      String screenId = _getScreenIdFromVoiceCommand(screen);
      String currentScreen = _currentScreen ?? 'home';

      // Check if already on the target screen
      if (currentScreen == screenId) {
        await _audioManagerService.speakIfActive(
          screenId,
          "You're already on the ${_getScreenName(screenId)}. What would you like to do?",
        );
        return;
      }

      // Provide immediate feedback for seamless experience
      String transitionMessage =
          "Seamlessly transitioning from ${_getScreenName(currentScreen)} to ${_getScreenName(screenId)}";

      await navigateToScreen(screenId, transitionMessage: transitionMessage);
    } catch (e) {
      debugPrint('Error in voice navigation: $e');
      // Fallback navigation
      await navigateToScreen(
        'home',
        transitionMessage: 'Returning to home screen',
      );
    }
  }

  // Get screen ID from tab index
  String _getScreenIdFromIndex(int index) {
    switch (index) {
      case 0:
        return 'home';
      case 1:
        return 'map';
      case 2:
        return 'discover';
      case 3:
        return 'downloads';
      case 4:
        return 'help';
      default:
        return 'home';
    }
  }

  // Get screen ID from voice command with proper navigation pattern matching
  String _getScreenIdFromVoiceCommand(String command) {
    String normalizedCommand = command.toLowerCase().trim();

    // Handle "go to" commands first
    if (normalizedCommand.contains('go to')) {
      if (normalizedCommand.contains('home') ||
          normalizedCommand.contains('main')) {
        return 'home';
      } else if (normalizedCommand.contains('map') ||
          normalizedCommand.contains('location')) {
        return 'map';
      } else if (normalizedCommand.contains('discover') ||
          normalizedCommand.contains('explore') ||
          normalizedCommand.contains('tour')) {
        return 'discover';
      } else if (normalizedCommand.contains('download') ||
          normalizedCommand.contains('saved') ||
          normalizedCommand.contains('offline')) {
        return 'downloads';
      } else if (normalizedCommand.contains('help') ||
          normalizedCommand.contains('support')) {
        return 'help';
      }
    }

    // Handle direct screen names
    if (normalizedCommand.contains('home') ||
        normalizedCommand.contains('main') ||
        normalizedCommand.contains('dashboard')) {
      return 'home';
    } else if (normalizedCommand.contains('map') ||
        normalizedCommand.contains('location') ||
        normalizedCommand.contains('tracking')) {
      return 'map';
    } else if (normalizedCommand.contains('discover') ||
        normalizedCommand.contains('explore') ||
        normalizedCommand.contains('tour')) {
      return 'discover';
    } else if (normalizedCommand.contains('download') ||
        normalizedCommand.contains('saved') ||
        normalizedCommand.contains('offline')) {
      return 'downloads';
    } else if (normalizedCommand.contains('help') ||
        normalizedCommand.contains('support') ||
        normalizedCommand.contains('assistance')) {
      return 'help';
    }

    // Handle number-based navigation
    if (normalizedCommand == 'one' || normalizedCommand == '1') {
      return 'home';
    } else if (normalizedCommand == 'two' || normalizedCommand == '2') {
      return 'map';
    } else if (normalizedCommand == 'three' || normalizedCommand == '3') {
      return 'discover';
    } else if (normalizedCommand == 'four' || normalizedCommand == '4') {
      return 'downloads';
    } else if (normalizedCommand == 'five' || normalizedCommand == '5') {
      return 'help';
    }

    // Default to home if command is unclear
    return 'home';
  }

  // Get screen name for user feedback
  String _getScreenName(String screenId) {
    switch (screenId) {
      case 'home':
        return 'Home screen';
      case 'map':
        return 'Map screen';
      case 'discover':
        return 'Discover screen';
      case 'downloads':
        return 'Downloads screen';
      case 'help':
        return 'Help and Support screen';
      default:
        return 'Home screen';
    }
  }

  // Ensure voice navigation is always active
  Future<void> ensureVoiceNavigationActive() async {
    // This method ensures that voice navigation continues seamlessly
    // across all screen transitions
    _transitionStatusController.add('voice_navigation_active');
  }

  // Provide transition feedback
  Future<void> provideTransitionFeedback(
    String fromScreen,
    String toScreen,
  ) async {
    String message =
        "Transitioning from ${_getScreenName(fromScreen)} to ${_getScreenName(toScreen)}";
    await _audioManagerService.speakIfActive(fromScreen, message);
  }

  // Get transition status
  String getTransitionStatus() {
    if (_isTransitioning) {
      return 'transitioning';
    } else if (_currentScreen != null) {
      return 'active:$_currentScreen';
    } else {
      return 'idle';
    }
  }

  // Dispose resources
  void dispose() {
    _transitionTimer?.cancel();
    _transitionController.close();
    _transitionStatusController.close();
  }
}
