import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_ap/screens/checkout_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Pastel theme colors (kept the same)
class PastelTheme {
  static const Color primary = Color.fromARGB(255, 197, 157, 216); // Soft blue
  static const Color secondary = Color(0xFFFFC8DD); // Soft pink
  static const Color accent = Color.fromARGB(255, 60, 61, 55); // Light blue
  static const Color background = Color(0xFFF8EDEB); // Soft cream
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF445566); // Darker blue-gray (adjusted for professionalism)
  static const Color textSecondary = Color(0xFF7A8999); // Medium blue-gray (adjusted for professionalism)
  static const Color success = Color(0xFFABD8C6); // Mint green
  static const Color error = Color(0xFFFFADAD); // Soft red
}
// Model class for cart items
class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  double? priceInPKR; // Added PKR price field

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.priceInPKR,
  });

  double get totalPrice => price * quantity;
  double get totalPriceInPKR => (priceInPKR ?? (price * 278.5)) * quantity; // Default conversion if not provided
  
  // Convert CartItem instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'priceInPKR': priceInPKR ?? (price * 278.5), // Include PKR price in map
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}

class CartScreen extends StatefulWidget {
  CartScreen({super.key});
  final List<CartItem> _cartItems = []; 
  double totalAmount = 0.0; 

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  bool _loadingRecommendations = true;
  double _totalAmount = 0;
  double _totalAmountPKR = 0;
  double _exchangeRate = 278.5; // Default exchange rate (1 USD = 278.5 PKR)
  bool _showPKR = true; // Toggle between USD and PKR

  @override
  void initState() {
    super.initState();
    _loadExchangeRate();
    _loadCartItems();
    _loadRecommendations();
  }

  // Method to load current exchange rate (in a real app, you would use an API)
  Future<void> _loadExchangeRate() async {
    try {
      // You could fetch the current exchange rate from an API here
      // For example:
      // final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      // final data = jsonDecode(response.body);
      // _exchangeRate = data['rates']['PKR'];
      
      // For now, we'll use a static rate
      setState(() {
        _exchangeRate = 278.5; // 1 USD = 278.5 PKR (you should use real-time data)
      });
    } catch (error) {
      print("Error loading exchange rate: $error");
      // Fallback to default rate
    }
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
      double totalUSD = 0;
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
          final priceUSD = double.tryParse(productData['price'].toString()) ?? 0.0;
          final pricePKR = priceUSD * _exchangeRate;
          
          final cartItem = CartItem(
            id: productId,
            name: productData['name'] ?? 'Unknown Product',
            price: priceUSD,
            priceInPKR: pricePKR,
            imageUrl: (productData['image'] is List<dynamic> && (productData['image'] as List).isNotEmpty)
                ? productData['image'][0]
                : (productData['image'] is String ? productData['image'] : 'https://via.placeholder.com/150'),
            quantity: doc.data()['quantity'] ?? 1,
          );

          loadedItems.add(cartItem);
          totalUSD += cartItem.totalPrice;
          totalPKR += cartItem.totalPriceInPKR;
        }
      }

      setState(() {
        _cartItems = loadedItems;
        _totalAmount = totalUSD;
        _totalAmountPKR = totalPKR;
        _isLoading = false;
      });
    } catch (error) {
      print("Error loading cart items: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading cart items. Please try again."),
          backgroundColor: PastelTheme.error,
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
              "priceInPKR": (double.tryParse(data["price"].toString()) ?? 0.0) * _exchangeRate,
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
        SnackBar(
          content: Text("Failed to update quantity. Please try again."),
          backgroundColor: PastelTheme.error,
        ),
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
        SnackBar(
          content: Text("Item removed from cart"),
          backgroundColor: PastelTheme.success,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to remove item. Please try again."),
          backgroundColor: PastelTheme.error,
        ),
      );
    }
  }

  // Helper method to recalculate total amount
  void _recalculateTotal() {
    double totalUSD = 0;
    double totalPKR = 0;
    for (var item in _cartItems) {
      totalUSD += item.totalPrice;
      totalPKR += item.totalPriceInPKR;
    }
    setState(() {
      _totalAmount = totalUSD;
      _totalAmountPKR = totalPKR;
    });
  }

  // Add recommended product to cart
  void _addRecommendedProductToCart(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please sign in to add to cart"),
          backgroundColor: PastelTheme.error,
        ),
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
      // Refresh recommendations (to remove the newly added item)
      await _loadRecommendations();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${product['name']} added to cart"),
          backgroundColor: PastelTheme.success,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add item to cart. Please try again."),
          backgroundColor: PastelTheme.error,
        ),
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
        'priceInPKR': product['priceInPKR'],
        'images': product['image'],
        'rating': product['rating'],
        'description': product['description'],
        'category': product['category'],
      },
    );
  }

  // Toggle between USD and PKR
  void _toggleCurrency() {
    setState(() {
      _showPKR = !_showPKR;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Apply Nunito Sans font to the entire widget
    final textTheme = GoogleFonts.nunitoSansTextTheme(
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
          title: Text(
            "My Cart",
            style: GoogleFonts.nunitoSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          backgroundColor: PastelTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            // Currency toggle button
            TextButton.icon(
              onPressed: _toggleCurrency,
              icon: Icon(Icons.currency_exchange, color: Colors.white),
              label: Text(
                _showPKR ? "PKR" : "USD",
                style: GoogleFonts.nunitoSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
              ))
            : _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined, 
                          size: 80, 
                          color: PastelTheme.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Your cart is empty",
                          style: GoogleFonts.nunitoSans(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: PastelTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Add items to get started",
                          style: GoogleFonts.nunitoSans(
                            color: PastelTheme.textSecondary,
                          ),
                        ),
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
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              elevation: 1,
                              color: PastelTheme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Row(
                                  children: [
                                    // Image with error handling
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[200],
                                            child: Icon(Icons.image_not_supported, color: PastelTheme.textSecondary),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Item details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: PastelTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _showPKR 
                                                ? "PKR ${item.priceInPKR?.toStringAsFixed(2) ?? (item.price * _exchangeRate).toStringAsFixed(2)}"
                                                : "\$${item.price.toStringAsFixed(2)}",
                                            style: GoogleFonts.nunitoSans(
                                              color: PastelTheme.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                _showPKR
                                                    ? "Subtotal: PKR ${item.totalPriceInPKR.toStringAsFixed(2)}"
                                                    : "Subtotal: \$${item.totalPrice.toStringAsFixed(2)}",
                                                style: GoogleFonts.nunitoSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: PastelTheme.textSecondary,
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
                                               icon: Icon(FontAwesomeIcons.minus, size: 18),
                                              color: PastelTheme.error,
                                              onPressed: () => _updateCartItemQuantity(item.id, item.quantity - 1),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: PastelTheme.accent.withOpacity(0.3),
                                              ),
                                              child: Text(
                                                item.quantity.toString(),
                                                style: GoogleFonts.nunitoSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: PastelTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(FontAwesomeIcons.plus, size: 18),
                                              color: PastelTheme.success,
                                              onPressed: () => _updateCartItemQuantity(item.id, item.quantity + 1),
                                            ),
                                          ],
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _removeCartItem(item.id),
                                          icon: const Icon(Icons.delete_outline, size: 14),
                                          label: Text(
                                            "Remove",
                                            style: GoogleFonts.nunitoSans(),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: PastelTheme.error,
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
                          color: PastelTheme.background.withOpacity(0.7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  "You may also like",
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 180,
                                child: _loadingRecommendations 
                                  ? Center(child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
                                    ))
                                  : _recommendations.isEmpty
                                    ? Center(child: Text(
                                        "No recommendations available",
                                        style: GoogleFonts.nunitoSans(
                                          color: PastelTheme.textSecondary,
                                        ),
                                      ))
                                    : ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _recommendations.length,
                                        itemBuilder: (context, index) {
                                          final recommendation = _recommendations[index];
                                          return Stack(
                                            children: [
                                              GestureDetector(
                                                onTap: () => _navigateToProductDetail(recommendation),
                                                child: Card(
                                                  margin: const EdgeInsets.only(right: 16),
                                                  color: PastelTheme.cardColor,
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
                                                                child: Center(
                                                                  child: CircularProgressIndicator(
                                                                    valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
                                                                  ),
                                                                ),
                                                              ),
                                                              errorWidget: (context, url, error) => Container(
                                                                color: Colors.grey[200],
                                                                child: Icon(Icons.image_not_supported, color: PastelTheme.textSecondary),
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
                                                                style: GoogleFonts.nunitoSans(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: PastelTheme.textPrimary,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                _showPKR
                                                                    ? "PKR ${recommendation['priceInPKR'].toStringAsFixed(2)}"
                                                                    : "\$${recommendation['price'].toStringAsFixed(2)}",
                                                                style: GoogleFonts.nunitoSans(
                                                                  color: PastelTheme.textPrimary,
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
                                              ),
                                              // Add to cart button
                                              Positioned(
                                              bottom: 8,
                                              right: 22,
                                              child: Container(
                                                padding: EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: PastelTheme.primary,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      spreadRadius: 1,
                                                      blurRadius: 3,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: GestureDetector(
                                                  onTap: () => _addRecommendedProductToCart(recommendation),
                                                  child: Icon(
                                                    Icons.add_shopping_cart,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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
                  color: PastelTheme.cardColor,
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
                          Text(
                            "Total",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              color: PastelTheme.textSecondary,
                            ),
                          ),
                          Text(
                            _showPKR
                                ? "PKR ${_totalAmountPKR.toStringAsFixed(2)}"
                                : "\$${_totalAmount.toStringAsFixed(2)}",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: PastelTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to checkout with currency information
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  cartItems: _convertCartItemsToMap(_cartItems),
                                  totalAmount: _showPKR ? _totalAmountPKR : _totalAmount,
                                  currency: _showPKR ? "PKR" : "USD",
                                  exchangeRate: _exchangeRate,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PastelTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "CHECKOUT",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  
  List<Map<String, dynamic>> _convertCartItemsToMap(List<CartItem> cartItems) {
    return cartItems.map((item) => item.toMap()).toList();
  }
}