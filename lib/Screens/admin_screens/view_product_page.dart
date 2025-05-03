import 'package:flutter/material.dart';
import 'package:mobile_ap/services/product_services.dart';

class ViewProductPage extends StatefulWidget {
  const ViewProductPage({super.key});

  @override
  State<ViewProductPage> createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  final _idController = TextEditingController();
  Product? _product;

  void _viewProduct() {
    final id = _idController.text;
    final product = ProductService.viewProduct(id);

    setState(() {
      _product = product;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Product')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Enter Product ID')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _viewProduct,
              child: const Text('View Product'),
            ),
            const SizedBox(height: 20),
            if (_product != null) ...[
              Text('Name: ${_product!.name}', style: const TextStyle(fontSize: 18)),
              Text('Image URL: ${_product!.imageUrl}', style: const TextStyle(fontSize: 18)),
              Text('Details: ${_product!.details}', style: const TextStyle(fontSize: 18)),
            ]
          ],
        ),
      ),
    );
  }
}