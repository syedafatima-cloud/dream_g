import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../pastel_theme.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelTheme.background,
      appBar: AppBar(
        title: const Text(
          "My Wishlist", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 20,
            color: PastelTheme.accent,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: PastelTheme.primary,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: PastelTheme.accent),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
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
          return Center(
            child: CircularProgressIndicator(
              color: PastelTheme.primary,
              strokeWidth: 3,
            ),
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
              return Center(
                child: CircularProgressIndicator(
                  color: PastelTheme.primary,
                  strokeWidth: 3,
                ),
              );
            }
            
            if (!productsSnapshot.hasData || productsSnapshot.data!.isEmpty) {
              return _buildEmptyWishlistView();
            }
            
            final products = productsSnapshot.data!;
            
            return RefreshIndicator(
              color: PastelTheme.primary,
              backgroundColor: PastelTheme.cardColor,
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
                  
                  // Directly fetch the price from Firebase
                  final double price = _getProductPrice(productData);
                  
                  final List<String> images = productData["image"] is String
                    ? [productData["image"]]
                    : List<String>.from(productData["image"] ?? []);
                  final double rating = productData["rating"] != null ? 
                    double.parse(productData["rating"].toString()) : 4.5;
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

  // Helper method to get product price from Firebase data
  double _getProductPrice(Map<String, dynamic> productData) {
    // Price is already in PKR, no conversion needed
    double pricePkr = 0.0;
    
    // Check if price exists directly in the product data
    if (productData.containsKey("price")) {
      pricePkr = double.tryParse(productData["price"].toString()) ?? 0.0;
    }
    // Check if there's a prices map with current price
    else if (productData.containsKey("prices") && productData["prices"] is Map) {
      final pricesMap = productData["prices"] as Map;
      if (pricesMap.containsKey("current")) {
        pricePkr = double.tryParse(pricesMap["current"].toString()) ?? 0.0;
      }
    }
    
    return pricePkr;
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
    return Hero(
      tag: 'wishlist_$productId',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: PastelTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: PastelTheme.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
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
            borderRadius: BorderRadius.circular(16),
            splashColor: PastelTheme.secondary.withOpacity(0.2),
            highlightColor: PastelTheme.secondary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image with decorated container
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PastelTheme.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: images[0],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: PastelTheme.primary.withOpacity(0.5),
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: PastelTheme.secondary.withOpacity(0.2),
                                  child: const Icon(
                                    Icons.image_not_supported_rounded,
                                    color: PastelTheme.textSecondary,
                                  ),
                                ),
                              )
                            : Container(
                                color: PastelTheme.secondary.withOpacity(0.2),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    color: PastelTheme.textSecondary,
                                  ),
                                ),
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
                            color: PastelTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFFFD700), // Golden color for stars
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: PastelTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          // Changed from $ to PKR
                          "PKR ${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: PastelTheme.accent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _addToCart(context, productId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PastelTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1000),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: const Text(
                                  "Add to Cart",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
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
        ),
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context, String productId) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: PastelTheme.error.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
        color: PastelTheme.error.withOpacity(0.05),
      ),
      child: IconButton(
        onPressed: () => _showRemoveConfirmation(context, productId),
        icon: const Icon(
          Icons.favorite,
          color: PastelTheme.error,
        ),
        tooltip: "Remove from wishlist",
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
  
  void _showRemoveConfirmation(BuildContext context, String productId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: PastelTheme.cardColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Remove from Wishlist?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: PastelTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Are you sure you want to remove this item from your wishlist?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PastelTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PastelTheme.textPrimary,
                      side: const BorderSide(color: PastelTheme.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _removeFromWishlist(context, productId);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PastelTheme.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Remove"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWishlistView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: PastelTheme.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 60,
                color: PastelTheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Your wishlist is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: PastelTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Save items you love to your wishlist and come back to them anytime",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: PastelTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PastelTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Discover Products",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: PastelTheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_circle,
                size: 64,
                color: PastelTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Login to view your wishlist",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: PastelTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Sign in to keep track of your favorite items and create a personalized shopping experience",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: PastelTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PastelTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PastelTheme.primary,
                    side: const BorderSide(color: PastelTheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
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
      // Animate a heart to cart effect here if needed
      _animationController.forward(from: 0.0);
      
      FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .set({
        'quantity': FieldValue.increment(1),
        'addedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Show a styled snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Added to cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/cart'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "VIEW",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: PastelTheme.success.withOpacity(0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Please login to add to cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: PastelTheme.error.withOpacity(0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: "LOGIN",
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text(
                "Removed from wishlist",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: PastelTheme.textPrimary.withOpacity(0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: "UNDO",
            textColor: Colors.white,
            onPressed: () {
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .collection("wishlist")
                  .doc(productId)
                  .set({
                'addedAt': FieldValue.serverTimestamp()
              });
            },
          ),
        ),
      );
    }
  }
}