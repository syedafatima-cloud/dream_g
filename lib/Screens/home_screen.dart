
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_ap/pastel_theme.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _selectedCategory = "All";
  final bool _isLoading = true;
  List<String> _categories = [];

 
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
  _addCategoriesToFirestore(); // optional if already added
  _fetchCategories(); // fetch from Firebase

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
  Future<void> _addCategoriesToFirestore() async {
  final categoriesRef = FirebaseFirestore.instance.collection('categories');

  final List<String> categories = ["Flowers", "Chocolates", "Books", "Gifts"]; // No "All" here

  for (String category in categories) {
    final existing = await categoriesRef.where("name", isEqualTo: category).get();
    if (existing.docs.isEmpty) {
      await categoriesRef.add({"name": category});
    }
  }
}
  Future<void> _fetchCategories() async {
  final snapshot = await FirebaseFirestore.instance.collection('categories').get();
  setState(() {
    _categories = ["All"]; // Add "All" manually
    _categories.addAll(snapshot.docs.map((doc) => doc['name'].toString()).toList());
  });
}

  Future<void> _addSampleProducts() async {
  final productsRef = FirebaseFirestore.instance.collection("products");

  await _addProductIfNotExists(productsRef, {
  "name": "Roses Bouquet",
  "price": 2000,
  "category": "flowers",
  "rating": 4.8,
  "description": "Beautiful bouquet of fresh red roses, perfect for romantic occasions.",
  "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1746008317/roses_2_gopiwo.jpg"
});

await _addProductIfNotExists(productsRef, {
  "name": "Tulip Mix",
  "price": 5000,
  "category": "flowers",
  "rating": 4.6,
  "description": "Colorful mix of fresh tulips in various vibrant colors, perfect for brightening any room.",
  "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1746008317/tulips_vl3x1m.jpg"
});

await _addProductIfNotExists(productsRef, {
  "name": "Luxury Truffles Box",
  "price": 3000,
  "category": "chocolates",
  "rating": 4.9,
  "description": "Handcrafted luxury chocolate truffles in an elegant gift box. Perfect for special occasions.",
  "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1746008876/truffles_sf3lmq.jpg",
  "link": "https://example.com/product/luxury-truffles"
});
await _addProductIfNotExists(productsRef, {
  "name": "Lavender Soy Candle",
  "price": 1000,
  "category": "candles",
  "rating": 4.7,
  "description": "Relaxing lavender-scented soy candle that calms and soothes your senses.",
  "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1747167018/lavender_candle_hemv8m.jpg",
  "link": "https://example.com/product/lavender-soy-candle"
});
await _addProductIfNotExists(productsRef, {
  "name": "Fourty Rules of Love",
  "price": 1200,
  "category": "books",
  "rating": 4.7,
  "description": "A story of pure and divine love with sufism.",
  "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1747167007/fourty-rules_hkj4au.jpg",
  "link": "https://example.com/product/lavender-soy-candle"
});

await _addProductIfNotExists(productsRef, {
  "name": "Birthday Basket",
  "price": 4000,
  "category": "gifts",
  "rating": 4.7,
  "description": "A thoughtful gift for your loved ones to make their day special.",
  "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1747167007/birthday-basket_osqqek.jpg",
  "link": "https://example.com/product/lavender-soy-candle"
});

await _addProductIfNotExists(productsRef, {
  "name": "The Great Gatsby",
  "price": 2000,
  "category": "books",
  "rating": 4.5,
  "description": "F. Scott Fitzgerald's classic novel depicting the Jazz Age in 1920s America.",
  "image": "https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg",
  "link": "https://example.com/product/the-great-gatsby"
});

await _addProductIfNotExists(productsRef, {
  "name": "Sunflowers",
  "price": 2000,
  "category": "flowers",
  "rating": 4.5,
  "description": "Bright yellow flowers to brighten up your day.",
  "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1747167018/sunflowers_bwg2fd.jpg",
  "link": "https://example.com/product/the-great-gatsby"
});
await _addProductIfNotExists(productsRef, {
  "name": "1984",
  "price": 2000,
  "category": "books",
  "rating": 4.8,
  "description": "George Orwell's dystopian classic about the dangers of totalitarianism and mass surveillance.",
  "image": "https://images-na.ssl-images-amazon.com/images/I/71kxa1-0mfL.jpg",
  "link": "https://example.com/product/1984"
});


  await _addProductIfNotExists(productsRef, {
    "name": "Gift Basket",
    "price": 2000,
    "category": "gifts",
    "rating": 4.7,
    "description": "Elegant gift basket with assorted treats and goodies.",
    "image": "https://res.cloudinary.com/dax4erfc1/image/upload/v1746008877/gift_bhigvf.png",
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
            backgroundColor: const Color.fromARGB(255, 214, 172, 233),
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
            width: 47, // bigger size (you can adjust it, maybe 36 or 40)
            height: 47,
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
          color: PastelTheme.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Banner
              SliverToBoxAdapter(
                child: _buildEnhancedBanner(),
              ),
              
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

    // Category Chips without Icons
    SliverToBoxAdapter(
      child: SizedBox(
        height: 50, // Reduced height since we no longer have icons
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: FilterChip(
                label: Text(_categories[index]),
                selected: _selectedCategory == _categories[index],
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategory = _categories[index];
                    }
                  });
                },
                backgroundColor: Colors.grey[100],
                selectedColor: Colors.blue[100],
                labelStyle: TextStyle(
                  color: Colors.black87,
                  fontWeight: _selectedCategory == _categories[index]
                    ? FontWeight.w500
                    : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedCategory == _categories[index]
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
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
                "$_selectedCategory Products",
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
                foregroundColor: PastelTheme.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
              price: (double.tryParse(data["price"].toString()) ?? 0.0) ,
              imageUrl: data["image"] ?? "",
              rating: (data["rating"] is num) ? (data["rating"] as num).toDouble() : 4.5,
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
                      "PKR ${price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    InkWell(
                      onTap: () => _addToCart(id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: PastelTheme.primary,
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
      isScrollControlled: true, 
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: PastelTheme.primary.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: PastelTheme.primary,
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
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text("My Addresses"),
                onTap: () => Navigator.pushNamed(context, '/addresses'),
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
        )
        );
      },
      );
  }

  void _handleLogout() async {
  try {
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear saved login status

    Navigator.pushReplacementNamed(context, '/login'); // Go back to login page

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
        duration: Duration(seconds: 3),
      ),
    );
  }
}

}
