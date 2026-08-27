import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _priceController = TextEditingController();

  String? _selectedTerrainId;
  Map<String, dynamic>? _selectedTerrainData;
  String? _selectedDay;
  String? _selectedHour;

  String _genderOption = 'mixed'; // male / female / mixed
  bool _isCompetition = false;
  double _level = 3.5; // 0.5 - 7 range

  Future<void> _createGame() async {
    if (_selectedTerrainId == null ||
        _selectedDay == null ||
        _selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select terrain, day and hour')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('games').add({
      'terrainId': _selectedTerrainId,
      'location': _selectedTerrainData?['location'],
      'date': _selectedDay,
      'hour': _selectedHour,
      'gender': _genderOption,
      'competition': _isCompetition,
      'level': _level,
      'price': double.tryParse(_priceController.text) ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Game created')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Game')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Terrain'),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('terrains')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final docs = snapshot.data!.docs;

                return DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedTerrainId,
                  hint: const Text('Select terrain'),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['location'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final doc = docs.firstWhere((d) => d.id == value);
                    setState(() {
                      _selectedTerrainId = value;
                      _selectedTerrainData = doc.data() as Map<String, dynamic>;
                      _selectedDay = null;
                      _selectedHour = null;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            if (_selectedTerrainData != null) ...[
              const Text('Day'),
              Builder(
                builder: (context) {
                  final List<dynamic> slots =
                      _selectedTerrainData!['slots'] ?? [];
                  final Map<String, List<String>> daySlots = {
                    for (final entry in slots)
                      (entry as Map<String, dynamic>).keys.first:
                          List<String>.from(entry.values.first),
                  };
                  final days = daySlots.keys.toList();
                  final hours = _selectedDay != null
                      ? daySlots[_selectedDay!] ?? []
                      : <String>[];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDay,
                        hint: const Text('Select a day'),
                        items: days
                            .map(
                              (day) => DropdownMenuItem(
                                value: day,
                                child: Text(day),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _selectedDay = value;
                          _selectedHour = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      const Text('Hour'),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedHour,
                        hint: const Text('Select an hour'),
                        items: hours
                            .map(
                              (hour) => DropdownMenuItem(
                                value: hour,
                                child: Text(hour),
                              ),
                            )
                            .toList(),
                        onChanged: _selectedDay == null
                            ? null
                            : (value) => setState(() => _selectedHour = value),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            const Text('Gender'),
            RadioGroup<String>(
              groupValue: _genderOption,
              onChanged: (value) => setState(() => _genderOption = value!),
              child: const Column(
                children: [
                  RadioListTile<String>(title: Text('Male'), value: 'male'),
                  RadioListTile<String>(title: Text('Female'), value: 'female'),
                  RadioListTile<String>(title: Text('Mixed'), value: 'mixed'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text('Competition'),
              value: _isCompetition,
              onChanged: (value) => setState(() => _isCompetition = value!),
            ),
            const SizedBox(height: 16),

            Text('Level: ${_level.toStringAsFixed(1)}'),
            Slider(
              value: _level,
              min: 0.5,
              max: 7,
              divisions: 13, // steps of 0.5
              label: _level.toStringAsFixed(1),
              onChanged: (value) => setState(() => _level = value),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _createGame,
              child: const Text('Create Game'),
            ),
          ],
        ),
      ),
    );
  }
}
