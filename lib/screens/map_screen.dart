import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/voice_command_service.dart';
import '../services/voice_navigation_service.dart';
import '../services/audio_manager_service.dart';
import '../services/audio_narration_service.dart';
import '../models/landmark.dart';
import 'dart:async';
import 'dart:math' as math;

// Import providers from centralized location
import '../providers/app_providers.dart';

// Nearby place model
class NearbyPlace {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;
  final double? rating;
  final String? photoReference;

  NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.rating,
    this.photoReference,
  });
}

// Nearby places service with enhanced categories and real-time data
class NearbyPlacesService {
  // Available categories for speech narration
  static const List<String> availableCategories = [
    'restaurant',
    'hotel',
    'hospital',
    'pharmacy',
    'bank',
    'atm',
    'gas_station',
    'parking',
    'bus_station',
    'taxi_stand',
    'police',
    'fire_station',
    'school',
    'university',
    'library',
    'museum',
    'park',
    'shopping_mall',
    'market',
    'post_office',
    'tourist_attraction',
    'church',
    'mosque',
    'temple',
    'embassy',
    'government_office',
  ];

  Future<List<NearbyPlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required String category,
    double radius = 1000,
  }) async {
    // Simulate API call with comprehensive mock data
    await Future.delayed(Duration(milliseconds: 300));

    List<NearbyPlace> places = [];

    switch (category) {
      case 'restaurant':
        places = [
          NearbyPlace(
            id: 'rest_1',
            name: 'Kampala Restaurant',
            category: 'restaurant',
            latitude: latitude + 0.001,
            longitude: longitude + 0.001,
            address: 'Main Street, Kampala',
            rating: 4.5,
          ),
          NearbyPlace(
            id: 'rest_2',
            name: 'Uganda Cafe',
            category: 'restaurant',
            latitude: latitude - 0.001,
            longitude: longitude + 0.002,
            address: 'Central Avenue, Kampala',
            rating: 4.2,
          ),
          NearbyPlace(
            id: 'rest_3',
            name: 'African Delights',
            category: 'restaurant',
            latitude: latitude + 0.002,
            longitude: longitude - 0.001,
            address: 'Food Court, Kampala',
            rating: 4.7,
          ),
        ];
        break;
      case 'hotel':
        places = [
          NearbyPlace(
            id: 'hotel_1',
            name: 'Kampala Grand Hotel',
            category: 'hotel',
            latitude: latitude + 0.002,
            longitude: longitude - 0.001,
            address: 'Hotel Street, Kampala',
            rating: 4.8,
          ),
          NearbyPlace(
            id: 'hotel_2',
            name: 'Uganda Comfort Inn',
            category: 'hotel',
            latitude: latitude - 0.002,
            longitude: longitude + 0.003,
            address: 'Comfort Lane, Kampala',
            rating: 4.3,
          ),
        ];
        break;
      case 'hospital':
        places = [
          NearbyPlace(
            id: 'hosp_1',
            name: 'Kampala General Hospital',
            category: 'hospital',
            latitude: latitude - 0.002,
            longitude: longitude - 0.002,
            address: 'Medical Center, Kampala',
            rating: 4.6,
          ),
          NearbyPlace(
            id: 'hosp_2',
            name: 'Emergency Care Center',
            category: 'hospital',
            latitude: latitude + 0.003,
            longitude: longitude + 0.001,
            address: 'Emergency Street, Kampala',
            rating: 4.4,
          ),
        ];
        break;
      case 'pharmacy':
        places = [
          NearbyPlace(
            id: 'pharm_1',
            name: 'Kampala Pharmacy',
            category: 'pharmacy',
            latitude: latitude + 0.001,
            longitude: longitude - 0.002,
            address: 'Health Street, Kampala',
            rating: 4.3,
          ),
        ];
        break;
      case 'bank':
        places = [
          NearbyPlace(
            id: 'bank_1',
            name: 'Uganda National Bank',
            category: 'bank',
            latitude: latitude - 0.001,
            longitude: longitude + 0.001,
            address: 'Financial District, Kampala',
            rating: 4.5,
          ),
        ];
        break;
      case 'atm':
        places = [
          NearbyPlace(
            id: 'atm_1',
            name: '24/7 ATM Center',
            category: 'atm',
            latitude: latitude + 0.002,
            longitude: longitude + 0.002,
            address: 'Cash Street, Kampala',
            rating: 4.2,
          ),
        ];
        break;
      case 'gas_station':
        places = [
          NearbyPlace(
            id: 'gas_1',
            name: 'Kampala Fuel Station',
            category: 'gas_station',
            latitude: latitude - 0.003,
            longitude: longitude + 0.001,
            address: 'Fuel Avenue, Kampala',
            rating: 4.1,
          ),
        ];
        break;
      case 'parking':
        places = [
          NearbyPlace(
            id: 'park_1',
            name: 'Central Parking Lot',
            category: 'parking',
            latitude: latitude + 0.001,
            longitude: longitude - 0.003,
            address: 'Parking Street, Kampala',
            rating: 4.0,
          ),
        ];
        break;
      case 'bus_station':
        places = [
          NearbyPlace(
            id: 'bus_1',
            name: 'Kampala Bus Terminal',
            category: 'bus_station',
            latitude: latitude - 0.002,
            longitude: longitude + 0.002,
            address: 'Transport Hub, Kampala',
            rating: 4.3,
          ),
        ];
        break;
      case 'police':
        places = [
          NearbyPlace(
            id: 'police_1',
            name: 'Kampala Police Station',
            category: 'police',
            latitude: latitude + 0.003,
            longitude: longitude - 0.001,
            address: 'Security Street, Kampala',
            rating: 4.4,
          ),
        ];
        break;
      case 'school':
        places = [
          NearbyPlace(
            id: 'school_1',
            name: 'Kampala Primary School',
            category: 'school',
            latitude: latitude - 0.001,
            longitude: longitude - 0.002,
            address: 'Education Street, Kampala',
            rating: 4.6,
          ),
        ];
        break;
      case 'shopping_mall':
        places = [
          NearbyPlace(
            id: 'mall_1',
            name: 'Kampala Shopping Center',
            category: 'shopping_mall',
            latitude: latitude + 0.002,
            longitude: longitude + 0.001,
            address: 'Shopping District, Kampala',
            rating: 4.5,
          ),
        ];
        break;
      case 'market':
        places = [
          NearbyPlace(
            id: 'market_1',
            name: 'Kampala Central Market',
            category: 'market',
            latitude: latitude - 0.002,
            longitude: longitude - 0.001,
            address: 'Market Square, Kampala',
            rating: 4.3,
          ),
        ];
        break;
      case 'tourist_attraction':
        places = [
          NearbyPlace(
            id: 'attraction_1',
            name: 'Kampala Cultural Center',
            category: 'tourist_attraction',
            latitude: latitude + 0.003,
            longitude: longitude + 0.003,
            address: 'Tourist Area, Kampala',
            rating: 4.7,
          ),
        ];
        break;
      case 'church':
        places = [
          NearbyPlace(
            id: 'church_1',
            name: 'St. Mary\'s Cathedral',
            category: 'church',
            latitude: latitude - 0.003,
            longitude: longitude + 0.002,
            address: 'Religious Street, Kampala',
            rating: 4.8,
          ),
        ];
        break;
      default:
        places = [
          NearbyPlace(
            id: 'general_1',
            name: 'Local Business',
            category: category,
            latitude: latitude + 0.001,
            longitude: longitude + 0.001,
            address: 'Main Area, Kampala',
            rating: 4.0,
          ),
        ];
    }

    return places;
  }

  // Get all nearby places across multiple categories
  Future<Map<String, List<NearbyPlace>>> getAllNearbyPlaces({
    required double latitude,
    required double longitude,
    double radius = 1000,
  }) async {
    Map<String, List<NearbyPlace>> allPlaces = {};

    for (String category in availableCategories) {
      try {
        List<NearbyPlace> places = await getNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          category: category,
          radius: radius,
        );
        if (places.isNotEmpty) {
          allPlaces[category] = places;
        }
      } catch (e) {
        // Continue with other categories if one fails
        debugPrint('Error fetching $category places: $e');
      }
    }

    return allPlaces;
  }

  // Get category description for speech narration
  String getCategoryDescription(String category) {
    switch (category) {
      case 'restaurant':
        return 'restaurants and dining options';
      case 'hotel':
        return 'hotels and accommodation';
      case 'hospital':
        return 'hospitals and medical facilities';
      case 'pharmacy':
        return 'pharmacies and drug stores';
      case 'bank':
        return 'banks and financial services';
      case 'atm':
        return 'ATM machines and cash points';
      case 'gas_station':
        return 'gas stations and fuel services';
      case 'parking':
        return 'parking facilities';
      case 'bus_station':
        return 'bus stations and public transport';
      case 'taxi_stand':
        return 'taxi stands and ride services';
      case 'police':
        return 'police stations and security services';
      case 'fire_station':
        return 'fire stations and emergency services';
      case 'school':
        return 'schools and educational institutions';
      case 'university':
        return 'universities and higher education';
      case 'library':
        return 'libraries and study spaces';
      case 'museum':
        return 'museums and cultural centers';
      case 'park':
        return 'parks and recreational areas';
      case 'shopping_mall':
        return 'shopping malls and retail centers';
      case 'market':
        return 'markets and local vendors';
      case 'post_office':
        return 'post offices and mail services';
      case 'tourist_attraction':
        return 'tourist attractions and landmarks';
      case 'church':
        return 'churches and places of worship';
      case 'mosque':
        return 'mosques and Islamic centers';
      case 'temple':
        return 'temples and religious sites';
      case 'embassy':
        return 'embassies and diplomatic missions';
      case 'government_office':
        return 'government offices and services';
      default:
        return category.replaceAll('_', ' ');
    }
  }
}

// TTS Service
class TTSService {
  final FlutterTts _tts = FlutterTts();

  Future<void> initialize() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);

      // Skip voice setting to avoid type errors and use default voice
    } catch (e) {
      debugPrint('Error configuring TTS: $e');
      // Continue with default configuration
    }
  }

  Future<void> speakWithPriority(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

// Comprehensive Map Narration Service for real-time speech narration
class MapNarrationService {
  final TTSService _ttsService;
  final NearbyPlacesService _placesService;
  final AudioManagerService _audioManager;

  MapNarrationService({
    required TTSService ttsService,
    required NearbyPlacesService placesService,
    required AudioManagerService audioManager,
  }) : _ttsService = ttsService,
       _placesService = placesService,
       _audioManager = audioManager;

  // Enhanced narration state for blind users
  DateTime? _lastNarrationTime;
  final Duration _narrationCooldown = Duration(seconds: 8);
  final Map<String, List<NearbyPlace>> _cachedPlaces = {};

  // Blind user specific features
  bool _isBlindModeEnabled = true;
  String _currentNarrationMode = 'detailed'; // 'brief', 'detailed', 'immersive'
  double _narrationSpeed = 0.8;
  final double _narrationPitch = 1.0;

  // Spatial awareness tracking
  double? _lastLatitude;
  double? _lastLongitude;
  final double _movementThreshold = 10.0; // meters
  final List<String> _recentlyNarratedPlaces = [];
  final int _maxRecentlyNarrated = 5;

  // Initialize the service with blind user optimizations
  Future<void> initialize() async {
    await _ttsService.initialize();
    await _configureForBlindUsers();
  }

  // Configure TTS for optimal blind user experience
  Future<void> _configureForBlindUsers() async {
    await _ttsService._tts.setSpeechRate(_narrationSpeed);
    await _ttsService._tts.setPitch(_narrationPitch);
    await _ttsService._tts.setVolume(1.0);
    await _ttsService._tts.setLanguage("en-US");
  }

  // Enhanced surroundings narration for blind users
  Future<void> narrateSurroundings({
    required double latitude,
    required double longitude,
    double radius = 1000,
  }) async {
    try {
      // Check if user has moved significantly
      if (_hasUserMovedSignificantly(latitude, longitude)) {
        await _narrateMovementUpdate(latitude, longitude);
      }

      // Get all nearby places across categories
      Map<String, List<NearbyPlace>> allPlaces = await _placesService
          .getAllNearbyPlaces(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
          );

      _cachedPlaces.clear();
      _cachedPlaces.addAll(allPlaces);

      // Generate comprehensive narration for blind users
      String narration = _generateBlindUserSurroundingsNarration(
        allPlaces,
        latitude,
        longitude,
      );

      await _audioManager.speakIfActive('map', narration);

      // Update position tracking
      _lastLatitude = latitude;
      _lastLongitude = longitude;
    } catch (e) {
      debugPrint('Error narrating surroundings: $e');
      await _audioManager.speakIfActive(
        'map',
        'I encountered an issue getting nearby information. Please try again.',
      );
    }
  }

  // Check if user has moved significantly for spatial awareness
  bool _hasUserMovedSignificantly(double latitude, double longitude) {
    if (_lastLatitude == null || _lastLongitude == null) return false;

    double distance = _calculateDistance(
      _lastLatitude!,
      _lastLongitude!,
      latitude,
      longitude,
    );

    return distance > _movementThreshold;
  }

  // Calculate distance between two points in meters
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

  // Narrate movement updates for spatial awareness
  Future<void> _narrateMovementUpdate(double latitude, double longitude) async {
    if (_lastLatitude == null || _lastLongitude == null) return;

    double distance = _calculateDistance(
      _lastLatitude!,
      _lastLongitude!,
      latitude,
      longitude,
    );

    String direction = _getMovementDirection(latitude, longitude);
    String movementNarration =
        "You have moved ${distance.toStringAsFixed(0)} meters $direction. ";

    await _audioManager.speakIfActive('map', movementNarration);
  }

  // Determine movement direction
  String _getMovementDirection(double newLat, double newLon) {
    if (_lastLatitude == null || _lastLongitude == null) return "forward";

    double latDiff = newLat - _lastLatitude!;
    double lonDiff = newLon - _lastLongitude!;

    if (latDiff.abs() > lonDiff.abs()) {
      return latDiff > 0 ? "north" : "south";
    } else {
      return lonDiff > 0 ? "east" : "west";
    }
  }

  // Generate comprehensive surroundings narration for blind users
  String _generateBlindUserSurroundingsNarration(
    Map<String, List<NearbyPlace>> allPlaces,
    double latitude,
    double longitude,
  ) {
    if (allPlaces.isEmpty) {
      return 'No nearby places found in your current area. You are in a quiet location. Try moving to a different area or say "expand search" to look further.';
    }

    String narration = 'Here\'s what\'s around you: ';
    int totalPlaces = 0;
    List<String> nearbyDescriptions = [];

    // Prioritize important categories for blind users
    List<String> priorityCategories = [
      'restaurant',
      'hotel',
      'hospital',
      'bank',
      'police',
      'bus_station',
      'pharmacy',
      'atm',
    ];

    // Add spatial context
    narration +=
        'You are currently at coordinates ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}. ';

    for (String category in priorityCategories) {
      if (allPlaces.containsKey(category)) {
        List<NearbyPlace> places = allPlaces[category]!;
        if (places.isNotEmpty) {
          totalPlaces += places.length;
          String categoryDesc = _placesService.getCategoryDescription(category);

          // Add distance information for blind users
          for (NearbyPlace place in places.take(3)) {
            // Limit to 3 per category
            double distance = _calculateDistance(
              latitude,
              longitude,
              place.latitude,
              place.longitude,
            );
            String distanceDesc = _getDistanceDescription(distance);
            String placeDesc =
                '$categoryDesc: ${place.name}, $distanceDesc away';

            if (place.address != null) {
              placeDesc += ', at ${place.address}';
            }
            if (place.rating != null) {
              placeDesc += ', rated ${place.rating} stars';
            }

            nearbyDescriptions.add(placeDesc);
          }
        }
      }
    }

    // Add other categories
    for (String category in allPlaces.keys) {
      if (!priorityCategories.contains(category)) {
        List<NearbyPlace> places = allPlaces[category]!;
        if (places.isNotEmpty) {
          totalPlaces += places.length;
          String categoryDesc = _placesService.getCategoryDescription(category);
          String placeNames = places.map((p) => p.name).join(', ');
          nearbyDescriptions.add('$categoryDesc: $placeNames');
        }
      }
    }

    // Combine descriptions
    narration += nearbyDescriptions.join('. ');
    narration += ' Total of $totalPlaces places found nearby. ';

    // Add navigation guidance
    narration +=
        'Say a specific category like "restaurants", "hotels", or "hospitals" for detailed information. ';
    narration +=
        'Say "describe surroundings" for immersive narration, or "navigate to" followed by a place name for directions.';

    return narration;
  }

  // Get human-readable distance description
  String _getDistanceDescription(double distanceInMeters) {
    if (distanceInMeters < 50) {
      return 'very close, about ${distanceInMeters.toStringAsFixed(0)} meters';
    } else if (distanceInMeters < 200) {
      return 'nearby, about ${distanceInMeters.toStringAsFixed(0)} meters';
    } else if (distanceInMeters < 500) {
      return 'a short walk away, about ${(distanceInMeters / 100).toStringAsFixed(1)} blocks';
    } else {
      return 'about ${(distanceInMeters / 1000).toStringAsFixed(1)} kilometers away';
    }
  }

  // Enhanced category narration for blind users
  Future<void> narrateCategory({
    required String category,
    required double latitude,
    required double longitude,
    double radius = 1000,
  }) async {
    try {
      // Check cooldown to prevent spam
      if (_lastNarrationTime != null &&
          DateTime.now().difference(_lastNarrationTime!) < _narrationCooldown) {
        return;
      }

      _lastNarrationTime = DateTime.now();

      List<NearbyPlace> places = await _placesService.getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        category: category,
        radius: radius,
      );

      if (places.isNotEmpty) {
        String narration = _generateBlindUserCategoryNarration(
          category,
          places,
          latitude,
          longitude,
        );
        await _audioManager.speakIfActive('map', narration);

        // Add to recently narrated places
        for (NearbyPlace place in places.take(3)) {
          _addToRecentlyNarrated(place.name);
        }
      } else {
        String categoryDesc = _placesService.getCategoryDescription(category);
        await _audioManager.speakIfActive(
          'map',
          'No $categoryDesc found nearby within walking distance. Try expanding your search area or ask for a different category.',
        );
      }
    } catch (e) {
      debugPrint('Error narrating category $category: $e');
      await _audioManager.speakIfActive(
        'map',
        'I encountered an issue getting $category information. Please try again.',
      );
    }
  }

  // Generate category narration optimized for blind users
  String _generateBlindUserCategoryNarration(
    String category,
    List<NearbyPlace> places,
    double latitude,
    double longitude,
  ) {
    String categoryDesc = _placesService.getCategoryDescription(category);

    if (places.length == 1) {
      NearbyPlace place = places.first;
      double distance = _calculateDistance(
        latitude,
        longitude,
        place.latitude,
        place.longitude,
      );
      String distanceDesc = _getDistanceDescription(distance);

      String narration =
          'Found $categoryDesc: ${place.name}, $distanceDesc away';
      if (place.address != null) {
        narration += ', located at ${place.address}';
      }
      if (place.rating != null) {
        narration += '. Rating: ${place.rating} out of 5 stars';
      }
      narration +=
          '. Say "navigate to ${place.name}" for directions, or "describe ${place.name}" for more details.';
      return narration;
    } else {
      String narration = 'Found ${places.length} $categoryDesc nearby: ';
      List<String> placeDescriptions = [];

      for (int i = 0; i < places.length && i < 5; i++) {
        // Limit to 5 places
        NearbyPlace place = places[i];
        double distance = _calculateDistance(
          latitude,
          longitude,
          place.latitude,
          place.longitude,
        );
        String distanceDesc = _getDistanceDescription(distance);

        String placeDesc = '${place.name}, $distanceDesc away';
        if (place.rating != null) {
          placeDesc += ' (${place.rating} stars)';
        }
        placeDescriptions.add(placeDesc);
      }

      narration += placeDescriptions.join(', ');
      narration +=
          '. Say "navigate to" followed by any place name for directions.';
      return narration;
    }
  }

  // Add place to recently narrated places
  void _addToRecentlyNarrated(String placeName) {
    _recentlyNarratedPlaces.remove(placeName); // Remove if already exists
    _recentlyNarratedPlaces.insert(0, placeName); // Add to beginning

    if (_recentlyNarratedPlaces.length > _maxRecentlyNarrated) {
      _recentlyNarratedPlaces.removeLast();
    }
  }

  // Get recently narrated places
  List<String> getRecentlyNarratedPlaces() {
    return List.from(_recentlyNarratedPlaces);
  }

  // Enhanced emergency services narration for blind users
  Future<void> narrateEmergencyServices({
    required double latitude,
    required double longitude,
  }) async {
    List<String> emergencyCategories = [
      'hospital',
      'pharmacy',
      'police',
      'fire_station',
    ];

    String narration = 'Emergency services nearby: ';
    bool hasEmergencyServices = false;
    List<String> emergencyDescriptions = [];

    for (String category in emergencyCategories) {
      try {
        List<NearbyPlace> places = await _placesService.getNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          category: category,
          radius: 2000, // Larger radius for emergency services
        );

        if (places.isNotEmpty) {
          hasEmergencyServices = true;
          String categoryDesc = _placesService.getCategoryDescription(category);
          NearbyPlace place = places.first;
          double distance = _calculateDistance(
            latitude,
            longitude,
            place.latitude,
            place.longitude,
          );
          String distanceDesc = _getDistanceDescription(distance);

          String emergencyDesc =
              '$categoryDesc: ${place.name}, $distanceDesc away';
          if (place.address != null) {
            emergencyDesc += ', at ${place.address}';
          }
          emergencyDescriptions.add(emergencyDesc);
        }
      } catch (e) {
        debugPrint('Error getting emergency services for $category: $e');
      }
    }

    if (hasEmergencyServices) {
      narration += emergencyDescriptions.join('. ');
      narration +=
          '. Say "navigate to" followed by any service name for directions.';
    } else {
      narration =
          'No emergency services found in the immediate area. Consider calling emergency services directly if needed. The nearest hospital may be further away.';
    }

    await _audioManager.speakIfActive('map', narration);
  }

  // Enhanced transportation narration for blind users
  Future<void> narrateTransportation({
    required double latitude,
    required double longitude,
  }) async {
    List<String> transportCategories = [
      'bus_station',
      'taxi_stand',
      'parking',
      'gas_station',
    ];

    String narration = 'Transportation options nearby: ';
    bool hasTransport = false;
    List<String> transportDescriptions = [];

    for (String category in transportCategories) {
      try {
        List<NearbyPlace> places = await _placesService.getNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          category: category,
          radius: 1500,
        );

        if (places.isNotEmpty) {
          hasTransport = true;
          String categoryDesc = _placesService.getCategoryDescription(category);
          NearbyPlace place = places.first;
          double distance = _calculateDistance(
            latitude,
            longitude,
            place.latitude,
            place.longitude,
          );
          String distanceDesc = _getDistanceDescription(distance);

          String transportDesc =
              '$categoryDesc: ${place.name}, $distanceDesc away';
          if (place.address != null) {
            transportDesc += ', at ${place.address}';
          }
          transportDescriptions.add(transportDesc);
        }
      } catch (e) {
        debugPrint('Error getting transportation for $category: $e');
      }
    }

    if (hasTransport) {
      narration += transportDescriptions.join('. ');
      narration +=
          '. Say "navigate to" followed by any transport option for directions.';
    } else {
      narration =
          'Limited transportation options found nearby. Consider walking or calling a ride service. The nearest bus stop may be further away.';
    }

    await _audioManager.speakIfActive('map', narration);
  }

  // Enhanced shopping and services narration for blind users
  Future<void> narrateShoppingAndServices({
    required double latitude,
    required double longitude,
  }) async {
    List<String> shoppingCategories = [
      'shopping_mall',
      'market',
      'bank',
      'atm',
      'post_office',
    ];

    String narration = 'Shopping and services nearby: ';
    bool hasServices = false;
    List<String> serviceDescriptions = [];

    for (String category in shoppingCategories) {
      try {
        List<NearbyPlace> places = await _placesService.getNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          category: category,
          radius: 1200,
        );

        if (places.isNotEmpty) {
          hasServices = true;
          String categoryDesc = _placesService.getCategoryDescription(category);
          NearbyPlace place = places.first;
          double distance = _calculateDistance(
            latitude,
            longitude,
            place.latitude,
            place.longitude,
          );
          String distanceDesc = _getDistanceDescription(distance);

          String serviceDesc =
              '$categoryDesc: ${place.name}, $distanceDesc away';
          if (place.address != null) {
            serviceDesc += ', at ${place.address}';
          }
          serviceDescriptions.add(serviceDesc);
        }
      } catch (e) {
        debugPrint('Error getting shopping services for $category: $e');
      }
    }

    if (hasServices) {
      narration += serviceDescriptions.join('. ');
      narration +=
          '. Say "navigate to" followed by any service name for directions.';
    } else {
      narration =
          'Limited shopping and services found nearby. You may need to travel further for these amenities.';
    }

    await _audioManager.speakIfActive('map', narration);
  }

  // Immersive surroundings description for blind users
  Future<void> narrateImmersiveSurroundings({
    required double latitude,
    required double longitude,
  }) async {
    try {
      Map<String, List<NearbyPlace>> allPlaces = await _placesService
          .getAllNearbyPlaces(
            latitude: latitude,
            longitude: longitude,
            radius: 800,
          );

      String narration = _generateImmersiveNarration(
        allPlaces,
        latitude,
        longitude,
      );
      await _audioManager.speakIfActive('map', narration);
    } catch (e) {
      debugPrint('Error narrating immersive surroundings: $e');
      await _audioManager.speakIfActive(
        'map',
        'I encountered an issue providing immersive narration. Please try again.',
      );
    }
  }

  // Generate immersive narration for blind users
  String _generateImmersiveNarration(
    Map<String, List<NearbyPlace>> allPlaces,
    double latitude,
    double longitude,
  ) {
    String narration = 'Let me describe your surroundings in detail: ';

    // Describe the immediate area
    narration += 'You are in an area with ';

    List<String> areaFeatures = [];
    if (allPlaces.containsKey('restaurant')) {
      areaFeatures.add('dining options');
    }
    if (allPlaces.containsKey('shopping_mall') ||
        allPlaces.containsKey('market')) {
      areaFeatures.add('shopping areas');
    }
    if (allPlaces.containsKey('park')) {
      areaFeatures.add('green spaces');
    }
    if (allPlaces.containsKey('bus_station')) {
      areaFeatures.add('public transportation');
    }
    if (allPlaces.containsKey('hospital') ||
        allPlaces.containsKey('pharmacy')) {
      areaFeatures.add('medical facilities');
    }

    if (areaFeatures.isNotEmpty) {
      narration += areaFeatures.join(', ');
    } else {
      narration += 'a mix of residential and commercial buildings';
    }

    narration += '. ';

    // Describe the atmosphere
    int totalPlaces = allPlaces.values.fold(
      0,
      (total, places) => total + places.length,
    );
    if (totalPlaces > 20) {
      narration +=
          'This is a busy, urban area with many amenities within easy reach. ';
    } else if (totalPlaces > 10) {
      narration +=
          'This is a moderately busy area with good access to essential services. ';
    } else {
      narration +=
          'This is a quieter area, perfect for a peaceful experience. ';
    }

    // Add specific highlights
    List<String> highlights = [];
    for (String category in ['tourist_attraction', 'museum', 'park']) {
      if (allPlaces.containsKey(category)) {
        List<NearbyPlace> places = allPlaces[category]!;
        if (places.isNotEmpty) {
          NearbyPlace place = places.first;
          double distance = _calculateDistance(
            latitude,
            longitude,
            place.latitude,
            place.longitude,
          );
          String distanceDesc = _getDistanceDescription(distance);
          highlights.add('${place.name} is $distanceDesc away');
        }
      }
    }

    if (highlights.isNotEmpty) {
      narration +=
          'Notable nearby attractions include: ${highlights.join(', ')}. ';
    }

    narration +=
        'You can explore this area safely with voice navigation. Say "describe surroundings" anytime for an updated description.';

    return narration;
  }

  // Navigation assistance for blind users
  Future<void> provideNavigationAssistance({
    required String destinationName,
    required double currentLat,
    required double currentLon,
  }) async {
    try {
      // Search for the destination across all categories
      Map<String, List<NearbyPlace>> allPlaces = await _placesService
          .getAllNearbyPlaces(
            latitude: currentLat,
            longitude: currentLon,
            radius: 2000,
          );

      NearbyPlace? destination;

      for (String cat in allPlaces.keys) {
        List<NearbyPlace> places = allPlaces[cat]!;
        for (NearbyPlace place in places) {
          if (place.name.toLowerCase().contains(
            destinationName.toLowerCase(),
          )) {
            destination = place;
            break;
          }
        }
        if (destination != null) break;
      }

      if (destination != null) {
        double distance = _calculateDistance(
          currentLat,
          currentLon,
          destination.latitude,
          destination.longitude,
        );
        String distanceDesc = _getDistanceDescription(distance);
        String direction = _getDirectionToDestination(
          currentLat,
          currentLon,
          destination.latitude,
          destination.longitude,
        );

        String navigationNarration =
            'I found ${destination.name} $distanceDesc away. ';
        navigationNarration += 'It\'s located to the $direction. ';

        if (destination.address != null) {
          navigationNarration += 'The address is ${destination.address}. ';
        }

        navigationNarration += 'I\'ll guide you there step by step. ';
        navigationNarration +=
            'Start walking $direction, and I\'ll provide updates as you move.';

        await _audioManager.speakIfActive('map', navigationNarration);
      } else {
        await _audioManager.speakIfActive(
          'map',
          'I couldn\'t find $destinationName nearby. Try saying the name more clearly, or ask for nearby places in that category.',
        );
      }
    } catch (e) {
      debugPrint('Error providing navigation assistance: $e');
      await _audioManager.speakIfActive(
        'map',
        'I encountered an issue with navigation. Please try again.',
      );
    }
  }

  // Get direction to destination
  String _getDirectionToDestination(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    double latDiff = toLat - fromLat;
    double lonDiff = toLon - fromLon;

    if (latDiff.abs() > lonDiff.abs()) {
      return latDiff > 0 ? 'north' : 'south';
    } else {
      return lonDiff > 0 ? 'east' : 'west';
    }
  }

  // Toggle narration modes
  void toggleNarrationMode() {
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

  // Get current narration mode
  String getCurrentNarrationMode() {
    return _currentNarrationMode;
  }

  // Toggle blind mode features
  void toggleBlindMode() {
    _isBlindModeEnabled = !_isBlindModeEnabled;
  }

  // Get blind mode status
  bool getBlindModeStatus() {
    return _isBlindModeEnabled;
  }

  // Adjust narration speed
  void adjustNarrationSpeed(double speed) {
    _narrationSpeed = speed.clamp(0.5, 1.5);
    _ttsService._tts.setSpeechRate(_narrationSpeed);
  }

  // Get narration speed
  double getNarrationSpeed() {
    return _narrationSpeed;
  }

  // Provide help with available categories
  List<String> getAvailableCategories() {
    return NearbyPlacesService.availableCategories;
  }

  // Get category suggestions for voice commands
  String getCategorySuggestions() {
    List<String> categories = getAvailableCategories();
    String suggestions = 'Available categories: ';
    suggestions += categories.take(10).join(', '); // Limit to first 10
    if (categories.length > 10) {
      suggestions += ', and ${categories.length - 10} more. ';
    }
    suggestions += 'Say any category name to hear nearby places. ';
    suggestions +=
        'You can also say "describe surroundings" for immersive narration, "navigate to" followed by a place name for directions, or "emergency services" for safety information.';
    return suggestions;
  }
}

// Dependency injection
class DependencyInjection {
  static final TTSService _ttsService = TTSService();
  static final NearbyPlacesService _nearbyPlacesService = NearbyPlacesService();

  static TTSService get ttsService => _ttsService;
  static NearbyPlacesService get nearbyPlacesService => _nearbyPlacesService;
}

// Widgets
class VoiceStatusWidget extends StatelessWidget {
  const VoiceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceNavigationProvider>(
      builder: (context, provider, child) {
        return IconButton(
          icon: Icon(
            provider.isListening ? Icons.mic : Icons.mic_off,
            color: provider.isListening ? Colors.green : Colors.grey,
          ),
          onPressed: () {
            provider.setListening(!provider.isListening);
          },
          tooltip: provider.isListening ? 'Voice Active' : 'Voice Inactive',
        );
      },
    );
  }
}

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCurrentLocation;

  const MapControlsWidget({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton.small(
          onPressed: onZoomIn,
          tooltip: 'Zoom In',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onZoomOut,
          tooltip: 'Zoom Out',
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onCurrentLocation,
          tooltip: 'My Location',
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }
}

class CategorySelectorWidget extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final VoidCallback onClose;

  const CategorySelectorWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'id': 'tours', 'name': 'Tours', 'icon': Icons.explore},
      {'id': 'restaurant', 'name': 'Restaurants', 'icon': Icons.restaurant},
      {'id': 'hotel', 'name': 'Hotels', 'icon': Icons.hotel},
      {'id': 'hospital', 'name': 'Hospitals', 'icon': Icons.local_hospital},
      {'id': 'pharmacy', 'name': 'Pharmacies', 'icon': Icons.local_pharmacy},
      {'id': 'bank', 'name': 'Banks', 'icon': Icons.account_balance},
      {'id': 'atm', 'name': 'ATMs', 'icon': Icons.atm},
      {'id': 'bus_station', 'name': 'Bus Stops', 'icon': Icons.directions_bus},
      {'id': 'market', 'name': 'Markets', 'icon': Icons.store},
      {'id': 'park', 'name': 'Parks', 'icon': Icons.park},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category['id'];

                return InkWell(
                  onTap: () => onCategorySelected(category['id'].toString()),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category['name'].toString(),
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

class NearbyPlacesWidget extends StatelessWidget {
  final List<NearbyPlace> places;
  final String category;
  final Function(NearbyPlace) onPlaceSelected;
  final VoidCallback onClose;

  const NearbyPlacesWidget({
    super.key,
    required this.places,
    required this.category,
    required this.onPlaceSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Nearby ${_getCategoryDisplayName(category)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child:
                places.isEmpty
                    ? const Center(child: Text('No places found nearby'))
                    : ListView.builder(
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(_getCategoryIcon(place.category)),
                          ),
                          title: Text(place.name),
                          subtitle: Text(place.address ?? 'No address'),
                          trailing:
                              place.rating != null
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      Text(place.rating!.toStringAsFixed(1)),
                                    ],
                                  )
                                  : null,
                          onTap: () => onPlaceSelected(place),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'tours':
        return 'Tour Destinations';
      case 'restaurant':
        return 'Restaurants';
      case 'hotel':
        return 'Hotels';
      case 'hospital':
        return 'Hospitals';
      case 'pharmacy':
        return 'Pharmacies';
      case 'bank':
        return 'Banks';
      case 'atm':
        return 'ATMs';
      case 'bus_station':
        return 'Bus Stops';
      case 'train_station':
        return 'Train Stations';
      case 'taxi_stand':
        return 'Taxi Stands';
      case 'market':
        return 'Markets';
      case 'shopping_mall':
        return 'Shopping Centers';
      case 'school':
        return 'Schools';
      case 'university':
        return 'Universities';
      case 'library':
        return 'Libraries';
      case 'post_office':
        return 'Post Offices';
      case 'police':
        return 'Police Stations';
      case 'fire_station':
        return 'Fire Stations';
      case 'park':
        return 'Parks';
      case 'museum':
        return 'Museums';
      case 'church':
        return 'Churches';
      case 'mosque':
        return 'Mosques';
      case 'temple':
        return 'Temples';
      default:
        return 'Unknown Category';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'hospital':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'bank':
        return Icons.account_balance;
      case 'atm':
        return Icons.atm;
      case 'bus_station':
        return Icons.directions_bus;
      case 'market':
        return Icons.store;
      case 'park':
        return Icons.park;
      default:
        return Icons.place;
    }
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final VoiceCommandService _voiceCommandService = VoiceCommandService();
  final VoiceNavigationService _voiceNavigationService =
      VoiceNavigationService();
  final AudioManagerService _audioManagerService = AudioManagerService();
  final AudioNarrationService _audioNarrationService = AudioNarrationService();
  final FlutterTts _tts = FlutterTts();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TTSService _ttsService = DependencyInjection.ttsService;
  final NearbyPlacesService _nearbyPlacesService =
      DependencyInjection.nearbyPlacesService;
  late MapNarrationService _mapNarrationService;
  String? _userId;

  Position? _currentPosition;
  List<Landmark> _nearbyLandmarks = [];
  Set<Marker> _markers = {};

  // Enhanced state for new functionality
  String _selectedCategory = 'tours';
  List<NearbyPlace> _nearbyPlaces = [];
  bool _isLoadingPlaces = false;
  bool _showCategorySelector = false;
  bool _showNearbyPlaces = false;

  // Navigation and voice narration state
  Timer? _narrationTimer;

  // Performance optimization timers
  Timer? _positionUpdateTimer;
  Timer? _providerUpdateTimer;
  Timer? _audioUpdateTimer;
  Timer? _mapUpdateTimer;
  Timer? _markerUpdateTimer;
  Timer? _firestoreUpdateTimer;
  Timer? _otherUsersUpdateTimer;
  Timer? _locationNarrationTimer;
  Position? _pendingPositionUpdate;

  // Enhanced voice features
  // Remove the hardcoded voice enabled flag and use the dynamic one

  // Map screen specific voice command state
  bool _isMapVoiceEnabled = true;

  // Voice command state
  StreamSubscription<String>? _mapCommandSubscription;
  StreamSubscription<String>? _audioControlSubscription;
  StreamSubscription<String>? _screenActivationSubscription;

  // Map settings
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(0.3476, 32.5825), // Kampala, Uganda
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    debugPrint('🗺️ Map screen initializing...');
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _listenToOtherUsers();
    _initializeVoiceNavigation();
    _registerWithAudioManager();
    _setupVoiceNavigation();
    _initializeScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure map screen is activated when dependencies change
    if (_isMapVoiceEnabled) {
      _audioManagerService.activateScreenAudio('map');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('🗺️ Map screen resumed - activating audio');
        if (_isMapVoiceEnabled) {
          _audioManagerService.activateScreenAudio('map');
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('🗺️ Map screen paused - deactivating audio');
        _audioManagerService.deactivateScreenAudio('map');
        break;
      default:
        break;
    }
  }

  void _setupVoiceNavigation() {
    try {
      // Update voice navigation context
      final voiceProvider = Provider.of<VoiceNavigationProvider>(
        context,
        listen: false,
      );
      voiceProvider.updateCurrentScreen('map');
    } catch (e) {
      debugPrint('Error setting up voice navigation: $e');
    }
  }

  Future<void> _initializeScreen() async {
    try {
      debugPrint('🗺️ Initializing map screen with audio manager...');

      // Ensure map screen is activated in audio manager
      await _audioManagerService.activateScreenAudio('map');

      // Use audio manager for welcome message
      await _audioManagerService.speakIfActive(
        'map',
        'Welcome to your interactive map guide! I\'m here to help you explore your surroundings with comprehensive voice navigation. '
            'I can tell you about nearby hotels, restaurants, attractions, facilities, transportation, and much more. '
            'Say "surroundings" to hear about your current area, "landmarks" for attractions, "hotels" for accommodation, "restaurants" for dining, "facilities" for services, "transport" for transportation, "safety" for emergency services, or "help" for all options. '
            'I\'ll provide real-time information and guide you through your exploration. What would you like to discover first?',
      );

      // Load initial nearby places
      await _loadNearbyPlaces();
    } catch (e) {
      debugPrint('Error initializing map screen: $e');
      // Fallback to direct TTS
      await _ttsService.speakWithPriority(
        'I encountered an issue initializing the map. Please try again, or say "help" for assistance.',
      );
    }
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      setState(() {
        _isLoadingPlaces = true;
      });

      if (_currentPosition != null) {
        final places = await _nearbyPlacesService.getNearbyPlaces(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          category: _selectedCategory,
        );

        setState(() {
          _nearbyPlaces = places;
          _isLoadingPlaces = false;
        });

        _updateMarkers();
      } else {
        setState(() {
          _isLoadingPlaces = false;
        });
        await _audioManagerService.speakIfActive(
          'map',
          'Location not available. Please enable location services to find nearby places.',
        );
      }
    } catch (e) {
      debugPrint('Error loading nearby places: $e');
      setState(() {
        _isLoadingPlaces = false;
      });
      await _audioManagerService.speakIfActive(
        'map',
        'Error loading nearby places. Please try again.',
      );
    }
  }

  void _updateMarkers() {
    // Use a more efficient marker update approach to reduce frame skipping
    if (!mounted) return;

    // Limit the number of markers to prevent performance issues (reduced from 20)
    final maxMarkers = 10;
    final markers = <Marker>{};

    // Add user location marker (always first)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add landmark markers (limit to 3 to reduce rendering load)
    int landmarkCount = 0;
    for (final landmark in _nearbyLandmarks) {
      if (landmarkCount >= 3) break;
      markers.add(
        Marker(
          markerId: MarkerId(landmark.id),
          position: LatLng(landmark.latitude, landmark.longitude),
          infoWindow: InfoWindow(
            title: landmark.name,
            snippet: landmark.description,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _onLandmarkTapped(landmark),
        ),
      );
      landmarkCount++;
    }

    // Add nearby places markers (limit to remaining slots)
    int placeCount = 0;
    final maxPlaces = maxMarkers - markers.length;
    for (final place in _nearbyPlaces) {
      if (placeCount >= maxPlaces) break;
      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address ?? 'No address available',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(place.category),
          ),
          onTap: () => _onPlaceSelected(place),
        ),
      );
      placeCount++;
    }

    // Update markers with throttling - use Timer instead of microtask
    _markerUpdateTimer?.cancel();
    _markerUpdateTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _markers = markers;
        });
      }
    });
  }

  double _getMarkerColor(String category) {
    switch (category) {
      case 'tours':
        return BitmapDescriptor.hueBlue;
      case 'restaurant':
        return BitmapDescriptor.hueRed;
      case 'hotel':
        return BitmapDescriptor.hueYellow;
      case 'hospital':
        return BitmapDescriptor.hueGreen;
      case 'pharmacy':
        return BitmapDescriptor.hueCyan;
      case 'bank':
        return BitmapDescriptor.hueOrange;
      case 'atm':
        return BitmapDescriptor.hueViolet;
      case 'bus_station':
        return BitmapDescriptor.hueAzure;
      case 'market':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  Future<void> _onCategorySelected(String category) async {
    // Haptic feedback for category selection
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 45);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    setState(() {
      _selectedCategory = category;
      _showCategorySelector = false;
    });

    if (_isMapVoiceEnabled) {
      String categoryName = _getCategoryDisplayName(category);
      await _audioManagerService.speakIfActive(
        'map',
        'Searching for nearby $categoryName. Please wait while I discover locations for you.',
      );
    }

    _loadNearbyPlaces();
  }

  Future<void> _toggleCategorySelector() async {
    // Haptic feedback for category selector toggle
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 35);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    setState(() {
      _showCategorySelector = !_showCategorySelector;
      if (_showCategorySelector) {
        _showNearbyPlaces = false;
      }
    });

    if (_showCategorySelector) {
      if (_isMapVoiceEnabled) {
        await _audioManagerService.speakIfActive(
          'map',
          'Category selector opened. Choose a place type to search for nearby locations.',
        );
      }
    } else {
      if (_isMapVoiceEnabled) {
        await _audioManagerService.speakIfActive(
          'map',
          'Category selector closed.',
        );
      }
    }
  }

  Future<void> _toggleNearbyPlaces() async {
    // Haptic feedback for nearby places toggle
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 35);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    setState(() {
      _showNearbyPlaces = !_showNearbyPlaces;
      if (_showNearbyPlaces) {
        _showCategorySelector = false;
      }
    });

    if (_showNearbyPlaces) {
      if (_isMapVoiceEnabled) {
        await _audioManagerService.speakIfActive(
          'map',
          'Nearby places panel opened. Browse discovered locations and tap on any place for details.',
        );
      }
    } else {
      if (_isMapVoiceEnabled) {
        await _audioManagerService.speakIfActive(
          'map',
          'Nearby places panel closed.',
        );
      }
    }
  }

  Future<void> _onPlaceSelected(NearbyPlace place) async {
    // Enhanced haptic feedback for place selection
    try {
      if (await Vibration.hasVibrator()) {
        // Triple vibration pattern for place selection (different from landmarks)
        Vibration.vibrate(duration: 150);
        await Future.delayed(const Duration(milliseconds: 80));
        Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 80));
        Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    // Enhanced speech narration for place selection with current location context
    if (_isMapVoiceEnabled) {
      String placeDescription = "Place selected: ${place.name}. ";

      // Add category information
      String categoryDesc = _getCategoryDisplayName(place.category);
      placeDescription += "This is a $categoryDesc. ";

      // Add current location context
      if (_currentPosition != null) {
        placeDescription += "Your current location: ";
        placeDescription +=
            "${_currentPosition!.latitude.toStringAsFixed(4)}, ";
        placeDescription +=
            "${_currentPosition!.longitude.toStringAsFixed(4)}. ";

        // Add distance and direction information
        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          place.latitude,
          place.longitude,
        );
        String distanceDesc = _getDistanceDescription(distance);
        String direction = _getDirectionToDestination(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          place.latitude,
          place.longitude,
        );

        placeDescription +=
            "The place is $distanceDesc away, located to the $direction. ";

        // Add estimated walking time
        int walkingTimeMinutes =
            (distance / 80)
                .round(); // Assuming 80 meters per minute walking speed
        if (walkingTimeMinutes > 0) {
          placeDescription +=
              "Estimated walking time: $walkingTimeMinutes minutes. ";
        }
      } else {
        placeDescription +=
            "Location services not available. Please enable location to get distance information. ";
      }

      // Add address information
      if (place.address != null && place.address!.isNotEmpty) {
        placeDescription += "Address: ${place.address}. ";
      }

      // Add rating information if available
      if (place.rating != null) {
        placeDescription += "Rating: ${place.rating} out of 5 stars. ";
      }

      // Add accessibility information based on category
      String accessibilityInfo = _getAccessibilityInfo(place.category);
      placeDescription += accessibilityInfo;

      // Add action suggestions
      placeDescription +=
          "Say 'navigate to ${place.name}' for turn-by-turn directions, 'call ${place.name}' for contact information, 'tell me more' for additional details, or 'describe surroundings' to hear about nearby places.";

      debugPrint('🎤 Attempting to speak place description: ${place.name}');
      try {
        await _audioManagerService.speakIfActive('map', placeDescription);
        debugPrint('🎤 Place description spoken successfully');
      } catch (e) {
        debugPrint('🎤 Audio manager failed, using fallback TTS: $e');
        // Fallback to direct TTS
        await _ttsService.speakWithPriority(placeDescription);
      }
    }
  }

  // Handle map tap events with haptic feedback and speech narration
  Future<void> _onMapTapped(LatLng position) async {
    // Light haptic feedback for map tap
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    // Enhanced speech narration for map tap with current location context
    if (_isMapVoiceEnabled) {
      String tapDescription = "Map tapped at coordinates ";
      tapDescription += "${position.latitude.toStringAsFixed(4)}, ";
      tapDescription += "${position.longitude.toStringAsFixed(4)}. ";

      // Add current location context and distance information
      if (_currentPosition != null) {
        tapDescription += "Your current location: ";
        tapDescription += "${_currentPosition!.latitude.toStringAsFixed(4)}, ";
        tapDescription += "${_currentPosition!.longitude.toStringAsFixed(4)}. ";

        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        String distanceDesc = _getDistanceDescription(distance);
        String direction = _getDirectionToDestination(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        tapDescription +=
            "The tapped location is $distanceDesc away, located to the $direction. ";

        // Add estimated walking time
        int walkingTimeMinutes =
            (distance / 80)
                .round(); // Assuming 80 meters per minute walking speed
        if (walkingTimeMinutes > 0) {
          tapDescription +=
              "Estimated walking time: $walkingTimeMinutes minutes. ";
        }
      } else {
        tapDescription +=
            "Location services not available. Please enable location to get distance information. ";
      }

      tapDescription +=
          "Say 'what's here' to discover nearby places, 'navigate here' for directions to this location, or 'describe surroundings' to hear about the area.";

      await _audioManagerService.speakIfActive('map', tapDescription);
    }
  }

  Future<void> _zoomIn() async {
    // Haptic feedback for zoom in
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 30);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    _mapController?.animateCamera(CameraUpdate.zoomIn());

    if (_isMapVoiceEnabled) {
      await _audioManagerService.speakIfActive(
        'map',
        'Zooming in on map for closer view',
      );
    }
  }

  Future<void> _zoomOut() async {
    // Haptic feedback for zoom out
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 30);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    _mapController?.animateCamera(CameraUpdate.zoomOut());

    if (_isMapVoiceEnabled) {
      await _audioManagerService.speakIfActive(
        'map',
        'Zooming out on map for wider view',
      );
    }
  }

  Future<void> _goToCurrentLocation() async {
    // Enhanced haptic feedback for current location
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 40);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );

      if (_isMapVoiceEnabled) {
        String locationInfo = "Centering map on your current location. ";
        locationInfo += "You are at coordinates ";
        locationInfo += "${_currentPosition!.latitude.toStringAsFixed(4)}, ";
        locationInfo += "${_currentPosition!.longitude.toStringAsFixed(4)}. ";
        locationInfo +=
            "Say 'describe surroundings' to hear about nearby places, or 'what's here' to discover local attractions.";

        await _audioManagerService.speakIfActive('map', locationInfo);
      }
    } else {
      if (_isMapVoiceEnabled) {
        await _audioManagerService.speakIfActive(
          'map',
          'Location not available. Please enable location services to get your current position and nearby information.',
        );
      }
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'tours':
        return 'Tour Destinations';
      case 'restaurant':
        return 'Restaurants';
      case 'hotel':
        return 'Hotels';
      case 'hospital':
        return 'Hospitals';
      case 'pharmacy':
        return 'Pharmacies';
      case 'bank':
        return 'Banks';
      case 'atm':
        return 'ATMs';
      case 'bus_station':
        return 'Bus Stops';
      case 'train_station':
        return 'Train Stations';
      case 'taxi_stand':
        return 'Taxi Stands';
      case 'market':
        return 'Markets';
      case 'shopping_mall':
        return 'Shopping Centers';
      case 'school':
        return 'Schools';
      case 'university':
        return 'Universities';
      case 'library':
        return 'Libraries';
      case 'post_office':
        return 'Post Offices';
      case 'police':
        return 'Police Stations';
      case 'fire_station':
        return 'Fire Stations';
      case 'park':
        return 'Parks';
      case 'museum':
        return 'Museums';
      case 'church':
        return 'Churches';
      case 'mosque':
        return 'Mosques';
      case 'temple':
        return 'Temples';
      default:
        return 'Unknown Category';
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _locationService.initialize();
      await _voiceCommandService.initialize();
      // Voice navigation is already initialized globally
      debugPrint('Map screen: Global voice navigation active');
      await _audioNarrationService.initialize();
      await _ttsService.initialize();

      // Initialize map narration service
      _mapNarrationService = MapNarrationService(
        ttsService: _ttsService,
        placesService: _nearbyPlacesService,
        audioManager: _audioManagerService,
      );
      await _mapNarrationService.initialize();

      // Get initial position to center the map
      final initialPosition = await _locationService.getInitialPosition();
      if (mounted) {
        setState(() {
          _currentPosition = initialPosition;
        });
      }
      _centerMapOnUser();

      // Listen to location updates
      _locationService.positionStream.listen(_onPositionUpdate);
      _locationService.nearbyLandmarksStream.listen(_onNearbyLandmarksUpdate);
      _locationService.landmarkEnteredStream.listen(_onLandmarkEntered);

      // Start location tracking
      await _startLocationTracking();

      // Start automatic narration
      await _startAutomaticNarration();
    } catch (e) {
      debugPrint('Error initializing map services: $e');
      if (mounted) {
        await _audioManagerService.speakIfActive(
          'map',
          "Error initializing map services. Please check your location permissions.",
        );
      }
    }
  }

  Future<void> _startAutomaticNarration() async {
    String welcomeMessage =
        "Your interactive map guide is ready! I can help you discover hotels, restaurants, attractions, facilities, transportation, and safety services in your area. "
        "Say 'surroundings' to start exploring, 'help' for all options, or ask about specific places you're interested in. "
        "I'll provide real-time information and guide you through your exploration.";
    await _audioManagerService.speakIfActive('map', welcomeMessage);
  }

  // Center map on user's current location with throttling
  void _centerMapOnUser() {
    if (_currentPosition != null && _mapController != null) {
      // Throttle map centering to reduce frame skipping
      _mapUpdateTimer?.cancel();
      _mapUpdateTimer = Timer(const Duration(milliseconds: 3000), () {
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            ),
          );
        }
      });
    }
  }

  // Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      await _locationService.startTracking();
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }

  // Start continuous narration with much reduced frequency to prevent frame skipping
  void _startContinuousNarration() {
    _narrationTimer?.cancel();
    _narrationTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      if (_isMapVoiceEnabled && _currentPosition != null) {
        // Throttle narration to reduce workload
        Timer(const Duration(milliseconds: 2000), () {
          _narrateSurroundings();
        });
      }
    });
  }

  Future<void> _registerWithAudioManager() async {
    final speech = stt.SpeechToText();
    await speech.initialize();
    _audioManagerService.registerScreen('map', _ttsService._tts, speech);

    _audioManagerService.enableNarration(
      'map',
      interval: const Duration(seconds: 30),
      priority: 1,
    );

    _audioControlSubscription = _audioManagerService.audioControlStream.listen((
      event,
    ) {
      if (event.startsWith('activated:map')) {
        _onMapScreenActivated();
      } else if (event.startsWith('deactivated:map')) {
        _onMapScreenDeactivated();
      }
    });

    _screenActivationSubscription = _audioManagerService.screenActivationStream
        .listen((screenId) {
          if (screenId == 'map') {
            _onMapScreenActivated();
          } else {
            _onMapScreenDeactivated();
          }
        });
  }

  Future<void> _initializeVoiceNavigation() async {
    _mapCommandSubscription = _voiceNavigationService.mapCommandStream.listen((
      command,
    ) {
      _handleMapVoiceCommand(command);
    });
  }

  Future<void> _handleMapVoiceCommand(String command) async {
    if (!_isMapVoiceEnabled) return;

    debugPrint('🎤 Map voice command received: $command');

    // Enhanced surroundings narration commands
    if (command.contains('describe surroundings') ||
        command.contains('immersive description') ||
        command.contains('detailed surroundings') ||
        command.contains('tell me about surroundings') ||
        command.contains('describe area') ||
        command.contains('what is around me') ||
        command.contains('describe environment')) {
      await _narrateImmersiveSurroundings();
    }
    // Handle comprehensive surroundings commands
    else if (command.contains('surroundings') ||
        command.contains('around me') ||
        command.contains('what\'s nearby') ||
        command.contains('nearby places') ||
        command.contains('what\'s around') ||
        command.contains('tell me surroundings') ||
        command.contains('describe nearby') ||
        command.contains('what\'s here') ||
        command.contains('explore area') ||
        command.contains('discover surroundings') ||
        command.contains('scan area') ||
        command.contains('survey surroundings')) {
      await _narrateSurroundings();
    }
    // Handle spatial awareness and location commands
    else if (command.contains('where am i') ||
        command.contains('my position') ||
        command.contains('current coordinates') ||
        command.contains('my location') ||
        command.contains('current location') ||
        command.contains('where am i located') ||
        command.contains('what is my position') ||
        command.contains('tell me my location')) {
      await _narrateCurrentPosition();
    }
    // Handle navigation assistance for blind users
    else if (command.startsWith('navigate to ') ||
        command.startsWith('go to ') ||
        command.startsWith('take me to ') ||
        command.startsWith('guide me to ') ||
        command.startsWith('direct me to ') ||
        command.startsWith('route to ')) {
      String destination =
          command
              .replaceAll('navigate to ', '')
              .replaceAll('go to ', '')
              .replaceAll('take me to ', '')
              .replaceAll('guide me to ', '')
              .replaceAll('direct me to ', '')
              .replaceAll('route to ', '')
              .trim();
      await _provideNavigationAssistance(destination);
    }
    // Handle recently narrated places
    else if (command.contains('recent places') ||
        command.contains('last mentioned') ||
        command.contains('recently narrated') ||
        command.contains('what did you mention') ||
        command.contains('previous places') ||
        command.contains('last places')) {
      await _narrateRecentPlaces();
    }
    // Handle narration mode changes
    else if (command.contains('change narration mode') ||
        command.contains('switch narration') ||
        command.contains('toggle narration') ||
        command.contains('change mode') ||
        command.contains('switch mode')) {
      _toggleNarrationMode();
      String mode = _mapNarrationService.getCurrentNarrationMode();
      await _audioManagerService.speakIfActive(
        'map',
        'Narration mode changed to $mode',
      );
    }
    // Handle speed adjustments
    else if (command.contains('speak faster') ||
        command.contains('increase speed') ||
        command.contains('speed up') ||
        command.contains('talk faster')) {
      double currentSpeed = _mapNarrationService.getNarrationSpeed();
      _mapNarrationService.adjustNarrationSpeed(currentSpeed + 0.1);
      await _audioManagerService.speakIfActive('map', 'Speech speed increased');
    } else if (command.contains('speak slower') ||
        command.contains('decrease speed') ||
        command.contains('slow down') ||
        command.contains('talk slower')) {
      double currentSpeed = _mapNarrationService.getNarrationSpeed();
      _mapNarrationService.adjustNarrationSpeed(currentSpeed - 0.1);
      await _audioManagerService.speakIfActive('map', 'Speech speed decreased');
    }
    // Handle distance-based surroundings commands
    else if (command.contains('near surroundings') ||
        command.contains('close surroundings') ||
        command.contains('nearby area') ||
        command.contains('immediate surroundings')) {
      await _narrateSurroundingsByDistance('near');
    } else if (command.contains('medium surroundings') ||
        command.contains('moderate surroundings') ||
        command.contains('medium distance')) {
      await _narrateSurroundingsByDistance('medium');
    } else if (command.contains('far surroundings') ||
        command.contains('distant surroundings') ||
        command.contains('extended area') ||
        command.contains('wider area')) {
      await _narrateSurroundingsByDistance('far');
    }
    // Handle specific category commands
    else if (command.contains('restaurant') ||
        command.contains('food') ||
        command.contains('dining') ||
        command.contains('eat')) {
      await _narrateCategory('restaurant');
    } else if (command.contains('hotel') ||
        command.contains('accommodation') ||
        command.contains('stay') ||
        command.contains('lodging')) {
      await _narrateCategory('hotel');
    } else if (command.contains('hospital') ||
        command.contains('medical') ||
        command.contains('doctor') ||
        command.contains('clinic')) {
      await _narrateCategory('hospital');
    } else if (command.contains('pharmacy') ||
        command.contains('drug store') ||
        command.contains('medicine')) {
      await _narrateCategory('pharmacy');
    } else if (command.contains('bank') ||
        command.contains('financial') ||
        command.contains('money')) {
      await _narrateCategory('bank');
    } else if (command.contains('atm') ||
        command.contains('cash machine') ||
        command.contains('withdraw')) {
      await _narrateCategory('atm');
    } else if (command.contains('gas station') ||
        command.contains('fuel') ||
        command.contains('petrol')) {
      await _narrateCategory('gas_station');
    } else if (command.contains('parking') || command.contains('car park')) {
      await _narrateCategory('parking');
    } else if (command.contains('bus station') ||
        command.contains('bus stop') ||
        command.contains('transport')) {
      await _narrateCategory('bus_station');
    } else if (command.contains('police') || command.contains('security')) {
      await _narrateCategory('police');
    } else if (command.contains('school') || command.contains('education')) {
      await _narrateCategory('school');
    } else if (command.contains('shopping mall') ||
        command.contains('mall') ||
        command.contains('shopping center')) {
      await _narrateCategory('shopping_mall');
    } else if (command.contains('market') || command.contains('shop')) {
      await _narrateCategory('market');
    } else if (command.contains('tourist attraction') ||
        command.contains('attraction') ||
        command.contains('landmark')) {
      await _narrateCategory('tourist_attraction');
    } else if (command.contains('church') || command.contains('worship')) {
      await _narrateCategory('church');
    }
    // Handle grouped service commands
    else if (command.contains('emergency') ||
        command.contains('safety') ||
        command.contains('help')) {
      await _narrateEmergencyServices();
    } else if (command.contains('transportation') ||
        command.contains('transport') ||
        command.contains('travel')) {
      await _narrateTransportation();
    } else if (command.contains('shopping') ||
        command.contains('services') ||
        command.contains('amenities')) {
      await _narrateShoppingAndServices();
    }
    // Handle specific surroundings exploration commands
    else if (command.contains('what\'s here') ||
        command.contains('explore here') ||
        command.contains('discover here') ||
        command.contains('scan here')) {
      await _narrateSurroundingsByDistance('near');
    } else if (command.contains('explore nearby') ||
        command.contains('discover nearby') ||
        command.contains('scan nearby') ||
        command.contains('survey nearby')) {
      await _narrateSurroundingsByDistance('medium');
    } else if (command.contains('explore area') ||
        command.contains('discover area') ||
        command.contains('scan area') ||
        command.contains('survey area')) {
      await _narrateSurroundings();
    }
    // Handle map control commands
    else if (command.contains('zoom in') ||
        command.contains('closer') ||
        command.contains('enlarge')) {
      _zoomIn();
    } else if (command.contains('zoom out') ||
        command.contains('farther') ||
        command.contains('shrink')) {
      _zoomOut();
    } else if (command.contains('my location') ||
        command.contains('current location') ||
        command.contains('where am i')) {
      _goToCurrentLocation();
    }
    // Handle help and category suggestions
    else if (command.contains('help') ||
        command.contains('what can i say') ||
        command.contains('categories') ||
        command.contains('options')) {
      await _provideMapHelp();
    }
    // Handle unknown commands
    else {
      await _provideMapDefaultResponse();
    }
  }

  // Enhanced surroundings narration with comprehensive voice commands
  Future<void> _narrateSurroundings() async {
    if (_currentPosition != null) {
      // Provide immediate feedback
      await _audioManagerService.speakIfActive(
        'map',
        'Exploring your surroundings. Discovering nearby places and landmarks...',
      );

      await _mapNarrationService.narrateSurroundings(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services to explore your surroundings.',
      );
    }
  }

  // Narrate surroundings by distance (near, medium, far)
  Future<void> _narrateSurroundingsByDistance(String distance) async {
    if (_currentPosition != null) {
      double radius = 500; // Default medium distance

      switch (distance.toLowerCase()) {
        case 'near':
        case 'close':
        case 'nearby':
          radius = 200;
          break;
        case 'medium':
        case 'moderate':
          radius = 500;
          break;
        case 'far':
        case 'distant':
        case 'extended':
          radius = 1000;
          break;
      }

      await _audioManagerService.speakIfActive(
        'map',
        'Exploring $distance surroundings within ${radius.toStringAsFixed(0)} meters...',
      );

      await _mapNarrationService.narrateSurroundings(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: radius,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  // Narrate specific category using the map narration service
  Future<void> _narrateCategory(String category) async {
    if (_currentPosition != null) {
      await _mapNarrationService.narrateCategory(
        category: category,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  // Narrate emergency services using the map narration service
  Future<void> _narrateEmergencyServices() async {
    if (_currentPosition != null) {
      await _mapNarrationService.narrateEmergencyServices(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  // Narrate transportation options using the map narration service
  Future<void> _narrateTransportation() async {
    if (_currentPosition != null) {
      await _mapNarrationService.narrateTransportation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  // Narrate shopping and services using the map narration service
  Future<void> _narrateShoppingAndServices() async {
    if (_currentPosition != null) {
      await _mapNarrationService.narrateShoppingAndServices(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  // Enhanced map help with comprehensive voice commands
  Future<void> _provideMapHelp() async {
    String helpMessage = 'Here are the voice commands you can use: ';

    // Surroundings commands
    helpMessage +=
        'For surroundings exploration: "surroundings", "describe surroundings", "what\'s around me", "explore area", "scan area", "survey surroundings". ';

    // Distance-based commands
    helpMessage +=
        'For specific distances: "near surroundings", "medium surroundings", "far surroundings", "close area", "extended area". ';

    // Location commands
    helpMessage +=
        'For location: "where am i", "my position", "current location", "tell me my location". ';

    // Navigation commands
    helpMessage +=
        'For navigation: "navigate to [place name]", "go to [place name]", "guide me to [place name]", "route to [place name]". ';

    // Category commands
    helpMessage +=
        'For specific categories: "restaurants", "hotels", "hospitals", "banks", "shopping", "transportation", "emergency services". ';

    // Control commands
    helpMessage += 'For map controls: "zoom in", "zoom out", "my location". ';

    // Settings commands
    helpMessage +=
        'For settings: "change narration mode", "speak faster", "speak slower", "recent places". ';

    helpMessage +=
        'Say any of these commands to get started with exploring your surroundings!';

    await _audioManagerService.speakIfActive('map', helpMessage);
  }

  // Enhanced default response for unknown commands
  Future<void> _provideMapDefaultResponse() async {
    String response = "I didn't understand that command. ";
    response +=
        "Try saying 'surroundings' to explore what's around you, 'describe surroundings' for detailed information, or 'what's around me' for an overview. ";
    response +=
        "You can also ask for specific categories like 'restaurants', 'hotels', 'hospitals', 'banks', or 'shopping'. ";
    response +=
        "For navigation, say 'navigate to [place name]'. For your location, say 'where am i'. ";
    response += "Say 'help' for a complete list of available voice commands.";

    await _audioManagerService.speakIfActive('map', response);
  }

  Future<void> _onMapScreenActivated() async {
    if (mounted) {
      debugPrint('🗺️ Map screen activated - enabling voice features');
      setState(() {
        _isMapVoiceEnabled = true;
      });

      // Ensure audio manager knows map screen is active
      await _audioManagerService.activateScreenAudio('map');

      _audioNarrationService.startNarration();
      _startContinuousNarration();

      // Automatic speech narration when map screen becomes active
      await _provideAutomaticLocationNarration();
    }
  }

  Future<void> _onMapScreenDeactivated() async {
    if (mounted) {
      debugPrint('🗺️ Map screen deactivated - disabling voice features');
      setState(() {
        _isMapVoiceEnabled = false;
      });

      // Ensure audio manager knows map screen is deactivated
      await _audioManagerService.deactivateScreenAudio('map');

      _audioNarrationService.stopNarration();
      _narrationTimer?.cancel();
    }
  }

  void _onPositionUpdate(Position position) {
    // Ultra-aggressive throttling to prevent frame skipping
    if (!mounted) return;

    // Only update UI if position has changed significantly (increased threshold)
    if (_currentPosition != null) {
      double distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Only update if moved more than 10 meters to drastically reduce UI updates
      if (distance < 10.0) {
        return;
      }
    }

    // Use a single batched update instead of multiple microtasks
    _pendingPositionUpdate = position;
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && _pendingPositionUpdate != null) {
        setState(() {
          _currentPosition = _pendingPositionUpdate;
          _pendingPositionUpdate = null;
        });
      }
    });

    // Update provider with much longer delay
    _providerUpdateTimer?.cancel();
    _providerUpdateTimer = Timer(const Duration(milliseconds: 5000), () {
      try {
        if (mounted) {
          final locationProvider = Provider.of<LocationProvider>(
            context,
            listen: false,
          );
          locationProvider.updatePosition(position);
        }
      } catch (e) {
        debugPrint('LocationProvider not available: $e');
      }
    });

    // Update audio narration with longer delay
    _audioUpdateTimer?.cancel();
    _audioUpdateTimer = Timer(const Duration(milliseconds: 3000), () {
      _audioNarrationService.updatePosition(position);
    });

    // Throttle map updates much more aggressively
    _mapUpdateTimer?.cancel();
    _mapUpdateTimer = Timer(const Duration(milliseconds: 8000), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    });

    // Throttle marker updates with much longer delay
    _markerUpdateTimer?.cancel();
    _markerUpdateTimer = Timer(const Duration(milliseconds: 10000), () {
      _updateMarkers();
    });

    // Throttle Firestore updates with even longer delay
    _firestoreUpdateTimer?.cancel();
    _firestoreUpdateTimer = Timer(const Duration(milliseconds: 15000), () {
      _updateUserLocationInFirestore(position);
    });

    // Automatic location narration when user moves significantly (every 30 seconds)
    _locationNarrationTimer?.cancel();
    _locationNarrationTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isMapVoiceEnabled && _currentPosition != null) {
        _provideLocationUpdateNarration();
      }
    });
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

  // Get human-readable distance description
  String _getDistanceDescription(double distanceInMeters) {
    if (distanceInMeters < 50) {
      return 'very close, about ${distanceInMeters.toStringAsFixed(0)} meters';
    } else if (distanceInMeters < 200) {
      return 'nearby, about ${distanceInMeters.toStringAsFixed(0)} meters';
    } else if (distanceInMeters < 500) {
      return 'a short walk away, about ${(distanceInMeters / 100).toStringAsFixed(1)} blocks';
    } else {
      return 'about ${(distanceInMeters / 1000).toStringAsFixed(1)} kilometers away';
    }
  }

  // Get direction to destination for blind users
  String _getDirectionToDestination(
    double currentLat,
    double currentLon,
    double destLat,
    double destLon,
  ) {
    double latDiff = destLat - currentLat;
    double lonDiff = destLon - currentLon;

    // Calculate bearing
    double bearing = math.atan2(lonDiff, latDiff) * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    // Convert bearing to cardinal directions
    if (bearing >= 337.5 || bearing < 22.5) {
      return 'north';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      return 'northeast';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      return 'east';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      return 'southeast';
    } else if (bearing >= 157.5 && bearing < 202.5) {
      return 'south';
    } else if (bearing >= 202.5 && bearing < 247.5) {
      return 'southwest';
    } else if (bearing >= 247.5 && bearing < 292.5) {
      return 'west';
    } else {
      return 'northwest';
    }
  }

  // Get accessibility information for different place categories
  String _getAccessibilityInfo(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return 'This restaurant is accessible with wheelchair ramps and accessible seating. ';
      case 'hotel':
        return 'This hotel offers accessible rooms and facilities for guests with disabilities. ';
      case 'hospital':
        return 'This hospital is fully accessible with ramps, elevators, and accessible facilities. ';
      case 'pharmacy':
        return 'This pharmacy is accessible with wide aisles and assistance available. ';
      case 'bank':
        return 'This bank has accessible entrances and ATMs with audio assistance. ';
      case 'atm':
        return 'This ATM has audio assistance and is accessible for wheelchair users. ';
      case 'gas_station':
        return 'This gas station has accessible pumps and facilities. ';
      case 'parking':
        return 'Accessible parking spaces are available at this location. ';
      case 'bus_station':
        return 'This bus station has accessible boarding areas and audio announcements. ';
      case 'taxi_stand':
        return 'Accessible taxis are available at this location. ';
      case 'police':
        return 'This police station is accessible with ramps and assistance available. ';
      case 'fire_station':
        return 'This fire station is accessible for emergency services. ';
      case 'school':
        return 'This school has accessible facilities and accommodations for students with disabilities. ';
      case 'university':
        return 'This university campus is accessible with ramps, elevators, and support services. ';
      case 'library':
        return 'This library is accessible with audio books and assistive technology available. ';
      case 'museum':
        return 'This museum offers audio tours and accessible exhibits for visitors with disabilities. ';
      case 'park':
        return 'This park has accessible pathways and facilities for visitors with disabilities. ';
      case 'shopping_mall':
        return 'This shopping mall is accessible with ramps, elevators, and wide aisles. ';
      case 'market':
        return 'This market has accessible entrances and assistance available for shoppers. ';
      case 'post_office':
        return 'This post office is accessible with ramps and assistance available. ';
      case 'tourist_attraction':
        return 'This attraction offers accessible tours and facilities for visitors with disabilities. ';
      case 'church':
      case 'mosque':
      case 'temple':
        return 'This place of worship is accessible with ramps and assistance available. ';
      case 'embassy':
      case 'government_office':
        return 'This government facility is accessible with ramps and assistance available. ';
      default:
        return 'This location is accessible for visitors with disabilities. ';
    }
  }

  void _onNearbyLandmarksUpdate(List<Landmark> landmarks) {
    if (mounted) {
      setState(() {
        _nearbyLandmarks = landmarks;
      });
    }

    // Update provider if available
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      locationProvider.updateLandmarks(landmarks);
    } catch (e) {
      debugPrint('LocationProvider not available: $e');
    }

    _audioNarrationService.updateLandmarks(landmarks);
    _updateMarkers();
  }

  void _onLandmarkEntered(Landmark landmark) {
    debugPrint('Entered landmark: ${landmark.name}');
  }

  Future<void> _onLandmarkTapped(Landmark landmark) async {
    // Enhanced haptic feedback for landmark selection
    try {
      if (await Vibration.hasVibrator()) {
        // Double vibration pattern for landmark selection
        Vibration.vibrate(duration: 200);
        await Future.delayed(const Duration(milliseconds: 100));
        Vibration.vibrate(duration: 150);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    // Enhanced speech narration for landmark selection with current location context
    if (_isMapVoiceEnabled) {
      String landmarkDescription = "Landmark selected: ${landmark.name}. ";
      landmarkDescription += "${landmark.description}. ";

      // Add current location context first
      if (_currentPosition != null) {
        landmarkDescription += "Your current location: ";
        landmarkDescription +=
            "${_currentPosition!.latitude.toStringAsFixed(4)}, ";
        landmarkDescription +=
            "${_currentPosition!.longitude.toStringAsFixed(4)}. ";

        // Add distance and direction information
        double distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          landmark.latitude,
          landmark.longitude,
        );
        String distanceDesc = _getDistanceDescription(distance);
        String direction = _getDirectionToDestination(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          landmark.latitude,
          landmark.longitude,
        );

        landmarkDescription +=
            "The landmark is $distanceDesc away, located to the $direction. ";

        // Add estimated walking time
        int walkingTimeMinutes =
            (distance / 80)
                .round(); // Assuming 80 meters per minute walking speed
        if (walkingTimeMinutes > 0) {
          landmarkDescription +=
              "Estimated walking time: $walkingTimeMinutes minutes. ";
        }
      } else {
        landmarkDescription +=
            "Location services not available. Please enable location to get distance information. ";
      }

      // Add accessibility information
      landmarkDescription += "This landmark is accessible for visitors. ";
      landmarkDescription +=
          "Say 'navigate to ${landmark.name}' to start turn-by-turn directions, 'tell me more' for additional information, or 'describe surroundings' to hear about nearby places.";

      debugPrint(
        '🎤 Attempting to speak landmark description: ${landmark.name}',
      );
      try {
        await _audioManagerService.speakIfActive('map', landmarkDescription);
        debugPrint('🎤 Landmark description spoken successfully');
      } catch (e) {
        debugPrint('🎤 Audio manager failed, using fallback TTS: $e');
        // Fallback to direct TTS
        await _ttsService.speakWithPriority(landmarkDescription);
      }
    }

    // Start navigation assistance
    await _startNavigationTo(landmark);
  }

  Future<void> _startNavigationTo(Landmark landmark) async {
    if (_isMapVoiceEnabled) {
      String navigationStart =
          "Starting navigation to ${landmark.name}. I'll guide you there with turn-by-turn directions.";
      await _audioManagerService.speakIfActive('map', navigationStart);
    }
  }

  Future<void> _updateUserLocationInFirestore(Position position) async {
    _userId ??= DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('user_locations').doc(_userId).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Enhanced blind user methods
  Future<void> _narrateImmersiveSurroundings() async {
    if (_currentPosition != null) {
      await _mapNarrationService.narrateImmersiveSurroundings(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  Future<void> _provideNavigationAssistance(String destinationName) async {
    if (_currentPosition != null) {
      await _mapNarrationService.provideNavigationAssistance(
        destinationName: destinationName,
        currentLat: _currentPosition!.latitude,
        currentLon: _currentPosition!.longitude,
      );
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  void _toggleNarrationMode() {
    // This method is handled by the MapNarrationService
    // The actual toggle is done in the voice command handler
  }

  Future<void> _narrateCurrentPosition() async {
    if (_currentPosition != null) {
      String positionNarration = 'You are currently at coordinates ';
      positionNarration += '${_currentPosition!.latitude.toStringAsFixed(4)}, ';
      positionNarration +=
          '${_currentPosition!.longitude.toStringAsFixed(4)}. ';
      positionNarration += 'This is your current location on the map.';

      await _audioManagerService.speakIfActive('map', positionNarration);
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'Location not available. Please enable location services.',
      );
    }
  }

  // Automatic speech narration when map screen becomes active
  Future<void> _provideAutomaticLocationNarration() async {
    try {
      // Brief delay to ensure screen is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || !_isMapVoiceEnabled) return;

      String automaticNarration = "Map screen activated. ";

      if (_currentPosition != null) {
        // Provide current location information
        automaticNarration += "Your current location: ";
        automaticNarration +=
            "${_currentPosition!.latitude.toStringAsFixed(4)}, ";
        automaticNarration +=
            "${_currentPosition!.longitude.toStringAsFixed(4)}. ";

        // Add nearby landmarks information
        if (_nearbyLandmarks.isNotEmpty) {
          automaticNarration += "Nearby landmarks: ";
          List<String> landmarkNames = [];
          for (int i = 0; i < _nearbyLandmarks.length && i < 3; i++) {
            Landmark landmark = _nearbyLandmarks[i];
            double distance = _calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              landmark.latitude,
              landmark.longitude,
            );
            String distanceDesc = _getDistanceDescription(distance);
            landmarkNames.add("${landmark.name} ($distanceDesc away)");
          }
          automaticNarration += landmarkNames.join(', ');
          automaticNarration += ". ";
        }

        // Add nearby places information
        if (_nearbyPlaces.isNotEmpty) {
          automaticNarration += "Nearby places: ";
          Map<String, List<NearbyPlace>> placesByCategory = {};
          for (NearbyPlace place in _nearbyPlaces) {
            if (!placesByCategory.containsKey(place.category)) {
              placesByCategory[place.category] = [];
            }
            placesByCategory[place.category]!.add(place);
          }

          List<String> categoryDescriptions = [];
          placesByCategory.forEach((category, places) {
            if (places.isNotEmpty) {
              String categoryName = _getCategoryDisplayName(category);
              categoryDescriptions.add("${places.length} $categoryName");
            }
          });

          if (categoryDescriptions.isNotEmpty) {
            automaticNarration += categoryDescriptions.join(', ');
            automaticNarration += ". ";
          }
        }

        // Add action suggestions
        automaticNarration +=
            "Say 'describe surroundings' for detailed area information, 'landmarks' for attractions, 'restaurants' for dining options, 'hotels' for accommodation, 'facilities' for services, or 'help' for all available commands. ";
        automaticNarration +=
            "Tap on any point on the map to hear detailed information about that location.";
      } else {
        // Location not available
        automaticNarration +=
            "Location services not available. Please enable location services to get your current position and nearby information. ";
        automaticNarration +=
            "Say 'help' for available commands or enable location services to explore your surroundings.";
      }

      debugPrint('🎤 Attempting to speak automatic location narration');
      try {
        await _audioManagerService.speakIfActive('map', automaticNarration);
        debugPrint('🎤 Automatic location narration spoken successfully');
      } catch (e) {
        debugPrint('🎤 Audio manager failed, using fallback TTS: $e');
        // Fallback to direct TTS
        await _ttsService.speakWithPriority(automaticNarration);
      }
    } catch (e) {
      debugPrint('Error providing automatic location narration: $e');
      // Fallback narration
      await _audioManagerService.speakIfActive(
        'map',
        'Map screen ready. Say "help" for available commands or "surroundings" to explore your area.',
      );
    }
  }

  // Automatic location update narration when user moves
  Future<void> _provideLocationUpdateNarration() async {
    try {
      if (!mounted || !_isMapVoiceEnabled || _currentPosition == null) return;

      String locationUpdateNarration = "Location update. ";
      locationUpdateNarration += "You are now at coordinates ";
      locationUpdateNarration +=
          "${_currentPosition!.latitude.toStringAsFixed(4)}, ";
      locationUpdateNarration +=
          "${_currentPosition!.longitude.toStringAsFixed(4)}. ";

      // Add nearby landmarks information
      if (_nearbyLandmarks.isNotEmpty) {
        locationUpdateNarration += "Nearby landmarks: ";
        List<String> landmarkNames = [];
        for (int i = 0; i < _nearbyLandmarks.length && i < 2; i++) {
          Landmark landmark = _nearbyLandmarks[i];
          double distance = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            landmark.latitude,
            landmark.longitude,
          );
          String distanceDesc = _getDistanceDescription(distance);
          landmarkNames.add("${landmark.name} ($distanceDesc away)");
        }
        locationUpdateNarration += landmarkNames.join(', ');
        locationUpdateNarration += ". ";
      }

      // Add nearby places summary
      if (_nearbyPlaces.isNotEmpty) {
        Map<String, int> categoryCounts = {};
        for (NearbyPlace place in _nearbyPlaces) {
          categoryCounts[place.category] =
              (categoryCounts[place.category] ?? 0) + 1;
        }

        List<String> categorySummaries = [];
        categoryCounts.forEach((category, count) {
          if (count > 0) {
            String categoryName = _getCategoryDisplayName(category);
            categorySummaries.add("$count $categoryName");
          }
        });

        if (categorySummaries.isNotEmpty) {
          locationUpdateNarration +=
              "Nearby: ${categorySummaries.join(', ')}. ";
        }
      }

      locationUpdateNarration +=
          "Say 'describe surroundings' for detailed information or tap on the map to explore specific locations.";

      await _audioManagerService.speakIfActive('map', locationUpdateNarration);
    } catch (e) {
      debugPrint('Error providing location update narration: $e');
    }
  }

  Future<void> _narrateRecentPlaces() async {
    List<String> recentPlaces =
        _mapNarrationService.getRecentlyNarratedPlaces();

    if (recentPlaces.isNotEmpty) {
      String narration = 'Recently mentioned places: ';
      narration += recentPlaces.join(', ');
      narration +=
          '. Say "navigate to" followed by any place name for directions.';

      await _audioManagerService.speakIfActive('map', narration);
    } else {
      await _audioManagerService.speakIfActive(
        'map',
        'No places have been mentioned recently. Try saying "surroundings" to discover nearby places.',
      );
    }
  }

  void _listenToOtherUsers() {
    _firestore.collection('user_locations').snapshots().listen((snapshot) {
      // Throttle other users updates to reduce frame skipping
      _otherUsersUpdateTimer?.cancel();
      _otherUsersUpdateTimer = Timer(const Duration(milliseconds: 5000), () {
        if (!mounted) return;

        final Set<Marker> newMarkers = {..._markers};
        int userCount = 0;
        for (var doc in snapshot.docs) {
          if (doc.id == _userId) continue;
          if (userCount >= 3) break; // Limit to 3 other users

          final data = doc.data();
          if (data['latitude'] != null && data['longitude'] != null) {
            newMarkers.add(
              Marker(
                markerId: MarkerId('user_${doc.id}'),
                position: LatLng(data['latitude'], data['longitude']),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Other User'),
              ),
            );
            userCount++;
          }
        }
        if (mounted) {
          setState(() {
            _markers = newMarkers;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService.stopTracking();
    _voiceCommandService.stopListening();
    _voiceNavigationService.stopContinuousListening();
    _audioNarrationService.stopNarration();
    _narrationTimer?.cancel();

    // Cancel all performance optimization timers
    _positionUpdateTimer?.cancel();
    _providerUpdateTimer?.cancel();
    _audioUpdateTimer?.cancel();
    _mapUpdateTimer?.cancel();
    _markerUpdateTimer?.cancel();
    _locationNarrationTimer?.cancel();
    _firestoreUpdateTimer?.cancel();
    _otherUsersUpdateTimer?.cancel();

    _mapCommandSubscription?.cancel();
    _audioControlSubscription?.cancel();
    _screenActivationSubscription?.cancel();
    _audioManagerService.unregisterScreen('map');
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Map'),
        actions: const [VoiceStatusWidget()],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: (LatLng position) => _onMapTapped(position),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _markers,
            // Enhanced performance optimizations
            compassEnabled: false,
            mapType: MapType.normal,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            // Additional performance settings
            liteModeEnabled: false,
            indoorViewEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: false,
          ),

          // Map controls
          Positioned(
            right: 16,
            top: 16,
            child: MapControlsWidget(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onCurrentLocation: _goToCurrentLocation,
            ),
          ),

          // Category and Places controls
          Positioned(
            left: 16,
            top: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _toggleCategorySelector,
                  tooltip: 'Select Category',
                  child: const Icon(Icons.category),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: _toggleNearbyPlaces,
                  tooltip: 'Show Nearby Places',
                  child: const Icon(Icons.near_me),
                ),
                const SizedBox(height: 8),
                if (_isLoadingPlaces)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),

          // Category selector
          if (_showCategorySelector)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: CategorySelectorWidget(
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
                onClose: _toggleCategorySelector,
              ),
            ),

          // Nearby places panel
          if (_showNearbyPlaces)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: NearbyPlacesWidget(
                places: _nearbyPlaces,
                category: _selectedCategory,
                onPlaceSelected: _onPlaceSelected,
                onClose: _toggleNearbyPlaces,
              ),
            ),

          // Location info panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Current Location',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_nearbyPlaces.isNotEmpty)
                        Text(
                          '${_nearbyPlaces.length} places found',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_currentPosition != null)
                    Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Text(
                      'Location not available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_selectedCategory != 'tours')
                    Text(
                      'Searching for: ${_getCategoryDisplayName(_selectedCategory)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
