import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_ap/firebase_options.dart';
import 'package:mobile_ap/screens/addresses_screen.dart' hide PastelTheme;
import 'package:mobile_ap/screens/admin_screens/add_product.dart';
import 'package:mobile_ap/screens/admin_screens/all_products_page.dart';
import 'package:mobile_ap/screens/admin_screens/batch_update_products_page.dart';
import 'package:mobile_ap/screens/admin_screens/delete_archive_products_page.dart';
import 'package:mobile_ap/screens/admin_screens/delete_product_page.dart';
import 'package:mobile_ap/screens/admin_screens/manage_categories_page.dart';
import 'package:mobile_ap/screens/admin_screens/manage_inventory_page';
import 'package:mobile_ap/screens/admin_screens/options_page.dart';
import 'package:mobile_ap/screens/admin_screens/track_inventory_history_page.dart';
import 'package:mobile_ap/screens/admin_screens/update_products_page.dart';
import 'package:mobile_ap/screens/admin_screens/view_orders_page.dart';
import 'package:mobile_ap/screens/admin_screens/view_product_page.dart';
import 'package:mobile_ap/screens/checkout_screen.dart' hide PastelTheme;
import 'package:mobile_ap/screens/order_history.dart';
import 'package:mobile_ap/screens/settings_screen.dart';
import 'package:mobile_ap/screens/splash_screen.dart';
import 'package:mobile_ap/screens/home_screen.dart' as home; 
import 'package:mobile_ap/screens/product_detail.dart' as detail; 
import 'package:mobile_ap/screens/login_page.dart';
import 'package:mobile_ap/screens/wishlist_screen.dart' hide PastelTheme;
import 'package:mobile_ap/screens/cart_screen.dart' as cart; 
import 'package:mobile_ap/screens/admin_screens/manage_products.dart'; 
import 'package:mobile_ap/screens/admin_screens/create_promotions_page.dart';
 import 'package:mobile_ap/screens/admin_screens/discount_page.dart';
 import 'package:mobile_ap/screens/admin_screens/free_shipping_page.dart';
 import 'package:mobile_ap/screens/admin_screens/promo_codes_page.dart';
 import 'package:mobile_ap/screens/admin_screens/validity_page.dart';
 import 'package:mobile_ap/screens/admin_screens/customer_review_page.dart';
 import 'package:mobile_ap/screens/admin_screens/generate_reports_page.dart';

import 'screens/help_screen.dart' show HelpScreen;
import 'screens/profile_screen.dart';
import 'pastel_theme.dart';
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
      theme: PastelTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const home.HomeScreen(),  
        '/productDetail': (context) => const detail.ProductDetailScreen(), 
        '/login': (context) => const LoginPage(),
        '/cart': (context) => cart.CartScreen(),  
        '/wishlist': (context) => const WishlistScreen(),
        '/orders': (context) => const OrderHistoryScreen(),
        '/checkout': (context) => CheckoutScreen(cartItems: [], totalAmount: 0, currency: '0', exchangeRate: 0,),
        '/settings' : (context) => SettingsScreen(),
        '/profile' : (context) => ProfileScreen(),
        '/help' : (context) => HelpScreen(),
        '/addresses' : (context) => AddressesScreen(),
        
        '/admin': (context) => const OptionsPage(),
        '/manageProducts': (context) => const ManageProductsPage(),
        '/viewOrders': (context) => const ViewOrdersPage(),
        '/manageInventory': (context) => const ManageInventoryPage(),
        '/manage_categories': (context) => const ManageCategoriesPage(),
        '/batch_update': (context) =>const  BatchUpdatePage(),
        '/track_inventory': (context) => const TrackInventoryStreamPage(),
        '/delete_archived': (context) => const DeleteArchivedProductsPage(),
        '/createPromotions': (context) =>const  CreatePromotionsPage(), 
        '/discount': (context) =>const  DiscountPage(),
        '/freeShipping': (context) => const FreeShippingPage(),
        '/validityPeriod': (context) => const ValidityPeriodPage(),
        '/promoCodes': (context) => const PromoCodesPage(),
        '/generatereports': (context) => const GenerateReportsPage(),  // Add this line
        '/customerreviews': (context) => const CustomerReviewsPage(),  // 

        '/addProduct': (context) => AddProductPage(),
        '/deleteProduct': (context) => DeleteProductPage(),
        '/updateProduct': (context) => UpdateProductPage(),
        '/viewProduct': (context) => ViewProductPage(),
        '/allProduct': (context) => AllProductsPage()

      }
    );
  }
}
