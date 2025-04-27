import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _selectedCategory = "All";
  final List<String> _categories = ["All", "Flowers", "Chocolates", "Books", "Gifts"];
  
  // Gradient animation setup
  final List<List<Color>> _gradients = [
    [const Color.fromARGB(255, 250, 244, 192), const Color.fromARGB(255, 245, 187, 206)],
    [const Color.fromARGB(255, 231, 178, 196), const Color.fromARGB(255, 251, 217, 172)],
    [const Color.fromARGB(255, 176, 199, 239), const Color.fromARGB(255, 242, 198, 250)],
  ];
  
  int _currentGradient = 0;
  int _nextGradient = 1;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
 @override
void initState() {
  super.initState();
  _addSampleProducts();

  _animationController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  );

  _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentGradient = _nextGradient;
        _nextGradient = (_nextGradient + 1) % _gradients.length;
        _animationController.reset();
        _animationController.forward();
      }
    });

  _animationController.forward();
}

  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _addSampleProducts() async {
  final productsRef = FirebaseFirestore.instance.collection("products");

  await _addProductIfNotExists(productsRef, {
  "name": "Roses Bouquet",
  "price": 49.99,
  "category": "flowers",
  "rating": 4.8,
  "description": "Beautiful bouquet of fresh red roses, perfect for romantic occasions.",
  "image": "https://images.unsplash.com/photo-1509042239860-f550ce710b93"
});

await _addProductIfNotExists(productsRef, {
  "name": "Tulip Mix",
  "price": 39.99,
  "category": "flowers",
  "rating": 4.6,
  "description": "Colorful mix of fresh tulips in various vibrant colors, perfect for brightening any room.",
  "image": "https://images.unsplash.com/photo-1504203700686-421f7095fddb"
});

await _addProductIfNotExists(productsRef, {
  "name": "Luxury Truffles Box",
  "price": 29.99,
  "category": "chocolates",
  "rating": 4.9,
  "description": "Handcrafted luxury chocolate truffles in an elegant gift box. Perfect for special occasions.",
  "image": "https://images.unsplash.com/photo-1590080877637-7f21c5411b1c",
  "link": "https://example.com/product/luxury-truffles"
});

await _addProductIfNotExists(productsRef, {
  "name": "The Great Gatsby",
  "price": 14.99,
  "category": "books",
  "rating": 4.5,
  "description": "F. Scott Fitzgerald's classic novel depicting the Jazz Age in 1920s America.",
  "image": "https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg",
  "link": "https://example.com/product/the-great-gatsby"
});

await _addProductIfNotExists(productsRef, {
  "name": "1984",
  "price": 12.99,
  "category": "books",
  "rating": 4.8,
  "description": "George Orwell's dystopian classic about the dangers of totalitarianism and mass surveillance.",
  "image": "https://images-na.ssl-images-amazon.com/images/I/71kxa1-0mfL.jpg",
  "link": "https://example.com/product/1984"
});


  await _addProductIfNotExists(productsRef, {
    "name": "Gift Basket",
    "price": 59.99,
    "category": "gifts",
    "rating": 4.7,
    "description": "Elegant gift basket with assorted treats and goodies.",
    "image": "https://images.unsplash.com/photo-1549465220-1a8b9238cd48?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
    "link": "https://example.com/product/gift-basket"
  });
}

Future<void> _addProductIfNotExists(CollectionReference ref, Map<String, dynamic> data) async {
  try {
    final query = await ref.where("name", isEqualTo: data["name"]).limit(1).get();
    if (query.docs.isEmpty) {
      await ref.add(data);
      print("Added product: ${data['name']}");
    } else {
      print("Product ${data['name']} already exists");
    }
  } catch (e) {
    print("Error adding product: $e");
  }
}

 @override
Widget build(BuildContext context) {
  // Set system overlay style for status bar
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent,
  ));

  return AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return Scaffold(
        backgroundColor: Color.lerp(
          _gradients[_currentGradient][0],
          _gradients[_nextGradient][0],
          _animation.value,
        ), // Animated background color
        appBar: _buildAppBar(), // AppBar already animated inside
        body: child, // Body passed as child to avoid rebuilding
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: FloatingActionButton(
            onPressed: () => _navigateToCart(),
            backgroundColor: const Color(0xFFF6C4FF),
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    },
    child: _buildBody(), // Pre-built body
  );
}

PreferredSizeWidget _buildAppBar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return AppBar(
          centerTitle: true, // <-- Important to center properly
          title: SvgPicture.asset(
            'assets/logo.svg', // your SVG path
            width: 36, // bigger size (you can adjust it, maybe 36 or 40)
            height: 36,
            placeholderBuilder: (context) => const Icon(Icons.shopping_bag),
          ),
          backgroundColor: Color.lerp(
            _gradients[_currentGradient][0], 
            _gradients[_nextGradient][0], 
            _animation.value,
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, size: 26),
              onPressed: () => _showSearchDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 26),
              onPressed: () => _showNotifications(),
            ),
          ],
        );
      },
    ),
  );
}



  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 800));
      },
      color: const Color.fromARGB(255, 245, 204, 252),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Banner
          SliverToBoxAdapter(
            child: _buildEnhancedBanner(),
          ),
          
          // Categories Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAllCategories(),
                    child: Text(
                      "See All", 
                      style: TextStyle(
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Category Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text(_categories[index]),
                      selected: _selectedCategory == _categories[index],
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategory = _categories[index];
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: _selectedCategory == _categories[index] 
                            ? Colors.white 
                            : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Products Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                "${_selectedCategory} Products",
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  // Enhanced banner with asset image
Widget _buildEnhancedBanner() {
  return Container(
    height: 160,
    margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      image: const DecorationImage(
        image: AssetImage('assets/gift_banner.PNG'), // your asset image
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.5), 
            Colors.black.withOpacity(0.2),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ), // optional: adds dark overlay for better text visibility
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "20% OFF",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "On selected items",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A11CB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text("Shop Now", style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProductsGrid() {
    print("Building products grid with category: $_selectedCategory");

    return StreamBuilder(
      stream: _selectedCategory == "All"
          ? FirebaseFirestore.instance.collection("products").snapshots()
          : FirebaseFirestore.instance
              .collection("products")
              .where("category", isEqualTo: _selectedCategory.toLowerCase())
              .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          print("Error loading products: ${snapshot.error}");
          return SliverFillRemaining(
            child: Center(
              child: Text("Error loading products: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print("Waiting for products data...");
          return SliverFillRemaining(
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A11CB)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("No products found for category: $_selectedCategory");
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No products found for ${_selectedCategory.toLowerCase()}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        var products = snapshot.data!.docs;
        print("Found ${products.length} products");

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85, // Increased to make cards shorter
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              var product = products[index];
              var data = product.data() as Map<String, dynamic>;

              return _buildCompactProductCard(
                id: product.id,
                name: data["name"] ?? "No Name",
                price: double.tryParse(data["price"].toString()) ?? 0.0,
                imageUrl: data["image"] ?? "",
                rating: data["rating"] ?? 4.5,
                productLink: data.containsKey("link") ? data["link"].toString() : "#",
              );
            },
            childCount: products.length,
          ),
        );
      },
    );
  }

  // Shortened product card to prevent overflow
  Widget _buildCompactProductCard({
  required String id,
  required String name,
  required double price,
  required dynamic imageUrl,
  required double rating,
  required String productLink, // you can ignore this for now if not needed
}) {
  final String finalImageUrl = imageUrl is List
      ? (imageUrl.isNotEmpty ? imageUrl[0].toString() : "")
      : imageUrl.toString();

  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context,
        '/productDetail', // 👈 your route name
        arguments: {
          'id': id,
          'name': name,
          'price': price,
          'images': [finalImageUrl], // 👈 wrap in List
          'rating': rating,
          'description': 'This is a sample description.', // 👈 you can customize
        },
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[200],
              child: CachedNetworkImage(
                imageUrl: finalImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    InkWell(
                      onTap: () => _addToCart(id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6C4FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14,
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


  // Bottom navigation bar with gradient animation
  Widget _buildBottomNavBar() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(_gradients[_currentGradient][0], _gradients[_nextGradient][0], _animation.value)!,
                Color.lerp(_gradients[_currentGradient][1], _gradients[_nextGradient][1], _animation.value)!,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.6),
            currentIndex: _selectedIndex,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              
              if (index == 1) {
                _navigateToWishlist();
              } else if (index == 2) {
                _showProfileOptions();
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: "Wishlist",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigation and Action Methods
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Search Products"),
        content: TextField(
          decoration: InputDecoration(
            hintText: "What are you looking for?",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No new notifications"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAllCategories() {
    // Implementation simplified to avoid overflow issues
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "All Categories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((category) {
                  return ActionChip(
                    label: Text(category),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                    backgroundColor: _selectedCategory == category
                        ? const Color(0xFFF6C4FF) 
                        : Colors.grey[200],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToProductDetail(
    String productId,
    String name, 
    double price, 
    String imageUrl, 
    double rating,
    String productLink
  ) {
    // Enhanced navigation with detailed arguments
    Navigator.pushNamed(
      context,
      '/product',
      arguments: {
        'id': productId,
        'name': name,
        'price': price,
        'image': imageUrl,
        'rating': rating,
        'link': productLink
      }
    );
  }

  void _navigateToCart() {
    Navigator.pushNamed(context, '/cart');
  }
  
  void _navigateToWishlist() {
    Navigator.pushNamed(context, '/wishlist');
  }

  void _addToCart(String productId) {
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
      }, SetOptions(merge: true)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to cart"),
            duration: Duration(seconds: 2),
          ),
        );
      });
    } else {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text("Please login to continue shopping"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions() {
    final user = FirebaseAuth.instance.currentUser;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFF6C4FF).withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: const Color(0xFFF6C4FF),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? "User",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? "Guest User",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text("My Orders"),
                onTap: () => Navigator.pushNamed(context, '/orders'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text("Settings"),
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              const SizedBox(height: 16),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () => _handleLogout(),
                )
              else
                ListTile(
                  leading: const Icon(Icons.login, color: Color(0xFF6A11CB)),
                  title: const Text("Login", style: TextStyle(color: Color(0xFF6A11CB))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error during logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error during logout: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Product Detail Screen
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isInWishlist = false;
  String _selectedSize = "M";
  final List<String> _availableSizes = ["XS", "S", "M", "L", "XL"];
  
  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }
  
  void _checkWishlistStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('id')) {
        final String productId = args['id'];
        
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
  }
  
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Product Detail")),
        body: const Center(child: Text("No product information provided")),
      );
    }
    
    final String name = args['name'] ?? "Unknown Product";
    final double price = args['price'] ?? 0.0;
    final String imageUrl = args['image'] ?? "";
    final double rating = args['rating'] ?? 0.0;
    final String productId = args['id'] ?? "";
    final String productLink = args['link'] ?? "#";
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar with image
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: "product_$productId",
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6A11CB)),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
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
                    color: Colors.white.withOpacity(0.8),
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
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.black),
                ),
                onPressed: () => _shareProduct(name, productLink),
              ),
            ],
          ),
          
          // Product Details
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20.0),
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
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "\$${price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A11CB),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Size",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeSelector(),
                  const SizedBox(height: 24),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This premium ${name.toLowerCase()} is crafted with the finest materials and attention to detail. Perfect for any occasion, it combines style, comfort, and durability to provide you with a great experience.",
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Quantity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuantitySelector(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                "Total: \$${(price * _quantity).toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: ElevatedButton(
                onPressed: () => _addToCart(productId, _quantity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Add to Cart",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSizeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: _availableSizes.map((size) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSize = size;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedSize == size ? const Color(0xFF6A11CB) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedSize == size ? const Color(0xFF6A11CB) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  size,
                  style: TextStyle(
                    color: _selectedSize == size ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildQuantitySelector() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            if (_quantity > 1) {
              setState(() {
                _quantity--;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.remove, size: 16),
          ),
        ),
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          child: Text(
            _quantity.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            setState(() {
              _quantity++;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
      ],
    );
  }
  
  void _toggleWishlist(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }
    
    setState(() {
      _isInWishlist = !_isInWishlist;
    });
    
    final wishlistRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("wishlist")
        .doc(productId);
    
    if (_isInWishlist) {
      // Add to wishlist
      await wishlistRef.set({
        'addedAt': FieldValue.serverTimestamp()
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to wishlist"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Remove from wishlist
      await wishlistRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from wishlist"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _shareProduct(String name, String productLink) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sharing $name"),
        duration: const Duration(seconds: 2),
      ),
    );
    // Here you would implement actual sharing functionality
    // using a package like share_plus
  }
  
  void _addToCart(String productId, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .set({
        'quantity': quantity,
        'size': _selectedSize,
        'addedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to cart"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error adding to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding to cart: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text("Please login to continue shopping"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
}

// Cart Screen
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  double _subtotal = 0.0;
  final double _shippingFee = 5.99;
  final double _taxRate = 0.08; // 8% tax
  
  @override
  void initState() {
    super.initState();
    _calculateSubtotal();
  }
  
  Future<void> _calculateSubtotal() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _subtotal = 0.0;
        _isLoading = false;
      });
      return;
    }
    
    try {
      // Get cart items
      final cartSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .get();
          
      if (cartSnapshot.docs.isEmpty) {
        setState(() {
          _subtotal = 0.0;
          _isLoading = false;
        });
        return;
      }
      
      // Get all product IDs from cart
      final productIds = cartSnapshot.docs.map((doc) => doc.id).toList();
      
      // Fetch product details for each item in cart
      double total = 0.0;
      for (var productId in productIds) {
        final productDoc = await FirebaseFirestore.instance
            .collection("products")
            .doc(productId)
            .get();
            
        if (productDoc.exists) {
          final productData = productDoc.data();
          if (productData != null && productData.containsKey("price")) {
            // Get quantity from cart
            final cartItem = cartSnapshot.docs.firstWhere((doc) => doc.id == productId);
            final quantity = cartItem.data()["quantity"] ?? 1;
            
            // Calculate item total
            final price = double.tryParse(productData["price"].toString()) ?? 0.0;
            total += price * quantity;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _subtotal = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error calculating subtotal: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final double tax = _subtotal * _taxRate;
    final double total = _subtotal + _shippingFee + tax;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(  
          "My Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: user == null
          ? _buildLoginPrompt()
          : _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
              : _buildCartContent(user, total),
    );
  }
  
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please login to view your cart",
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCartContent(User user, double total) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Your cart is empty",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start shopping to add items to your cart",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text("Continue Shopping"),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final cartItem = snapshot.data!.docs[index];
                  final productId = cartItem.id;
                  final quantity = cartItem["quantity"] ?? 1;
                  final size = cartItem["size"] ?? "M";
                  
                  return _buildCartItemCard(productId, quantity, size);
                },
              ),
            ),
            _buildOrderSummary(total),
          ],
        );
      },
    );
  }
  
  Widget _buildCartItemCard(String productId, int quantity, String size) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("products").doc(productId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final productData = snapshot.data!.data() as Map<String, dynamic>?;
        if (productData == null) {
          return const SizedBox();
        }
        
        final name = productData["name"] ?? "Unknown Product";
        final price = double.tryParse(productData["price"].toString()) ?? 0.0;
        final imageUrl = productData["image"] ?? "";
        
        return Dismissible(
          key: Key(productId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 30,
            ),
          ),
          onDismissed: (direction) => _removeCartItem(productId),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 6),
                        Text(
                          "Size: $size",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "\$${price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF6A11CB),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _updateQuantity(productId, quantity - 1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    quantity.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _updateQuantity(productId, quantity + 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
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
      },
    );
  }
  
  Widget _buildOrderSummary(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Summary",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Subtotal",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text("\$${_subtotal.toStringAsFixed(2)}"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Shipping",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text("\$${_shippingFee.toStringAsFixed(2)}"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tax",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text("\$${(_subtotal * _taxRate).toStringAsFixed(2)}"),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "\$${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A11CB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _subtotal > 0 ? () => _proceedToCheckout(total) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A11CB),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Proceed to Checkout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _removeCartItem(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .delete();
          
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item removed from cart"),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Recalculate subtotal
      _calculateSubtotal();
    } catch (e) {
      print("Error removing item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error removing item: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeCartItem(productId);
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .doc(productId)
          .update({
        'quantity': newQuantity,
      });
      
      // Recalculate subtotal
      _calculateSubtotal();
    } catch (e) {
      print("Error updating quantity: $e");
    }
  }
  
  void _proceedToCheckout(double total) {
    Navigator.pushNamed(
      context, 
      '/checkout',
      arguments: {'total': total}
    );
  }
}

// Checkout Screen
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  String _selectedPaymentMethod = "Credit Card";
  bool _saveInformation = false;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Set email if available
    if (user.email != null && user.email!.isNotEmpty) {
      _emailController.text = user.email!;
    }
    
    // Set name if available
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }
    
    try {
      // Check if user has saved shipping info
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          if (userData.containsKey("phone")) {
            _phoneController.text = userData["phone"];
          }
          if (userData.containsKey("address")) {
            _addressController.text = userData["address"];
          }
          if (userData.containsKey("city")) {
            _cityController.text = userData["city"];
          }
          if (userData.containsKey("zip")) {
            _zipController.text = userData["zip"];
          }
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final double total = args != null ? args['total'] as double : 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isProcessing 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6A11CB)),
                  SizedBox(height: 20),
                  Text(
                    "Processing your order...",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Contact Information"),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration("Full Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration("Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return "Please enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration("Phone Number"),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle("Shipping Address"),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration("Street Address"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: _inputDecoration("City"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your city";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: _zipController,
                            decoration: _inputDecoration("Zip Code"),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter zip code";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _saveInformation,
                      onChanged: (value) {
                        setState(() {
                          _saveInformation = value ?? false;
                        });
                      },
                      title: const Text("Save this information for next time"),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF6A11CB),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle("Payment Method"),
                    const SizedBox(height: 16),
                    _buildPaymentMethodSelector(),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle("Order Summary"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total"),
                              Text(
                                "\$${total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _placeOrder(total),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A11CB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Place Order",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A11CB)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
  
  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _buildPaymentOption(
          "Credit Card",
          Icons.credit_card,
          "Pay with credit or debit card",
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          "PayPal",
          Icons.account_balance_wallet,
          "Pay with your PayPal account",
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          "Apple Pay",
          Icons.apple,
          "Quick payment with Apple Pay",
        ),
      ],
    );
  }
  
  Widget _buildPaymentOption(String method, IconData icon, String description) {
    final isSelected = _selectedPaymentMethod == method;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A11CB) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6A11CB).withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF6A11CB) : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Radio(
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value.toString();
                });
              },
              activeColor: const Color(0xFF6A11CB),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _placeOrder(double total) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to place an order"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Save user information if requested
      if (_saveInformation) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'zip': _zipController.text,
        }, SetOptions(merge: true));
      }
      
      // Get cart items
      final cartSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cart")
          .get();
          
      final cartItems = cartSnapshot.docs.map((doc) {
        return {
          'productId': doc.id,
          'quantity': doc.data()['quantity'] ?? 1,
          'size': doc.data()['size'] ?? 'M',
        };
      }).toList();
      
      // Create order
      final orderRef = await FirebaseFirestore.instance.collection("orders").add({
        'userId': user.uid,
        'items': cartItems,
        'total': total,
        'status': 'pending',
        'paymentMethod': _selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'shipping': {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'zip': _zipController.text,
        }
      });
      
      // Clear cart
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Navigate to order confirmation
      Navigator.pushReplacementNamed(
        context,
        '/order_confirmation',
        arguments: {'orderId': orderRef.id},
      );
    } catch (e) {
      print("Error placing order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error placing order: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

// Order Confirmation Screen
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String orderId = args != null ? args['orderId'] as String : "Unknown";
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A11CB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6A11CB),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Thank You!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Your order has been placed successfully",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Order ID: #${orderId.substring(0, 8)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "We'll send you a confirmation email with your order details and tracking information once your order ships.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/', 
                      (route) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A11CB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Continue Shopping",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/orders'),
                  child: const Text(
                    "View My Orders",
                    style: TextStyle(
                      color: Color(0xFF6A11CB),
                      fontWeight: FontWeight.bold,
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
}

// Orders Screen
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: user == null
          ? _buildLoginPrompt(context)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("userId", isEqualTo: user.uid)
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No orders yet",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start shopping to place orders",
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A11CB),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text("Shop Now"),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final order = snapshot.data!.docs[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    
                    final Timestamp? timestamp = orderData['createdAt'] as Timestamp?;
                    final DateTime orderDate = timestamp?.toDate() ?? DateTime.now();
                    final String formattedDate = "${orderDate.day}/${orderDate.month}/${orderDate.year}";
                    
                    final String status = orderData['status'] ?? "pending";
                    final double total = double.tryParse(orderData['total'].toString()) ?? 0.0;
                    final List<dynamic>? items = orderData['items'] as List<dynamic>?;
                    final int itemCount = items?.length ?? 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showOrderDetails(context, order.id, orderData),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Order #${order.id.substring(0, 8)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$itemCount item${itemCount > 1 ? 's' : ''}",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "\$${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6A11CB),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
  
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            "Login to view your orders",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String badgeText;
    
    switch(status.toLowerCase()) {
      case 'completed':
        badgeColor = Colors.green;
        badgeText = 'Completed';
        break;
      case 'shipped':
        badgeColor = Colors.blue;
        badgeText = 'Shipped';
        break;
      case 'processing':
        badgeColor = Colors.orange;
        badgeText = 'Processing';
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        badgeText = 'Cancelled';
        break;
      default:
        badgeColor = Colors.amber;
        badgeText = 'Pending';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  void _showOrderDetails(BuildContext context, String orderId, Map<String, dynamic> orderData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final List<dynamic>? items = orderData['items'] as List<dynamic>?;
        final String status = orderData['status'] ?? "pending";
        final double total = double.tryParse(orderData['total'].toString()) ?? 0.0;
        final Map<String, dynamic>? shipping = orderData['shipping'] as Map<String, dynamic>?;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Details",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Order #${orderId.substring(0, 8)}",
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Order Items
const Text(
  "Order Items",
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 12),
items != null && items.isNotEmpty
    ? ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("products")
                .doc(item['productId'])
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6A11CB),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              
              final productData = snapshot.data!.data() as Map<String, dynamic>?;
              final String name = productData?['name'] ?? 'Product Not Found';
              final double price = double.tryParse(productData?['price'].toString() ?? '0') ?? 0.0;
              final String imageUrl = productData?['imageUrl'] ?? '';
              final int quantity = item['quantity'] ?? 1;
              final String size = item['size'] ?? 'M';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.image_not_supported, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Size: $size",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Qty: $quantity",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "\$${(price * quantity).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      )
    : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text("No items found"),
        ),
      ),
const SizedBox(height: 24),

// Shipping Information
const Text(
  "Shipping Information",
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 12),
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      _buildInfoRow("Name", shipping?['name'] ?? 'N/A'),
      const SizedBox(height: 8),
      _buildInfoRow("Email", shipping?['email'] ?? 'N/A'),
      const SizedBox(height: 8),
      _buildInfoRow("Phone", shipping?['phone'] ?? 'N/A'),
      const SizedBox(height: 8),
      _buildInfoRow("Address", shipping?['address'] ?? 'N/A'),
      const SizedBox(height: 8),
      _buildInfoRow("City", shipping?['city'] ?? 'N/A'),
      const SizedBox(height: 8),
      _buildInfoRow("Zip Code", shipping?['zip'] ?? 'N/A'),
    ],
  ),
),
const SizedBox(height: 24),

// Order Summary
const Text(
  "Order Summary",
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 12),
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Subtotal"),
          Text("\$${total.toStringAsFixed(2)}"),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text("Shipping"),
          Text("Free"),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "\$${total.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A11CB),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ],
  ),
),
const SizedBox(height: 32),

// Actions
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () => Navigator.pop(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6A11CB),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: const Text(
      "Close",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Set email if available
      if (user.email != null && user.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
      
      // Set name if available
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
      
      // Get additional user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          setState(() {
            if (userData.containsKey("name") && _nameController.text.isEmpty) {
              _nameController.text = userData["name"];
            }
            if (userData.containsKey("phone")) {
              _phoneController.text = userData["phone"];
            }
            if (userData.containsKey("address")) {
              _addressController.text = userData["address"];
            }
            if (userData.containsKey("city")) {
              _cityController.text = userData["city"];
            }
            if (userData.containsKey("zip")) {
              _zipController.text = userData["zip"];
            }
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login to save your profile"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update display name in Firebase Auth
      await user.updateDisplayName(_nameController.text);
      
      // Save additional data to Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'zip': _zipController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile saved successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving profile: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false,
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error signing out: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: user == null
          ? _buildLoginPrompt(context)
          : _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
                              child: Text(
                                _nameController.text.isNotEmpty 
                                    ? _nameController.text[0].toUpperCase() 
                                    : user.email != null && user.email!.isNotEmpty 
                                        ? user.email![0].toUpperCase() 
                                        : "U",
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A11CB),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _nameController.text.isNotEmpty 
                                  ? _nameController.text 
                                  : "User",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email ?? "",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Profile Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Personal Information",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration("Full Name"),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your name";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration("Email"),
                              readOnly: true, // Email cannot be changed
                              enabled: false,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              decoration: _inputDecoration("Phone Number"),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your phone number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            const Text(
                              "Shipping Address",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: _inputDecoration("Street Address"),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your address";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: _inputDecoration("City"),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your city";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: TextFormField(
                                    controller: _zipController,
                                    decoration: _inputDecoration("Zip Code"),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter zip code";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A11CB),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Save Profile",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _signOut,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Color(0xFF6A11CB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Logout",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6A11CB),
                                  ),
                                ),
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
  
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            "Login to view your profile",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A11CB)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}