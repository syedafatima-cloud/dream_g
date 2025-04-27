import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 243, 177, 255),
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildNotLoggedInView();
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("wishlist")
          .orderBy("addedAt", descending: true)
          .snapshots(),
      builder: (context, wishlistSnapshot) {
        if (wishlistSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }
        
        if (!wishlistSnapshot.hasData || wishlistSnapshot.data!.docs.isEmpty) {
          return _buildEmptyWishlistView();
        }
        
        final wishlistItems = wishlistSnapshot.data!.docs;
        
        // Create a list to hold all the futures for product data
        List<Future<DocumentSnapshot>> productFutures = [];
        
        // For each wishlist item, get the product data
        for (var item in wishlistItems) {
          productFutures.add(
            FirebaseFirestore.instance
                .collection("products")
                .doc(item.id)
                .get()
          );
        }
        
        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(productFutures),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }
            
            if (!productsSnapshot.hasData || productsSnapshot.data!.isEmpty) {
              return _buildEmptyWishlistView();
            }
            
            final products = productsSnapshot.data!;
            
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoading = true;
                });
                await Future.delayed(const Duration(milliseconds: 800));
                setState(() {
                  _isLoading = false;
                });
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  
                  if (!product.exists) {
                    // This product no longer exists in the database
                    return const SizedBox.shrink();
                  }
                  
                  final productData = product.data() as Map<String, dynamic>;
                  
                  final String name = productData["name"] ?? "Unknown Product";
                  final double price = double.tryParse(productData["price"].toString()) ?? 0.0;
                  final List<String> images = List<String>.from(productData["image"] ?? []);
                  final double rating = productData["rating"] ?? 4.5;
                  final String description = productData["description"] ?? "No description available";
                  
                  return _buildWishlistItem(
                    context,
                    product.id,
                    name,
                    price,
                    images,
                    rating,
                    description
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWishlistItem(
    BuildContext context,
    String productId,
    String name,
    double price,
    List<String> images,
    double rating,
    String description
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToProductDetail(
          context, 
          productId, 
          name, 
          price, 
          images, 
          rating, 
          description
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: images[0],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(color: Colors.grey[300]),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported, color: Colors.grey),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\$${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _addToCart(context, productId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text("Add to Cart"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRemoveButton(context, productId),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context, String productId) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: () => _removeFromWishlist(context, productId),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        tooltip: "Remove from wishlist",
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEmptyWishlistView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Your wishlist is empty",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Items you add to your wishlist will appear here",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Continue Shopping"),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "You're not logged in",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please login to view your wishlist",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  // Helper methods - All methods now accept a BuildContext parameter
  void _navigateToProductDetail(
    BuildContext context,
    String productId,
    String name,
    double price,
    List<String> images,
    double rating,
    String description
  ) {
    Navigator.pushNamed(
      context,
      '/product',
      arguments: {
        'id': productId,
        'name': name,
        'price': price,
        'images': images,
        'rating': rating,
        'description': description
      }
    );
  }

  void _addToCart(BuildContext context, String productId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .set({
        'quantity': FieldValue.increment(1),
        'addedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to cart"),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to add to cart"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeFromWishlist(BuildContext context, String productId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("wishlist")
          .doc(productId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from wishlist"),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}