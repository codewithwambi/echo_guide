import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_navigation_service.dart';
import '../services/audio_manager_service.dart';

class VoiceCommandHelper extends StatefulWidget {
  final String currentScreen;
  final bool isListening;
  final VoidCallback? onVoiceToggle;

  final Future<void> Function(String command)? onVoiceCommand;

  const VoiceCommandHelper({
    super.key,
    required this.currentScreen,
    required this.isListening,
    this.onVoiceToggle,
    this.onVoiceCommand,
  });

  @override
  State<VoiceCommandHelper> createState() => _VoiceCommandHelperState();
}

class _VoiceCommandHelperState extends State<VoiceCommandHelper> {
  final AudioManagerService _audioManager = AudioManagerService();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Voice status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.isListening ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status text
              Text(
                widget.isListening
                    ? 'Listening for voice commands...'
                    : 'Voice commands disabled',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Current screen info
              Text(
                'Current screen: ${widget.currentScreen}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Voice command suggestions
              _buildVoiceSuggestions(),
              const SizedBox(height: 12),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle voice button
                  ElevatedButton.icon(
                    onPressed: widget.onVoiceToggle,
                    icon: Icon(widget.isListening ? Icons.mic_off : Icons.mic),
                    label: Text(
                      widget.isListening ? 'Stop Voice' : 'Start Voice',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.isListening ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  // Help button
                  ElevatedButton.icon(
                    onPressed: _showVoiceHelp,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Help'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceSuggestions() {
    List<String> suggestions = _getSuggestionsForScreen(widget.currentScreen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try saying:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              suggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () => _speakSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  List<String> _getSuggestionsForScreen(String screen) {
    switch (screen.toLowerCase()) {
      case 'home':
        return ['map', 'tours', 'downloads', 'help', 'welcome'];
      case 'map':
        return [
          'surroundings',
          'places',
          'facilities',
          'tips',
          'zoom in',
          'zoom out',
        ];
      case 'discover':
        return ['explore', 'tours', 'refresh', 'help'];
      case 'downloads':
        return ['play', 'pause', 'stop', 'next', 'previous', 'help'];
      case 'help':
        return ['topics', 'assistance', 'read all', 'back'];
      default:
        return ['help', 'explore', 'navigate'];
    }
  }

  void _speakSuggestion(String suggestion) async {
    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Speak the suggestion
    await _audioManager.speakIfActive(
      widget.currentScreen,
      "Try saying: $suggestion",
    );
  }

  void _showVoiceHelp() async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Show help dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Voice Commands'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Navigation:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• "map" - Go to map'),
                  const Text('• "tours" - Go to tours'),
                  const Text('• "downloads" - Go to downloads'),
                  const Text('• "help" - Go to help'),
                  const SizedBox(height: 16),
                  const Text(
                    'Tour Discovery:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• "explore" - Discover tours'),
                  const Text('• "refresh" - Update location'),
                  const SizedBox(height: 16),
                  const Text(
                    'Downloads:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• "play" - Play selected tour'),
                  const Text('• "pause" - Pause playback'),
                  const Text('• "stop" - Stop playback'),
                  const Text('• "next" - Next tour'),
                  const Text('• "previous" - Previous tour'),
                  const SizedBox(height: 16),
                  const Text(
                    'Help:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• "one" through "six" - Topic help'),
                  const Text('• "read all" - All commands'),
                  const Text('• "back" - Go back'),
                  const SizedBox(height: 16),
                  const Text(
                    'General:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• "help" - Get help'),
                  const Text('• "stop" - Stop current action'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
