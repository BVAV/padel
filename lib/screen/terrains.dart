import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padel/screen/newgame.dart';
import 'package:padel/screen/terraindetail.dart';
import 'package:padel/service/seed.dart';

void _showOptionsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose an option'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            // option 1 logic
            await seedTerrains();
          },
          child: const Text('Seeding'),
        ),
        TextButton(
          onPressed: () {
            // option 1 logic
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const CreateGameScreen(),
              ),
            );
          },
          child: const Text('New game'),
        ),
      ],
    ),
  );
}

class TerrainsScreen extends StatelessWidget {
  const TerrainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terrains')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('terrains').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No terrains found'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return InkWell(
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: ((context) =>
                          TerrainDetailScreen(terrainId: docs[index].id)),
                    ),
                  ),
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        data['picture'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          data['location'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showOptionsModal(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
