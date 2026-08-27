// logic to save 3 fields (with hour slots), 5 users, 2 open matches
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> seedTerrains() async {
  final db = FirebaseFirestore.instance;

  final hours = ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'];

  List<Map<String, List<String>>> generateSlots() {
    final today = DateTime.now();
    return List.generate(8, (i) {
      final day = today.add(Duration(days: i));
      final label = DateFormat('E d MMM').format(day); // "Thu 27 Aug"
      return {label: List.from(hours)};
    });
  }

  final terrains = [
    {
      'picture': 'https://i.ibb.co/Z6MpnWNH/padel.jpg',
      'location': 'Garrincha Slachthuislaan',
      'slots': generateSlots(),
    },
    {
      'picture': 'hhttps://i.ibb.co/21gRhvg4/padel1.jpg',
      'location': 'Padel schoten',
      'slots': generateSlots(),
    },
    {
      'picture': 'https://i.ibb.co/gZf9h37w/padel2.jpg',
      'location': 'Padel antwerpen zuid',
      'slots': generateSlots(),
    },
  ];

  for (final terrain in terrains) {
    await db.collection('terrains').add(terrain);
  }
}
