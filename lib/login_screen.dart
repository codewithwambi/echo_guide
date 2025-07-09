import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import GoogleSignIn
import 'home_screen.dart'; // Ensure this exists and is your main app screen

// For basic logging in development, you can use `debugPrint` or a simple logger
// For production, consider packages like 'logger' or 'flutter_logs'
import 'dart:developer' as developer; // Import for developer.log

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User cancelled the sign-in process
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          // --- FIX 1: Removed 'const' from HomeScreen() ---
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      // --- FIX 2: Replaced print() with developer.log() or debugPrint() ---
      developer.log("Google Sign-In Error: $e", name: "LoginScreen");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Failed: ${e.toString()}')), // Use e.toString() for better display
        );
      }
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          // --- FIX 1: Removed 'const' from HomeScreen() ---
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      // --- FIX 2: Replaced print() with developer.log() or debugPrint() ---
      developer.log("Anonymous Sign-In Error: $e", name: "LoginScreen");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anonymous Sign-In Failed: ${e.toString()}')), // Use e.toString() for better display
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Login to EchoPath",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signInWithGoogle, // Simplified callback
              child: const Text("Continue with Google"),
            ),
            ElevatedButton(
              onPressed: signInAnonymously, // Simplified callback
              child: const Text("Continue as Guest"),
            ),
          ],
        ),
      ),
    );
  }
}