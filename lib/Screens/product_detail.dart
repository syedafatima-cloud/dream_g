import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;
  bool _isInWishlist = false;
  int _quantity = 1;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Check if product is in wishlist when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWishlistStatus();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkWishlistStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final productId = args['id'];
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("wishlist")
          .doc(productId)
          .get();
      
      if (mounted) {
        setState(() {
          _isInWishlist = docSnapshot.exists;
        });
        
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String name = args['name'];
    final double price = args['price'];
    final List<String> images = args['images'];
    final double rating = args['rating'];
    final String description = args['description'];
    final String productId = args['id'];
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: MediaQuery.of(context).size.height * 0.4,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: _isInWishlist ? Colors.red : Colors.black,
                    ),
                  ),
                  onPressed: () => _toggleWishlist(productId),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: Colors.black),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Share functionality will be implemented soon"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Product Image Carousel
                    CarouselSlider(
                      options: CarouselOptions(
                        height: MediaQuery.of(context).size.height * 0.4,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: images.length > 1,
                        autoPlay: false,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                      items: images.map((imageUrl) {
                        return CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(color: Colors.grey[300]),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      }).toList(),
                    ),
                    
                    // Dots indicator
                    if (images.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: images.asMap().entries.map((entry) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == entry.key
                                    ? Colors.black
                                    : Colors.white.withOpacity(0.7),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Product Details
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\$${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Quantity Selector
                    Row(
                      children: [
                        const Text(
                          "Quantity:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (_quantity > 1) {
                                    setState(() {
                                      _quantity--;
                                    });
                                  }
                                },
                                iconSize: 20,
                              ),
                              Text(
                                _quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _quantity++;
                                  });
                                },
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // TabBar for details, reviews, and similar products
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.black,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: "Details"),
                        Tab(text: "Reviews"),
                        Tab(text: "Similar"),
                      ],
                    ),
                    
                    // Tab content
                    SizedBox(
                      height: 300, // Fixed height for tab content
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Details Tab
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Product Description",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Features",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildFeatureItem(Icons.check_circle, "Premium Quality"),
                                _buildFeatureItem(Icons.check_circle, "100% Authentic"),
                                _buildFeatureItem(Icons.check_circle, "Free Returns"),
                              ],
                            ),
                          ),
                          
                          // Reviews Tab
                          _buildReviewsTab(productId),
                          
                          // Similar Products Tab
                          _buildSimilarProductsTab(args),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addToCart(productId, _quantity),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text("Add to Cart"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.black),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _buyNow(productId, _quantity),
                icon: const Icon(Icons.flash_on),
                label: const Text("Buy Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewsTab(String productId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .collection("reviews")
          .orderBy("timestamp", descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "No reviews yet",
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddReviewDialog(productId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Write a Review"),
              ),
            ],
          );
        }
        
        // Show reviews and add review button
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var review = snapshot.data!.docs[index];
                  return _buildReviewItem(
                    review["userName"] ?? "Anonymous",
                    review["rating"] ?? 5.0,
                    review["comment"] ?? "",
                    review["timestamp"] != null
                        ? (review["timestamp"] as Timestamp).toDate()
                        : DateTime.now(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddReviewDialog(productId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("Write a Review"),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildReviewItem(String userName, double rating, String comment, DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < rating.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment),
          const SizedBox(height: 4),
          Text(
            "${date.day}/${date.month}/${date.year}",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimilarProductsTab(Map<String, dynamic> args) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .where("category", isEqualTo: args['category'] ?? "")
          .where(FieldPath.documentId, isNotEqualTo: args['id'])
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No similar products found",
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
          );
        }
        
        // Show similar products
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = snapshot.data!.docs[index];
            return _buildSimilarProductCard(
              product.id,
              product["name"] ?? "",
              double.tryParse(product["price"].toString()) ?? 0.0,
              List<String>.from(product["image"] ?? []),
              product["rating"] ?? 4.5,
              product["description"] ?? "",
              product["category"] ?? "",
            );
          },
        );
      },
    );
  }
  
  Widget _buildSimilarProductCard(
    String id,
    String name,
    double price,
    List<String> images,
    double rating,
    String description,
    String category,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductDetailScreen(),
            settings: RouteSettings(
              arguments: {
                'id': id,
                'name': name,
                'price': price,
                'images': images,
                'rating': rating,
                'description': description,
                'category': category,
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
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
            
            // Product Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${price.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddReviewDialog(String productId) {
    double rating = 5;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Write a Review"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Rating"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Share your experience about this product...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  _submitReview(productId, rating, commentController.text);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _submitReview(String productId, double rating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .collection("reviews")
          .add({
        "userId": user.uid,
        "userName": user.displayName ?? "User",
        "rating": rating,
        "comment": comment,
        "timestamp": FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review submitted successfully"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in to leave a review"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _toggleWishlist(String productId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_isInWishlist) {
        // Remove from wishlist
        FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("wishlist")
            .doc(productId)
            .delete();
        
        setState(() {
          _isInWishlist = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Removed from wishlist"),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Add to wishlist
        FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("wishlist")
            .doc(productId)
            .set({
          'addedAt': FieldValue.serverTimestamp()
        });
        
        setState(() {
          _isInWishlist = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to wishlist"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in to add to wishlist"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _addToCart(String productId, int quantity) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      print('Trying to add productId: $productId with quantity: $quantity');
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .set({
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added $quantity item(s) to cart"),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: "VIEW CART",
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ),
      );
    } catch (error) {
      print("Error adding to cart: $error");  // <-- this will show error now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error adding to cart"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please sign in to add to cart"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

  void _buyNow(String productId, int quantity) {
    _addToCart(productId, quantity);
    Navigator.pushNamed(context, '/checkout');
  }
}