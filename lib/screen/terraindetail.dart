import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TerrainDetailScreen extends StatefulWidget {
  final String terrainId;

  const TerrainDetailScreen({super.key, required this.terrainId});

  @override
  State<TerrainDetailScreen> createState() => _TerrainDetailScreenState();
}

class _TerrainDetailScreenState extends State<TerrainDetailScreen> {
  String? _selectedDay;
  String? _selectedHour;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terrain')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('terrains')
            .doc(widget.terrainId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Terrain not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> slots = data['slots'] ?? [];

          // Build a map of day -> list of hours from the slots array
          final Map<String, List<String>> daySlots = {
            for (final entry in slots)
              (entry as Map<String, dynamic>).keys.first: List<String>.from(
                entry.values.first,
              ),
          };

          final days = daySlots.keys.toList();
          final hours = _selectedDay != null
              ? daySlots[_selectedDay!] ?? []
              : <String>[];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['picture'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['location'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Day'),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedDay,
                  hint: const Text('Select a day'),
                  items: days
                      .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value;
                      _selectedHour = null; // reset hour when day changes
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text('Hour'),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedHour,
                  hint: const Text('Select an hour'),
                  items: hours
                      .map(
                        (hour) =>
                            DropdownMenuItem(value: hour, child: Text(hour)),
                      )
                      .toList(),
                  onChanged: _selectedDay == null
                      ? null
                      : (value) => setState(() => _selectedHour = value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
