import 'package:flutter/material.dart';
import 'package:mobile_ap/screens/admin_screens/manage_categories_page.dart';
import 'package:mobile_ap/screens/admin_screens/batch_update_products_page.dart';
import 'package:mobile_ap/screens/admin_screens/track_inventory_history_page.dart';
import 'package:mobile_ap/screens/admin_screens/delete_archive_products_page.dart';

class ManageInventoryPage extends StatelessWidget {
  const ManageInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Inventory'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageCategoriesPage()),
                );
              },
              icon: const Icon(Icons.category),
              label: const Text('Manage Categories & Tags'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BatchUpdatePage()),
                );
              },
              icon: const Icon(Icons.update),
              label: const Text('Batch Update Products'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrackInventoryStreamPage()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Track Inventory History'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeleteArchivedProductsPage()),
                );
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete / Archive Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}