import 'package:flutter/material.dart';

class DeleteArchivedProductsPage extends StatefulWidget {
  const DeleteArchivedProductsPage({super.key});

  @override
  _DeleteArchivedProductsPageState createState() => _DeleteArchivedProductsPageState();
}

class _DeleteArchivedProductsPageState extends State<DeleteArchivedProductsPage> {
  final List<String> _archivedProducts = ['Old Laptop', 'Vintage Camera', 'Expired Milk'];

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _confirmDeleteArchived(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Archived Product'),
        content: Text('Delete "${_archivedProducts[index]}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _archivedProducts.removeAt(index);
              });
              Navigator.pop(context);
              _showSnackbar('Archived product deleted successfully!');
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delete Archived Products')),
      body: ListView.builder(
        itemCount: _archivedProducts.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_archivedProducts[index]),
          trailing: IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () => _confirmDeleteArchived(index),
          ),
        ),
      ),
    );
  }
}