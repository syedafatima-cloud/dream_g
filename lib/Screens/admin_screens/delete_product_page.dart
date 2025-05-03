import 'package:flutter/material.dart';
import 'package:mobile_ap/services/product_services.dart';

class DeleteProductPage extends StatefulWidget {
  const DeleteProductPage({super.key});

  @override
  State<DeleteProductPage> createState() => _DeleteProductPageState();
}

class _DeleteProductPageState extends State<DeleteProductPage> {
  final _idController = TextEditingController();

  void _deleteProduct() {
    final id = _idController.text;
    bool success = ProductService.deleteProduct(id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Product deleted' : 'Product not found')),
    );

    _idController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Product')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Enter Product ID')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _deleteProduct,
              child: const Text('Delete Product'),
            ),
          ],
        ),
      ),
    );
  }
}