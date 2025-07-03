import 'package:flutter/material.dart';

class LoginGuestScreen extends StatelessWidget {
  const LoginGuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Login or Continue as Guest',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  // TODO: Implement login with email
                },
                child: const Text('Log in with Email'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  // 
                },
                child: const Text(
                  'Continue with Google',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to home or guest flow
                },
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
