import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackInventoryStreamPage extends StatefulWidget {
  const TrackInventoryStreamPage({super.key});

  @override
  _TrackInventoryStreamPageState createState() =>
      _TrackInventoryStreamPageState();
}

class _TrackInventoryStreamPageState extends State<TrackInventoryStreamPage> {
  final _inventoryCollection = FirebaseFirestore.instance.collection('inventory');

  // Show a snackbar with a message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Show confirmation dialog for deleting a record
  void _confirmDeleteRecord(String recordId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _inventoryCollection.doc(recordId).delete();
                Navigator.pop(context);
                _showSnackbar('Record deleted successfully!');
              } catch (e) {
                Navigator.pop(context);
                _showSnackbar('Failed to delete record');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Add a new inventory record to Firestore
  Future<void> _addInventoryRecord(String message) async {
    try {
      await _inventoryCollection.add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showSnackbar('Record added successfully!');
    } catch (e) {
      _showSnackbar('Failed to add record');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Inventory Stream')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _inventoryCollection
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No inventory records available'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final record = docs[index];
              final recordId = record.id;
              final message = record['message'] ?? 'No message';

              return ListTile(
                title: Text(message),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteRecord(recordId),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // For now, just adding a sample inventory record when the button is pressed
          await _addInventoryRecord('Added 10 Shoes');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
