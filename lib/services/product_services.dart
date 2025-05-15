import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  static final _db = FirebaseFirestore.instance.collection('products');

  // Add a product
  static Future<void> addProduct(Product product) async {
    await _db.add(product.toMap());
  }

  // Delete product by ID
  static Future<bool> deleteProduct(String id) async {
    try {
      await _db.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Get product by ID
  static Future<Product?> viewProduct(String id) async {
    try {
      final doc = await _db.doc(id).get();
      if (doc.exists) {
        return Product.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Update product by ID
  static Future<bool> updateProductById(String id, Map<String, dynamic> data) async {
    try {
      await _db.doc(id).update(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Get all products
  static Future<List<Product>> getAllProducts() async {
    final snapshot = await _db.get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }
}
