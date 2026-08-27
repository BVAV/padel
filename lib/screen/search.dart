import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final game = doc.data() as Map<String, dynamic>;
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

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGameTap(
    BuildContext context,
    String gameId,
    Map<String, dynamic> game,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final userData = userDoc.data() ?? {};

    final List<dynamic> players = game['players'] ?? [];
    final alreadyJoined = players.any(
      (p) => (p as Map<String, dynamic>)['id'] == currentUser.uid,
    );

    final gameGender = game['gender'] as String?;
    final userGender = userData['gender'] as String?;
    final genderOk =
        gameGender == null || gameGender == 'mixed' || gameGender == userGender;

    final gameLevel = (game['level'] as num?)?.toDouble();
    final userSkill = (userData['skill'] as num?)?.toDouble();
    final skillOk =
        gameLevel == null ||
        userSkill == null ||
        (userSkill - gameLevel).abs() <= 1.0;

    if (!context.mounted) return;

    if (alreadyJoined) {
      _showMessage(context, 'You are already in this game');
      return;
    }

    if (!genderOk) {
      _showMessage(context, 'This game is not open to your gender');
      return;
    }

    if (!skillOk) {
      _showMessage(context, 'Your skill level does not match this game');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Game'),
        content: const Text('Are you sure you want to join this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('games').doc(gameId).update({
        'players': FieldValue.arrayUnion([
          {'id': currentUser.uid, 'name': userData['name'] ?? ''},
        ]),
      });

      if (context.mounted) {
        _showMessage(context, 'You joined the game');
      }
    }
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
                          final doc = filtered[index];
                          final game = doc.data() as Map<String, dynamic>;

                          final List<dynamic> players = game['players'] ?? [];
                          final names = players
                              .map(
                                (p) =>
                                    (p as Map<String, dynamic>)['name']
                                        as String? ??
                                    '?',
                              )
                              .toList();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              onTap: () {
                                _handleGameTap(context, doc.id, game);
                              },
                              title: Text(game['location'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${game['date'] ?? '?'} • ${game['hour'] ?? '?'} • '
                                    '${game['gender'] ?? '?'} • Level ${game['level'] ?? '?'}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    names.isEmpty
                                        ? 'No players yet'
                                        : 'Players: ${names.join(', ')}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
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
