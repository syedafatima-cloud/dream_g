import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BatchUpdatePage extends StatefulWidget {
  const BatchUpdatePage({super.key});

  @override
  _BatchUpdatePageState createState() => _BatchUpdatePageState();
}

class _BatchUpdatePageState extends State<BatchUpdatePage> {
  // Show dialog to add a new product
  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter product name' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter price';
                  }
                  final parsedPrice = double.tryParse(value);
                  if (parsedPrice == null || parsedPrice <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await FirebaseFirestore.instance.collection('products').add({
                    'name': nameController.text,
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  // Close the dialog after adding the product
                  Navigator.pop(context);
                  // Clear text fields
                  nameController.clear();
                  priceController.clear();
                } catch (e) {
                  // Show error message if there's an issue adding the product
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add product')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Update Products')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No products available'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final product = docs[index].data() as Map<String, dynamic>;
              final name = product['name'] ?? 'Unnamed';
              final price = product.containsKey('price') ? product['price'] : 0;

              return ListTile(
                title: Text(name),
                subtitle: Text('Price: \$${price.toString()}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
