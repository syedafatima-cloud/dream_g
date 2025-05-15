import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_ap/screens/addresses_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final String userId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final orderDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Tracking',
          style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: PastelTheme.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: orderDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Processing';
          final items = data['items'] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order ID: $orderId",
                  style: GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Text(
                  "Current Status: $status",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: PastelTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Items:",
                  style: GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                ...items.map((item) => ListTile(
                      title: Text(item['name']),
                      subtitle: Text("Qty: ${item['quantity']}"),
                      trailing: Text("Rs. ${item['price']}"),
                    )),
                const Spacer(),
                Center(
                  child: Text(
                    "Tracking updates in real-time",
                    style: GoogleFonts.nunitoSans(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}