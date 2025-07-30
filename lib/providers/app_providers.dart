import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/landmark.dart';
import 'dart:math' as math;

// Provider classes for state management
class VoiceNavigationProvider extends ChangeNotifier {
  String _currentScreen = 'home';
  bool _isVoiceEnabled = true;
  bool _isListening = false;
  bool _isProcessingCommand = false;

  String get currentScreen => _currentScreen;
  bool get isVoiceEnabled => _isVoiceEnabled;
  bool get isListening => _isListening;
  bool get isProcessingCommand => _isProcessingCommand;

  void updateCurrentScreen(String screen) {
    if (_currentScreen != screen) {
      _currentScreen = screen;
      // Add longer delay to prevent rapid notifications and reduce frame skipping
      Future.delayed(const Duration(milliseconds: 200), () {
        notifyListeners();
      });
    }
  }

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    notifyListeners();
  }

  void setListening(bool listening) {
    if (_isListening != listening) {
      _isListening = listening;
      notifyListeners();
    }
  }

  void setProcessingCommand(bool processing) {
    if (_isProcessingCommand != processing) {
      _isProcessingCommand = processing;
      notifyListeners();
    }
  }
}

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  List<Landmark> _nearbyLandmarks = [];
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  List<Landmark> get nearbyLandmarks => _nearbyLandmarks;
  bool get isTracking => _isTracking;

  void updatePosition(Position position) {
    // Only update if position actually changed significantly
    if (_currentPosition == null ||
        _currentPosition!.latitude != position.latitude ||
        _currentPosition!.longitude != position.longitude) {
      // Calculate distance to determine if change is significant
      if (_currentPosition != null) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Only update if moved more than 15 meters to reduce frame skipping
        if (distance < 15.0) {
          return;
        }
      }

      _currentPosition = position;
      // Add longer delay to prevent rapid notifications and reduce frame skipping
      Future.delayed(const Duration(milliseconds: 1000), () {
        notifyListeners();
      });
    }
  }

  // Calculate distance between two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        (math.sin(_degreesToRadians(lat1)) *
            math.sin(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));
    double c = 2 * math.atan(math.sqrt(a) / math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159 / 180);
  }

  void updateLandmarks(List<Landmark> landmarks) {
    // Only update if landmarks actually changed
    if (_nearbyLandmarks.length != landmarks.length ||
        !_areLandmarksEqual(_nearbyLandmarks, landmarks)) {
      _nearbyLandmarks = landmarks;
      // Add delay to prevent rapid notifications and reduce frame skipping
      Future.delayed(const Duration(milliseconds: 1000), () {
        notifyListeners();
      });
    }
  }

  void setTracking(bool tracking) {
    if (_isTracking != tracking) {
      _isTracking = tracking;
      notifyListeners();
    }
  }

  bool _areLandmarksEqual(List<Landmark> list1, List<Landmark> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
 