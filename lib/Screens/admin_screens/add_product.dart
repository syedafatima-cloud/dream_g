import 'package:flutter/material.dart';
import 'package:mobile_ap/services/product_services.dart';
import 'package:uuid/uuid.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _detailsController = TextEditingController();

  void _addProduct() {
    final id = const Uuid().v4();
    final product = Product(
      id: id,
      name: _nameController.text,
      imageUrl: _imageUrlController.text,
      details: _detailsController.text,
    );
    ProductService.addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully')),
    );

    _nameController.clear();
    _imageUrlController.clear();
    _detailsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            TextField(controller: _detailsController, decoration: const InputDecoration(labelText: 'Product Details')),
            const SizedBox(height: 20),
            ElevatedButton(
              
              onPressed: _addProduct,
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}