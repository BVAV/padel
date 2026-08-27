import 'package:cloud_firestore/cloud_firestore.dart';

class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> bookSlot(String terrainId, String date, String hour) async {
    try {
      final docRef = _db.collection('terrains').doc(terrainId);
      final doc = await docRef.get();

      if (!doc.exists) return 'Terrain not found';

      final List<dynamic> slots = doc.data()?['slots'] ?? [];

      final updatedSlots = slots.map((entry) {
        final map = entry as Map<String, dynamic>;
        if (map.containsKey(date)) {
          final hours = List<String>.from(map[date]);
          hours.remove(hour);
          return {date: hours};
        }
        return map;
      }).toList();

      await docRef.update({'slots': updatedSlots});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
