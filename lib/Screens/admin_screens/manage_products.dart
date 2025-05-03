import 'package:flutter/material.dart';

class ManageProductsPage extends StatelessWidget {
  const ManageProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/addProduct'),
              child: const Text('Add Product'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/deleteProduct'),
              child: const Text('Delete Product'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/viewProduct'),
              child: const Text('View Product'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/updateProduct'),
              child: const Text('Update Product'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/allProducts'),
              child: const Text('All Products'),
            ),
          ],
        ),
      ),
    );
  }
}