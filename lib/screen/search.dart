import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  double? _skillFilter;
  String? _dateFilter;
  String? _hourFilter;
  String? _locationFilter;
  String? _genderFilter; // null = any, 'mixed', 'male', 'female'
  bool? _competitionFilter; // null = any, true, false

  List<Map<String, dynamic>> _applyFilters(List<QueryDocumentSnapshot> docs) {
    return docs.map((d) => d.data() as Map<String, dynamic>).where((game) {
      if (_skillFilter != null && game['level'] != _skillFilter) return false;
      if (_dateFilter != null && game['date'] != _dateFilter) return false;
      if (_hourFilter != null && game['hour'] != _hourFilter) return false;
      if (_locationFilter != null && game['location'] != _locationFilter) {
        return false;
      }
      if (_genderFilter != null && game['gender'] != _genderFilter) {
        return false;
      }
      if (_competitionFilter != null &&
          game['competition'] != _competitionFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('games').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;
          final allGames = allDocs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          // Build filter option lists from the full dataset, skipping nulls
          final dates = allGames
              .map((g) => g['date'] as String?)
              .whereType<String>()
              .toSet()
              .toList();
          final hours = allGames
              .map((g) => g['hour'] as String?)
              .whereType<String>()
              .toSet()
              .toList();
          final locations = allGames
              .map((g) => g['location'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          final filtered = _applyFilters(allDocs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _dateFilter,
                            hint: const Text('Date'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Any date'),
                              ),
                              ...dates.map(
                                (d) => DropdownMenuItem<String?>(
                                  value: d,
                                  child: Text(d),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _dateFilter = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _hourFilter,
                            hint: const Text('Hour'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Any hour'),
                              ),
                              ...hours.map(
                                (h) => DropdownMenuItem<String?>(
                                  value: h,
                                  child: Text(h),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _hourFilter = value),
                          ),
                        ),
                      ],
                    ),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: _locationFilter,
                      hint: const Text('Location'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any location'),
                        ),
                        ...locations.map(
                          (l) => DropdownMenuItem<String?>(
                            value: l,
                            child: Text(l),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _locationFilter = value),
                    ),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: _genderFilter,
                      hint: const Text('Gender'),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any gender'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'mixed',
                          child: Text('Mixed'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _genderFilter = value),
                    ),
                    Row(
                      children: [
                        const Text('Skill:'),
                        Expanded(
                          child: Slider(
                            value: _skillFilter ?? 0.5,
                            min: 0.5,
                            max: 7,
                            divisions: 13,
                            label: _skillFilter?.toStringAsFixed(1) ?? 'Any',
                            onChanged: (value) =>
                                setState(() => _skillFilter = value),
                          ),
                        ),
                        if (_skillFilter != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _skillFilter = null),
                          ),
                      ],
                    ),
                    CheckboxListTile(
                      title: const Text('Competition only'),
                      value: _competitionFilter ?? false,
                      tristate: false,
                      onChanged: (value) => setState(
                        () =>
                            _competitionFilter = (value == true) ? true : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No games match your filters'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final game = filtered[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(game['location'] ?? ''),
                              subtitle: Text(
                                '${game['date'] ?? '?'} • ${game['hour'] ?? '?'} • '
                                '${game['gender'] ?? '?'} • Level ${game['level'] ?? '?'}',
                              ),
                              trailing: Text('€${game['price'] ?? '?'}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
