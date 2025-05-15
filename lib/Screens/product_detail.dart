import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_ap/screens/checkout_screen.dart';
import 'package:mobile_ap/screens/cart_screen.dart';

// Pastel theme colors for consistent styling
class PastelTheme {
  static const Color primary = Color.fromARGB(255, 197, 157, 216); // Soft purple
  static const Color secondary = Color(0xFFFFC8DD); // Soft pink
  static const Color accent = Color.fromARGB(255, 75, 77, 68); // Dark accent
  static const Color background = Color(0xFFF9F5F6); // Light background
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color cardShadow = Color(0x0D000000); // Light shadow
  static const Color textPrimary = Color(0xFF445566); // Darker blue-gray
  static const Color textSecondary = Color(0xFF7A8999); // Medium blue-gray
  static const Color success = Color(0xFFABD8C6); // Mint green
  static const Color error = Color(0xFFFFADAD); // Soft red
  static const Color divider = Color(0xFFEEEEEE); // Light divider
}

class ProductDetailScreen extends StatefulWidget {
  final String? productId;

  const ProductDetailScreen({
    super.key,
    this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;
  bool _isInWishlist = false;
  int _quantity = 1;
  bool _isLoading = true;
  Map<String, dynamic> _productData = {};
  List<String> _imageUrls = [];
  String? _productId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load product data and check wishlist status when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductData();
      _checkWishlistStatus();
    });
  }
  
  // Load product data from Firestore
  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get productId either from widget or from route arguments
      String? productId;
      
      if (widget.productId != null) {
        productId = widget.productId;
      } else if (ModalRoute.of(context)?.settings.arguments != null) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        productId = args['id'];
      }
      
      if (productId == null) {
        throw Exception("Product ID not provided");
      }
      
      _productId = productId;
      
      final productSnapshot = await FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .get();

      if (productSnapshot.exists) {
        final data = productSnapshot.data() as Map<String, dynamic>;
        
        // Process images
        List<String> images = [];
        if (data['image'] is List) {
          images = List<String>.from(data['image'] as List);
        } else if (data['image'] is String) {
          images = [data['image'] as String];
        } else if (data['images'] is List) {
          images = List<String>.from(data['images'] as List);
        }

        setState(() {
          _productData = data;
          _imageUrls = images;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Product not found"),
            backgroundColor: PastelTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      print("Error loading product: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading product details. Please try again."),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkWishlistStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _productId != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("wishlist")
          .doc(_productId)
          .get();
      
      if (mounted) {
        setState(() {
          _isInWishlist = docSnapshot.exists;
        });
      }
    }
  }
  
  // Toggle wishlist status
  Future<void> _toggleWishlist() async {
    if (_productId == null) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please login to use wishlist"),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isInWishlist = !_isInWishlist;
    });
    
    try {
      final wishlistRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("wishlist")
          .doc(_productId);
      
      if (_isInWishlist) {
        // Add to wishlist
        await wishlistRef.set({
          'productId': _productId,
          'name': _productData['name'],
          'price': _productData['price'],
          'image': _imageUrls.isNotEmpty ? _imageUrls[0] : '',
          'addedAt': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added to wishlist"),
            backgroundColor: PastelTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Remove from wishlist
        await wishlistRef.delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed from wishlist"),
            backgroundColor: PastelTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isInWishlist = !_isInWishlist; // Revert UI state
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update wishlist"),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _addToCart(String productId, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please login to add items to cart"),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
          ),
        ),
      );
      
      // Check if product already exists in cart
      final cartItemRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId);
      
      final cartItemDoc = await cartItemRef.get();
      
      if (cartItemDoc.exists) {
        // Update quantity if product already in cart
        final currentQuantity = cartItemDoc.data()?['quantity'] as int? ?? 0;
        await cartItemRef.update({
          'quantity': currentQuantity + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new product to cart
        await cartItemRef.set({
          'productId': productId,
          'name': _productData['name'],
          'price': _productData['price'],
          'image': _imageUrls.isNotEmpty ? _imageUrls[0] : '',
          'quantity': quantity,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message with cart action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added to cart"),
          backgroundColor: PastelTheme.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "VIEW CART",
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (error) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add to cart: $error"),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _buyNow(String productId, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please login to continue"),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
          ),
        ),
      );
      
      // Create a temporary checkout session
      final checkoutSessionRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("checkout_sessions")
          .doc();
      
      final totalPrice = double.tryParse(_productData['price'].toString()) ?? 0.0;
      
      // Create the cart item for checkout
      final cartItem = {
        'productId': productId,
        'name': _productData['name'],
        'price': totalPrice,
        'image': _imageUrls.isNotEmpty ? _imageUrls[0] : '',
        'quantity': quantity,
      };
      
      await checkoutSessionRef.set({
        'items': [cartItem],
        'totalAmount': totalPrice * quantity,
        'createdAt': FieldValue.serverTimestamp(),
        'sessionId': checkoutSessionRef.id,
      });
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Navigate to checkout screen with the cart item
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            totalAmount: totalPrice * quantity, 
            // Pass the cart item here instead of empty list
            cartItems: [cartItem], 
            currency: 'PKR', // Use proper currency code
          ),
        ),
      );
    } catch (error) {
      // Close loading dialog if still showing
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to process: $error"),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Get rating from product data if available
    final double rating = _productData.containsKey('rating') 
        ? double.tryParse(_productData['rating'].toString()) ?? 0.0 
        : 0.0;
    
    return Scaffold(
      backgroundColor: PastelTheme.background,
      body: _isLoading 
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
              ),
            )
          : Stack(
              children: [
                CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    // App bar with product image
                    SliverAppBar(
                      expandedHeight: 350,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            // Main product image carousel
                            PageView.builder(
                              itemCount: _imageUrls.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  imageUrl: _imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: PastelTheme.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                      size: 60,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Dots indicator
                            if (_imageUrls.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _imageUrls.asMap().entries.map((entry) {
                                    return Container(
                                      width: 8.0,
                                      height: 8.0,
                                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentImageIndex == entry.key
                                            ? PastelTheme.primary
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category
                            Text(
                              _productData['category'] ?? 'General',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: PastelTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Product name
                            Text(
                              _productData['name'] ?? 'Product Name',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: PastelTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Price and rating row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Price
                                Text(
                                  'PKR ${double.tryParse(_productData['price'].toString())?.toStringAsFixed(2) ?? "0.00"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: PastelTheme.primary,
                                  ),
                                ),
                                // Rating
                                if (_productData.containsKey('rating'))
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: PastelTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Description header
                            Text(
                              'Description',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: PastelTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Description text
                            Text(
                              _productData['description'] ?? 'No description available.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.6,
                                color: PastelTheme.textSecondary,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Quantity selector
                            Row(
                              children: [
                                Text(
                                  'Quantity:',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: PastelTheme.divider),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      // Decrease button
                                      InkWell(
                                        onTap: () {
                                          if (_quantity > 1) {
                                            setState(() {
                                              _quantity--;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(color: PastelTheme.divider),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: PastelTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      // Quantity display
                                      Container(
                                        width: 40,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$_quantity',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: PastelTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      // Increase button
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _quantity++;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(color: PastelTheme.divider),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color: PastelTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Add to cart button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: () => _productId != null ? _addToCart(_productId!, _quantity) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PastelTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(Icons.shopping_cart_outlined),
                                label: Text(
                                  "ADD TO CART",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Buy now button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () => _productId != null ? _buyNow(_productId!, _quantity) : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: PastelTheme.primary,
                                  side: BorderSide(color: PastelTheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "BUY NOW",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Tabs for reviews and similar products
                            TabBar(
                              controller: _tabController,
                              labelColor: PastelTheme.primary,
                              unselectedLabelColor: PastelTheme.textSecondary,
                              indicatorColor: PastelTheme.primary,
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
                                  // Details tab
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFeatureItem(Icons.local_shipping_outlined, "Free shipping on orders over PKR 2000"),
                                        _buildFeatureItem(Icons.access_time_outlined, "Delivery within 3-5 business days"),
                                        _buildFeatureItem(Icons.verified_outlined, "100% Authentic products"),
                                        _buildFeatureItem(Icons.assignment_return_outlined, "Easy returns within 7 days"),
                                        _buildFeatureItem(Icons.support_agent_outlined, "24/7 Customer support"),
                                      ],
                                    ),
                                  ),
                                  
                                  // Reviews Tab
                                  _productId != null ? _buildReviewsTab(_productId!) : Center(child: Text("Product ID not available")),
                                  
                                  // Similar Products Tab
                                  _buildSimilarProductsTab({
                                    'id': _productId,
                                    'category': _productData['category'],
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Heart icon in top right corner - moved inside the Stack
                Positioned(
                  top: 50, // Adjusted to be below the status bar
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: _isInWishlist ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleWishlist, // Use the unified toggle method
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PastelTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: PastelTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: PastelTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildReviewItem(String userName, double rating, String comment, DateTime date) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PastelTheme.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // User name and rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: PastelTheme.primary.withOpacity(0.2),
                  radius: 16,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "A",
                    style: TextStyle(
                      color: PastelTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PastelTheme.textPrimary,
                  ),
                ),
              ],
            ),
            // Date
            Text(
              "${date.day}/${date.month}/${date.year}",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: PastelTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Rating stars
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            );
          }),
        ),
        const SizedBox(height: 8),
        // Comment
        Text(
          comment,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: PastelTheme.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
 Widget _buildReviewsTab(String productId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("reviews")
        .where("productId", isEqualTo: productId)
        .orderBy("date", descending: true)
        .limit(5)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator(color: PastelTheme.primary));
      }

      // Check for any errors in the snapshot
      if (snapshot.hasError) {
        print("Error loading reviews: ${snapshot.error}");
        return Center(
          child: Text(
            'Error loading reviews. Please try again later.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: PastelTheme.textSecondary,
            ),
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: PastelTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No reviews yet",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: PastelTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddReviewDialog(productId),
              style: ElevatedButton.styleFrom(
                backgroundColor: PastelTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                "Write a Review",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                try {
                  var reviewDoc = snapshot.data!.docs[index];
                  Map<String, dynamic> reviewData = reviewDoc.data() as Map<String, dynamic>;
                  
                  // Use more robust field access with fallbacks like in the admin side
                  String userName = reviewData["customerName"] ?? 
                                   reviewData["userName"] ?? 
                                   "Anonymous";
                                   
                  // Robust rating extraction
                  double rating = 0.0;
                  if (reviewData["rating"] != null) {
                    rating = (reviewData["rating"] is num) 
                            ? (reviewData["rating"] as num).toDouble() 
                            : 0.0;
                  }
                  
                  // Get review text from either field name
                  String comment = reviewData["reviewText"] ?? 
                                  reviewData["comment"] ?? 
                                  "";
                  
                  // Handle different date field names and formats
                  DateTime timestamp;
                  if (reviewData["date"] is Timestamp) {
                    timestamp = (reviewData["date"] as Timestamp).toDate();
                  } else if (reviewData["timestamp"] is Timestamp) {
                    timestamp = (reviewData["timestamp"] as Timestamp).toDate();
                  } else {
                    timestamp = DateTime.now();
                  }

                  return _buildReviewItem(
                    userName,
                    rating,
                    comment,
                    timestamp,
                  );
                } catch (e) {
                  print("Error rendering review: $e");
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "Error displaying this review",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () => _showAddReviewDialog(productId),
              style: ElevatedButton.styleFrom(
                backgroundColor: PastelTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                "Write a Review",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
  Widget _buildSimilarProductsTab(Map<String, dynamic> productInfo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .where("category", isEqualTo: productInfo['category'])
          .where(FieldPath.documentId, isNotEqualTo: productInfo['id'])
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: PastelTheme.primary));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: PastelTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No similar products found",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: PastelTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Show similar products
        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = snapshot.data!.docs[index];
            var data = product.data() as Map<String, dynamic>;
            
            // Get product image
            String imageUrl = '';
            if (data['image'] is List && (data['image'] as List).isNotEmpty) {
              imageUrl = (data['image'] as List)[0];
            } else if (data['image'] is String) {
              imageUrl = data['image'];
            } else if (data['images'] is List && (data['images'] as List).isNotEmpty) {
              imageUrl = (data['images'] as List)[0];
            }
            
            return GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(productId: product.id),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: PastelTheme.cardShadow,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: PastelTheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                    // Product details
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Product',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PastelTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PKR ${double.tryParse(data['price'].toString())?.toStringAsFixed(2) ?? "0.00"}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PastelTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _showAddReviewDialog(String productId) {
  double rating = 5.0;
  final commentController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            'Write a Review',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: PastelTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Rating',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PastelTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Rating stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Review',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PastelTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: PastelTheme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: PastelTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: PastelTheme.primary),
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: PastelTheme.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please login to leave a review"),
                      backgroundColor: PastelTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                  return;
                }
                
                try {
                  // First, get product name for consistency
                  final productDoc = await FirebaseFirestore.instance
                      .collection("products")
                      .doc(productId)
                      .get();
                  
                  final productName = productDoc.exists && productDoc.data() != null
                    ? productDoc.data()!['name'] ?? 'Unknown Product'
                    : 'Unknown Product';

                  
                  // Now add the review to the global reviews collection
                  // This matches the admin-side collection structure
                  await FirebaseFirestore.instance
                      .collection("reviews")
                      .add({
                        'userId': user.uid,
                        'customerName': user.displayName ?? 'User',
                        'userName': user.displayName ?? 'User',
                        'productId': productId,
                        'productName': productName,
                        'rating': rating,
                        'reviewText': commentController.text.trim(),
                        'comment': commentController.text.trim(), // For backward compatibility
                        'date': FieldValue.serverTimestamp(),
                        'timestamp': FieldValue.serverTimestamp(),
                        'isDisplayed': true,
                        'isResponded': false,
                      });
                      
                  // Update average rating
                  final reviewsSnapshot = await FirebaseFirestore.instance
                      .collection("reviews")
                      .where('productId', isEqualTo: productId)
                      .where('isDisplayed', isEqualTo: true)
                      .get();
                      
                  double totalRating = 0;
                  int validReviewCount = 0;
                  
                  for (var doc in reviewsSnapshot.docs) {
                    final reviewData = doc.data();
                    if (reviewData['rating'] != null) {
                      totalRating += (reviewData['rating'] is num) 
                          ? (reviewData['rating'] as num).toDouble() 
                          : 0.0;
                      validReviewCount++;
                    }
                  }
                  
                  double averageRating = validReviewCount > 0 
                      ? totalRating / validReviewCount
                      : 0.0;
                  
                  await FirebaseFirestore.instance
                      .collection("products")
                      .doc(productId)
                      .update({
                        'rating': averageRating,
                        'reviewCount': validReviewCount,
                      });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Review added successfully"),
                      backgroundColor: PastelTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (error) {
                  print("Error adding review: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to add review: $error"),
                      backgroundColor: PastelTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PastelTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
}