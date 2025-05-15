
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_ap/screens/checkout_screen.dart' hide PastelTheme;
import 'package:google_fonts/google_fonts.dart';
import '../pastel_theme.dart';
import 'package:mobile_ap/models/cart.dart';
import 'product_detail.dart' hide PastelTheme;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  bool _loadingRecommendations = true;
  double _totalAmount = 0;
  List<Map<String, dynamic>> _getFilteredRecommendations() {
  final cartItemIds = _cartItems.map((item) => item.id).toSet();
  return _recommendations.where((product) => !cartItemIds.contains(product['id'])).toList();
}

  // ScrollController for smoother scrolling experience
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadCartItems();
    _loadRecommendations();
    
    // Add a small delay before scrolling to ensure the UI is built
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      double totalPKR = 0;

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
          final pricePKR = double.tryParse(productData['price'].toString()) ?? 0.0;
          
          final cartItem = CartItem(
            id: productId,
            name: productData['name'] ?? 'Unknown Product',
            price: pricePKR,
            imageUrl: (productData['image'] is List<dynamic> && (productData['image'] as List).isNotEmpty)
                ? productData['image'][0]
                : (productData['image'] is String ? productData['image'] : 'https://via.placeholder.com/150'),
            quantity: doc.data()['quantity'] ?? 1,
          );

          loadedItems.add(cartItem);
          totalPKR += cartItem.totalPrice;
        }
      }

      setState(() {
        _cartItems = loadedItems;
        _totalAmount = totalPKR;
        _isLoading = false;
      });
    } catch (error) {
      print("Error loading cart items: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading cart items. Please try again."),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to load recommendations from Firebase products collection
  Future<void> _loadRecommendations() async {
    setState(() {
      _loadingRecommendations = true;
    });

    try {
      // Get current categories from cart items (for relevant recommendations)
      Set<String> cartCategories = {};

      // We'll get recommendations after cart items are loaded
      if (_cartItems.isNotEmpty) {
        for (var item in _cartItems) {
          final productSnapshot = await FirebaseFirestore.instance
              .collection("products")
              .doc(item.id)
              .get();
          
          if (productSnapshot.exists) {
            final category = productSnapshot.data()?['category'];
            if (category != null) {
              cartCategories.add(category);
            }
          }
        }
      }

      // Query for recommended products
      Query recommendationsQuery = FirebaseFirestore.instance.collection("products");
      
      // Prioritize products from the same categories as items in cart
      if (cartCategories.isNotEmpty) {
        recommendationsQuery = recommendationsQuery.where("category", whereIn: cartCategories.take(10).toList());
      }
      
      // Limit results and maybe sort by rating if available
      final snapshot = await recommendationsQuery
          .orderBy("rating", descending: true)
          .limit(10)
          .get();

      // Filter out products already in cart
      final Set<String> cartProductIds = _cartItems.map((item) => item.id).toSet();

      final List<Map<String, dynamic>> recommendations = snapshot.docs
          .map<Map<String, dynamic>>((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "id": doc.id,
              "name": data["name"] ?? "Unknown Product",
              "price": double.tryParse(data["price"].toString()) ?? 0.0,
              "image": data["image"] is List ? data["image"] : [data["image"]],
              "description": data["description"] ?? "",
              "category": data["category"] ?? "",
              "rating": data["rating"] ?? 0.0,
            };
          })
          .where((product) => !cartProductIds.contains(product["id"]))
          .toList();

      setState(() {
        _recommendations = recommendations;
        _loadingRecommendations = false;
      });
    } catch (error) {
      print("Error loading recommendations: $error");
      setState(() {
        _loadingRecommendations = false;
      });
    }
  }

  // Method to clear all items from the cart using batch processing
  Future<void> _clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Create a batch operation for efficient updates
      final batch = FirebaseFirestore.instance.batch();
      final cartRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart");
      
      // Get all cart items
      final cartSnapshot = await cartRef.get();
      
      // Add delete operations to batch
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
      
      // Update local state
      setState(() {
        _cartItems = [];
        _totalAmount = 0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All items removed from cart"),
          backgroundColor: PastelTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      print("Error clearing cart: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error clearing cart. Please try again."),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Method to update cart item quantity
  Future<void> _updateCartItemQuantity(String productId, int newQuantity) async {
    if (newQuantity < 1) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update in Firebase
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .update({"quantity": newQuantity});

      // Update local state
      setState(() {
        final index = _cartItems.indexWhere((item) => item.id == productId);
        if (index != -1) {
          _cartItems[index].quantity = newQuantity;
          
          // Recalculate total
          _totalAmount = _cartItems.fold(
            0,
            (sum, item) => sum + item.totalPrice,
          );
        }
      });
    } catch (error) {
      print("Error updating quantity: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating quantity. Please try again."),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Remove item from cart
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
        
        // Recalculate total
        _totalAmount = _cartItems.fold(
          0,
          (sum, item) => sum + item.totalPrice,
        );
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Item removed from cart"),
          backgroundColor: PastelTheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (error) {
      print("Error removing item: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error removing item. Please try again."),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Add recommended product to cart
  Future<void> _addRecommendedProductToCart(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if product already exists in cart
      final cartSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(product["id"])
          .get();

      if (cartSnapshot.exists) {
        // Update quantity if already in cart
        final currentQuantity = cartSnapshot.data()?["quantity"] ?? 0;
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("cart")
            .doc(product["id"])
            .update({"quantity": currentQuantity + 1});
      } else {
        // Add new item to cart
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("cart")
            .doc(product["id"])
            .set({"quantity": 1});
      }

      // Refresh cart
      _loadCartItems();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${product["name"]} added to cart"),
          backgroundColor: PastelTheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print("Error adding to cart: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding to cart. Please try again."),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
  // Navigate to your existing product detail screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailScreen(
        productId: product["id"],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    // Apply Inter font to the entire widget - more modern than Nunito Sans
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        colorScheme: ColorScheme.light(
          primary: PastelTheme.primary,
          secondary: PastelTheme.secondary,
          surface: PastelTheme.background,
          error: PastelTheme.error,
        ),
      ),
      child: Scaffold(
        backgroundColor: PastelTheme.background,
        appBar: AppBar(
          backgroundColor: PastelTheme.primary,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Your Cart",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20),
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
                ),
              )
            : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartWithItems(),
      ),
    );
  }
  
  Widget _buildEmptyCart() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Empty cart illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: PastelTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 40,
                color: PastelTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Your cart is empty",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: PastelTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Browse our collection and discover premium products for you",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: PastelTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to products/home screen
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PastelTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000),
                ),
              ),
              child: Text(
                "CONTINUE SHOPPING",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Show recommendations even when cart is empty
            if (_recommendations.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recommended for you",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PastelTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _loadingRecommendations
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
                    ),
                  )
                :  SizedBox(
                      height: 140, // Match card height
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        itemCount: _getFilteredRecommendations().length,
                        itemBuilder: (context, index) {
                          final recommendation = _getFilteredRecommendations()[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildHorizontalRecommendationCard(recommendation),
                          );
                        },
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }


 Widget _buildRecommendationCard(Map<String, dynamic> product) {
    // Completely redesigned card with fixed dimensions
    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - FIXED HEIGHT
            Container(
              height: 110, // FIXED height for image
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    product['image'] is List ? product['image'][0] : product['image'] ?? '',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: InkWell(
                  onTap: () => _addRecommendedProductToCart(product),
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: PastelTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // Product details with FIXED HEIGHT
            Container(
              height: 50, // FIXED height for text content
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product['name'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PastelTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PKR ${product['price'].toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
  }
  Widget _buildHorizontalRecommendationCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        width: 85, // Even more compact width for horizontal cards
        height: 140, // Fixed height to prevent stretching
        decoration: BoxDecoration(
          color: PastelTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image - smaller aspect ratio
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: CachedNetworkImage(
                  imageUrl: product['image'] is List ? product['image'][0] : product['image'] ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: Center(child: CircularProgressIndicator(color: PastelTheme.primary, strokeWidth: 1.5)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 14),
                  ),
                ),
              ),
            ),
            // Compact product details
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product['name'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: PastelTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PKR ${product['price'].toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: PastelTheme.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      // Integrated add button next to price
                      InkWell(
                        onTap: () => _addRecommendedProductToCart(product),
                        child: Container(
                          decoration: BoxDecoration(
                            color: PastelTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCartWithItems() {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Recommendations section
            if (_recommendations.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "You may also like",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PastelTheme.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to all recommendations
                            },
                            child: Text(
                              "View all",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: PastelTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _loadingRecommendations
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
                            ),
                          )
                        : SizedBox(
                          height: 140, // Match the card height exactly
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            itemCount: _recommendations.length,
                            itemBuilder: (context, index) {
                              final recommendation = _recommendations[index];
                              return Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: _buildHorizontalRecommendationCard(recommendation),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Divider
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: PastelTheme.inputBackground, thickness: 1),
              ),
            ),

            // Cart Items Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Cart Items",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PastelTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: PastelTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${_cartItems.length}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PastelTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Optional: Add "Clear all" button if needed
                    if (_cartItems.length > 1)
                      TextButton.icon(
                        onPressed: () {
                          // Show confirmation dialog before clearing
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Clear Cart"),
                              content: Text("Are you sure you want to remove all items?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("CANCEL"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearCart();
                                  },
                                  child: Text(
                                    "CLEAR ALL",
                                    style: GoogleFonts.inter(
                                      color: PastelTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        
                        label: Text(
                          "Clear all",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: PastelTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Cart Items List
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 120), // Increased bottom padding for checkout button
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _cartItems[index];
                    return _buildCartItemCard(item);
                  },
                  childCount: _cartItems.length,
                ),
              ),
            ),
          ],
        ),

        // Checkout bottom bar
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 8),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Order summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: PastelTheme.textSecondary,
                        ),
                      ),
                      Text(
                        "PKR ${_totalAmount.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Shipping",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: PastelTheme.textSecondary,
                        ),
                      ),
                      Text(
                        "PKR 150.00",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      Text(
                        "PKR ${(_totalAmount + 150).toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PastelTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              cartItems: _convertCartItemsToMap(_cartItems),
                              totalAmount: _totalAmount + 150, // Including shipping
                              currency: "PKR",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PastelTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28), // Circular corners
                        ),
                      ),
                      child: Text(
                        "PROCEED TO CHECKOUT",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: PastelTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[100],
                child: Center(child: CircularProgressIndicator(color: PastelTheme.primary, strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
            ),
          ),
          // Product details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: PastelTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PKR ${item.price.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: PastelTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Remove button
                      InkWell(
                        onTap: () => _removeCartItem(item.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: PastelTheme.inputBackground.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: PastelTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity text
                      Text(
                        'Quantity:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: PastelTheme.textSecondary,
                        ),
                      ),
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: PastelTheme.inputBackground),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Decrease button
                            InkWell(
                              onTap: () => _updateCartItemQuantity(item.id, item.quantity - 1),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: PastelTheme.inputBackground),
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
                              width: 32,
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: PastelTheme.textPrimary,
                                ),
                              ),
                            ),
                            // Increase button
                            InkWell(
                              onTap: () => _updateCartItemQuantity(item.id, item.quantity + 1),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: PastelTheme.inputBackground),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Utility method to convert CartItem objects to a map for passing to other screens
  List<Map<String, dynamic>> _convertCartItemsToMap(List<CartItem> items) {
    return items.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'imageUrl': item.imageUrl,
        'totalPrice': item.totalPrice,
      };
    }).toList();
  }
}
