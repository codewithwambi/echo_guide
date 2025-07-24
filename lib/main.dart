import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'tour_discovery_screen.dart';
import 'audio_guide_screen.dart';
import 'downloads_screen.dart';
import 'help_and_support_screen.dart';

void main() {
  runApp(const MyApp());
} // Corrected: removed extra ')' and added missing '}' for the main function

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.black,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0),
          bodyMedium: TextStyle(fontSize: 16.0),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // Initial screen
      home: const SplashScreen(),

      // Named routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/tour-discovery': (context) => const TourDiscoveryScreen(),
        '/audio-guide': (context) => const AudioGuideScreen(),
        '/downloads': (context) => const DownloadsScreen(),
        '/help-support': (context) => const HelpAndSupportScreen(),
      },
    ); // Corrected: added missing ')' for the MaterialApp
  }
}