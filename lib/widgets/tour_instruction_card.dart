import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TourInstructionCard extends StatefulWidget {
  final VoidCallback? onVoiceHelp;
  final VoidCallback? onTouchHelp;

  const TourInstructionCard({super.key, this.onVoiceHelp, this.onTouchHelp});

  @override
  State<TourInstructionCard> createState() => _TourInstructionCardState();
}

class _TourInstructionCardState extends State<TourInstructionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "How to Use Tour Discovery",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                      HapticFeedback.lightImpact();
                    },
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState:
                  _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: _buildQuickInstructions(),
              secondChild: _buildDetailedInstructions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionRow(
            icon: Icons.mic,
            title: "Voice Commands",
            description: "Use voice commands to explore and select tours",
            onTap: widget.onVoiceHelp,
          ),
          const SizedBox(height: 12),
          _buildInstructionRow(
            icon: Icons.touch_app,
            title: "Touch Controls",
            description: "Tap tour cards or 'Start' buttons",
            onTap: widget.onTouchHelp,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Quick Tip: Use voice commands to explore tours and discover amazing places",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailedSection("🎤 Voice Commands", [
            "• Use voice commands to explore tours",
            "• Say tour names to select them",
            "• 'refresh' - Update location",
            "• 'help' - Get assistance",
            "• 'play' - Start selected tour",
            "• 'pause' - Pause current tour",
          ], Colors.blue),
          const SizedBox(height: 16),
          _buildDetailedSection("👆 Touch Controls", [
            "• Tap tour cards for details",
            "• Tap 'Start' button to begin",
            "• Swipe to browse tours",
            "• Pull down to refresh",
          ], Colors.purple),
          const SizedBox(height: 16),
          _buildDetailedSection("📱 Available Tours", [
            "• Discover amazing tour destinations",
            "• Each tour offers unique experiences",
            "• Tours vary in duration and difficulty",
            "• Explore at your own pace",
          ], Colors.orange),
        ],
      ),
    );
  }

  Widget _buildInstructionRow({
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
