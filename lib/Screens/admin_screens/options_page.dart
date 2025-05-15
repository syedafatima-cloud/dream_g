import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// Import your pastel theme

class OptionsPage extends StatelessWidget {
  const OptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access theme colors
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Options Management'),
        centerTitle: true,
        actions: [
          // Add change password icon to app bar corner
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: 'Change Password',
            onPressed: () {
              Navigator.pushNamed(context, '/changePassword');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              height: 90,
              width: 90,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildOptionButton(context, 'Manage Products', '/manageProducts'),
                  _buildOptionButton(context, 'View Orders', '/viewOrders'),
                  _buildOptionButton(context, 'Manage Inventory', '/manageInventory'),
                  _buildOptionButton(context, 'Create Promotions', '/createPromotions'),
                  _buildOptionButton(context, 'Generate Reports', '/generatereports'),
                  _buildOptionButton(context, 'View Customer Reviews', '/customerreviews')
                ],
              ),
            ),
            // Removed the Change Password button from here
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String title, String routeName) {
    // Using the pastel theme's primary color (soft purple) instead of blue
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, routeName),
      // The button style is now defined in the theme, but we can add custom styling here
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        title, 
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}