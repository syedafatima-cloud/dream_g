import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_ap/firebase_options.dart';
import 'package:mobile_ap/screens/splash_screen.dart';
import 'package:mobile_ap/screens/home_screen.dart' as home; 
import 'package:mobile_ap/screens/product_detail.dart' as detail; 
import 'package:mobile_ap/screens/login_page.dart';
import 'package:mobile_ap/screens/wishlist_screen.dart';
import 'package:mobile_ap/screens/cart_screen.dart' as cart; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const home.HomeScreen(),  
        '/productDetail': (context) => const detail.ProductDetailScreen(), 
        '/login': (context) => const LoginPage(),
        '/cart': (context) => const cart.CartScreen(),  
        '/wishlist': (context) => const WishlistScreen(),
      },
    );
  }
}
