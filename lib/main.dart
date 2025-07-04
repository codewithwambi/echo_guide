import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Ensure splash_screen.dart exists in lib/

void main() {
  runApp(const MyApp());
}

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
      home: const SplashScreen(), // First screen the user sees
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(
            child: Text(
              'Page not found',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
