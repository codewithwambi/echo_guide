import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:geolocator/geolocator.dart';
import 'audio_guide_screen.dart';

class TourDiscoveryScreen extends StatefulWidget {
  const TourDiscoveryScreen({super.key});

  @override
  State<TourDiscoveryScreen> createState() => _TourDiscoveryScreenState();
}

class _TourDiscoveryScreenState extends State<TourDiscoveryScreen> {
  String locationInfo = "Fetching nearby attractions...";

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    // Check for location service permission and status
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationInfo = "Location services are disabled. Please enable them.";
      });
      FlutterTts().speak(locationInfo);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationInfo = "Location permissions are denied. Please grant them.";
        });
        FlutterTts().speak(locationInfo);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationInfo = "Location permissions are permanently denied. We cannot request permissions.";
      });
      FlutterTts().speak(locationInfo);
      return;
    }

    // Corrected for geolocator 14.0.2: use 'locationSettings' parameter
    // The 'position' variable is still not directly used in this specific example
    // but if you were to use its latitude/longitude, you would store the result:
    // Position position = await Geolocator.getCurrentPosition(
    //   locationSettings: LocationSettings(
    //     accuracy: LocationAccuracy.high,
    //   ),
    // );
    await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high, // Use LocationAccuracy enum
      ),
    );


    // Fake check. Replace with actual Firestore query using the fetched position.
    setState(() {
      locationInfo =
          "You are near Murchison Falls. Would you like to start the tour?";
    });
    FlutterTts().speak(locationInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Nearby Tours")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(locationInfo, style: TextStyle(color: Colors.white)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AudioGuideScreen()),
              ),
              child: Text("Start Audio Tour"),
            ),
          ],
        ),
      ),
    );
  }
}