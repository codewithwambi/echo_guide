import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _filter = 'Nature';
  bool _offlineOnly = false;

  final List<Site> _sites = [
    Site(name: 'Murchison Falls', category: 'Nature', offline: true),
    Site(name: 'Nile Museum', category: 'Cultural', offline: false),
    Site(name: 'Old Kampala', category: 'History', offline: true),
  ];

  void startAudioTour(Site site) {
    // Simulated audio tour start
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting audio tour for ${site.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Site> filtered = _sites.where((s) {
      return s.category == _filter && (!_offlineOnly || s.offline);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Sites')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: _filter,
                items: ['Nature', 'History', 'Cultural']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _filter = v!),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _offlineOnly,
                    onChanged: (v) => setState(() => _offlineOnly = v!),
                  ),
                  const Text('Offline only'),
                ],
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final site = filtered[i];
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(site.name),
                  subtitle: Text('${site.category} • ${site.offline ? 'Offline ready' : 'Online only'}'),
                  onTap: () async {
                    final response = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('You’re near ${site.name}'),
                        content: const Text('Would you like to start the audio tour?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                        ],
                      ),
                    );

                    // ✅ Fix: Use mounted check before using context
                    if (mounted && response == true) {
                      startAudioTour(site);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Site {
  final String name;
  final String category;
  final bool offline;

  Site({required this.name, required this.category, required this.offline});
}
