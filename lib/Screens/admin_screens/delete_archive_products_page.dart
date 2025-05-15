import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteArchivedProductsPage extends StatefulWidget {
  const DeleteArchivedProductsPage({super.key});

  @override
  _DeleteArchivedProductsPageState createState() => _DeleteArchivedProductsPageState();
}

class _DeleteArchivedProductsPageState extends State<DeleteArchivedProductsPage> {
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _confirmDeleteArchived(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Archived Product'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
              Navigator.pop(context);
              _showSnackbar('Archived product deleted successfully!');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Archived Products')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isArchived', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No archived products'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final name = doc['name'] ?? 'Unnamed';

              return ListTile(
                title: Text(name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => _confirmDeleteArchived(doc.id, name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
