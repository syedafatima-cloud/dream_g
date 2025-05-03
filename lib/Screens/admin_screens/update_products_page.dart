import 'package:flutter/material.dart';
import 'package:mobile_ap/services/product_services.dart';

class UpdateProductPage extends StatefulWidget {
  const UpdateProductPage({super.key});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _detailsController = TextEditingController();

  void _updateProduct() {
    bool success = ProductService.updateProduct(
      _idController.text,
      _nameController.text,
      _imageUrlController.text,
      _detailsController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Product updated' : 'Product not found')),
    );

    _idController.clear();
    _nameController.clear();
    _imageUrlController.clear();
    _detailsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Product')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Enter Product ID')),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'New Product Name')),
              TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'New Image URL')),
              TextField(controller: _detailsController, decoration: const InputDecoration(labelText: 'New Product Details')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProduct,
                child: const Text('Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}