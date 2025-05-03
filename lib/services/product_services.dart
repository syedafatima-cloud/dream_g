class Product {
  final String id;
  String name;
  String imageUrl;
  String details;

  // Constructor for the Product class
  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.details,
  });
}

class ProductService {
  // List to store products
  static final List<Product> _products = [];

  // Method to add a product to the list
  static void addProduct(Product product) {
    _products.add(product);
  }

  // Method to delete a product by id
  static bool deleteProduct(String id) {
  int initialLength = _products.length;
  _products.removeWhere((product) => product.id == id);
  return _products.length < initialLength;
}

  // Method to view a product by id
  static Product? viewProduct(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;  // Return null if no product is found
    }
  }

  // Method to update a product's details
  static bool updateProduct(String id, String newName, String newImageUrl, String newDetails) {
    Product? product = viewProduct(id);
    if (product != null) {
      product.name = newName;
      product.imageUrl = newImageUrl;
      product.details = newDetails;
      return true; // Return true if update is successful
    }
    return false; // Return false if no product is found to update
  }

  // Method to get all products
  static List<Product> getAllProducts() {
    return List.unmodifiable(_products); // Returns an unmodifiable list of products
  }
}