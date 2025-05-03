import 'package:flutter/material.dart';
import 'package:mobile_ap/services/product_services.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    // Assuming ProductService.getAllProducts() returns a list of products
    final productList = ProductService.getAllProducts();  
    setState(() {
      products = productList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products available'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported),
                    title: Text(product.name),
                    subtitle: Text('ID: ${product.id}\nDetails: ${product.details}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}