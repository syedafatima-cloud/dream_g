import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Model class for cart items
class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  double _totalAmount = 0;

  // Sample recommendations - you can replace with real recommendations from Firebase
  final List<Map<String, dynamic>> recommendations = [
    {
      "id": "rec1",
      "name": "Birthday Card",
      "price": 4.99,
      "image": ["https://images.unsplash.com/photo-1530103862676-de8c9debad1d"],
      "description": "Beautiful birthday card for your loved ones",
      "category": "Cards",
      "rating": 4.5,
    },
    {
      "id": "rec2",
      "name": "Gift Box",
      "price": 15.99,
      "image": ["https://images.unsplash.com/photo-1549465220-1a8b9238cd48"],
      "description": "Elegant gift box for special occasions",
      "category": "Gifts",
      "rating": 4.8,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  // Method to load cart items from Firebase
  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Get cart item references
      final cartSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .get();

      final List<CartItem> loadedItems = [];
      double total = 0;

      // Process each cart item
      for (var doc in cartSnapshot.docs) {
        // Get product details from the products collection
        final productId = doc.id;
        final productSnapshot = await FirebaseFirestore.instance
            .collection("products")
            .doc(productId)
            .get();

        if (productSnapshot.exists) {
          final productData = productSnapshot.data()!;
          final cartItem = CartItem(
            id: productId,
            name: productData['name'] ?? 'Unknown Product',
            price: double.tryParse(productData['price'].toString()) ?? 0.0,
            imageUrl: (productData['image'] is List<dynamic> && (productData['image'] as List).isNotEmpty)
                ? productData['image'][0]
                : (productData['image'] is String ? productData['image'] : 'https://via.placeholder.com/150'),
            quantity: doc.data()['quantity'] ?? 1,
          );


          loadedItems.add(cartItem);
          total += cartItem.totalPrice;
        }
      }

      setState(() {
        _cartItems = loadedItems;
        _totalAmount = total;
        _isLoading = false;
      });
    } catch (error) {
      print("Error loading cart items: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading cart items. Please try again.")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update quantity in Firebase and local state
  Future<void> _updateCartItemQuantity(String id, int newQuantity) async {
    if (newQuantity < 1) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update in Firebase
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(id)
          .update({'quantity': newQuantity});

      // Update in local state
      setState(() {
        final itemIndex = _cartItems.indexWhere((item) => item.id == id);
        if (itemIndex != -1) {
          _cartItems[itemIndex].quantity = newQuantity;
          _recalculateTotal();
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update quantity. Please try again.")),
      );
    }
  }

  // Remove item from cart in Firebase and local state
  Future<void> _removeCartItem(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Remove from Firebase
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(id)
          .delete();

      // Remove from local state
      setState(() {
        _cartItems.removeWhere((item) => item.id == id);
        _recalculateTotal();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item removed from cart")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to remove item. Please try again.")),
      );
    }
  }

  // Helper method to recalculate total amount
  void _recalculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += item.totalPrice;
    }
    _totalAmount = total;
  }

  // Add recommended product to cart
  void _addRecommendedProductToCart(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to add to cart")),
      );
      return;
    }

    try {
      // Add to Firebase cart
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(product['id'])
          .set({
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Refresh cart
      await _loadCartItems();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product['name']} added to cart")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add item to cart. Please try again.")),
      );
    }
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: {
        'id': product['id'],
        'name': product['name'],
        'price': product['price'],
        'images': product['image'],
        'rating': product['rating'],
        'description': product['description'],
        'category': product['category'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        elevation: 0,
        backgroundColor: Colors.black, // Match your app's theme
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Your cart is empty",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text("Add items to get started"),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // Image with error handling
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CachedNetworkImage(
                                        imageUrl: item.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Item details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "\$${item.price.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "Subtotal: \$${item.totalPrice.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle),
                                            color: Colors.red,
                                            onPressed: () => _updateCartItemQuantity(item.id, item.quantity - 1),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: Colors.grey[200],
                                            ),
                                            child: Text(
                                              item.quantity.toString(),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle),
                                            color: Colors.green,
                                            onPressed: () => _updateCartItemQuantity(item.id, item.quantity + 1),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _removeCartItem(item.id),
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                        label: const Text("Remove"),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Recommendations section
                    if (_cartItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                "You may also like",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: recommendations.length,
                                itemBuilder: (context, index) {
                                  final recommendation = recommendations[index];
                                  return GestureDetector(
                                    onTap: () => _navigateToProductDetail(recommendation),
                                    child: Card(
                                      margin: const EdgeInsets.only(right: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SizedBox(
                                        width: 140,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Recommendation image
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                              child: SizedBox(
                                                height: 100,
                                                width: double.infinity,
                                                child: CachedNetworkImage(
                                                  imageUrl: recommendation['image'][0],
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child: CircularProgressIndicator(),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    recommendation['name'],
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "\$${recommendation['price'].toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
      // Bottom navigation bar with checkout button
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "\$${_totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 50,
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to checkout
                          Navigator.pushNamed(context, '/checkout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "CHECKOUT",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}