import 'package:flutter/material.dart';

class BatchUpdatePage extends StatefulWidget {
  const BatchUpdatePage({super.key});

  @override
  _BatchUpdatePageState createState() => _BatchUpdatePageState();
}

class _BatchUpdatePageState extends State<BatchUpdatePage> {
  final List<Map<String, dynamic>> _products = [
    {'name': 'Product 1', 'price': 100},
    {'name': 'Product 2', 'price': 200},
  ];

  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Product'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter price' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _products.add({
                    'name': nameController.text,
                    'price': int.tryParse(priceController.text) ?? 0,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Batch Update Products')),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_products[index]['name']),
          subtitle: Text('Price: \$${_products[index]['price']}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}