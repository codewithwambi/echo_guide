import 'package:flutter/material.dart'; // Import the Material Design library

class DownloadsScreen extends StatelessWidget {
  // It's good practice for public StatelessWidgets to have a const constructor with a Key.
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Offline Downloads"), // Make AppBar title const
        backgroundColor: Colors.black, // Match Scaffold background for a consistent dark theme
        foregroundColor: Colors.white, // Set back button and title color
      ),
      body: Center(
        child: Column(
          children: const [ // Make Column children const if all items are const
            ListTile(
              title: Text("Murchison Falls", style: TextStyle(color: Colors.white)),
              subtitle: Text("Downloaded", style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              title: Text("Kasubi Tombs", style: TextStyle(color: Colors.white)), // Corrected typo: Kasula -> Kasubi
              subtitle: Text("Downloaded", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}