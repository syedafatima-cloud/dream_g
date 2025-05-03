import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen
          },
        ),
        title: const Text("Order History"),
        backgroundColor: const Color.fromARGB(255, 174, 125, 183),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("Please log in to view order history."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No orders found."));
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    final orderId = orders[index].id;
                    final orderDate = order['orderDate']?.toDate();
                    final items = order['items'] ?? [];
                    final total = order['total'] ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Order ID: $orderId", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Date: ${orderDate?.toString().split(' ')[0] ?? 'N/A'}"),
                            const SizedBox(height: 4),
                            Text("Total: \$${total.toStringAsFixed(2)}"),
                            const Divider(),
                            const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ...List.generate(items.length, (i) {
                              return Text("- ${items[i]['name']} x${items[i]['quantity']}");
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
