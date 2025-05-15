class Product {
  final String id;
  String name;
  String imageUrl;
  String details;
  double price; // <-- Add price

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.details,
    required this.price,
  });

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      details: map['details'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'details': details,
      'price': price,
    };
  }
}
