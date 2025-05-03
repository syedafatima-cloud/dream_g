import 'package:flutter/material.dart';

class TrackInventoryStreamPage extends StatefulWidget {
  const TrackInventoryStreamPage({super.key});

  @override
  _TrackInventoryStreamPageState createState() => _TrackInventoryStreamPageState();
}

class _TrackInventoryStreamPageState extends State<TrackInventoryStreamPage> {
  final List<String> _inventoryRecords = ['Added 10 Shoes', 'Sold 5 Bags', 'Restocked 20 Shirts'];

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _confirmDeleteRecord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Record'),
        content: Text('Delete "${_inventoryRecords[index]}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _inventoryRecords.removeAt(index);
              });
              Navigator.pop(context);
              _showSnackbar('Record deleted successfully!');
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
      appBar: AppBar(title: Text('Track Inventory Stream')),
      body: ListView.builder(
        itemCount: _inventoryRecords.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_inventoryRecords[index]),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDeleteRecord(index),
          ),
        ),
      ),
    );
  }
}