import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Import the audioplayers package

class AudioGuideScreen extends StatefulWidget {
  const AudioGuideScreen({super.key});

  @override
  State<AudioGuideScreen> createState() => _AudioGuideScreenState();
}

class _AudioGuideScreenState extends State<AudioGuideScreen> {
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  String currentTrackTitle = "Murchison Falls Tour Audio";
  // Replace with your actual audio URL
  final String audioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();

    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    if (!isPlaying) {
      await audioPlayer.play(UrlSource(audioUrl));
    }
  }

  Future<void> _pauseAudio() async {
    if (isPlaying) {
      await audioPlayer.pause();
    }
  }

  Future<void> _stopAudio() async {
    await audioPlayer.stop();
    if (mounted) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Murchison Falls Tour"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.place, color: Colors.white, size: 100),
            const SizedBox(height: 20),
            Text(
              isPlaying ? "Playing: $currentTrackTitle" : "Ready to Play: $currentTrackTitle",
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 80,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      _pauseAudio();
                    } else {
                      _playAudio();
                    }
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  // --- FIX: Changed Icons.stop_circle_filled to Icons.stop_circle ---
                  icon: const Icon(
                    Icons.stop_circle, // This is the correct icon name
                    color: Colors.white,
                    size: 80,
                  ),
                  onPressed: _stopAudio,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}