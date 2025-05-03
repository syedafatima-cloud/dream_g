import 'package:flutter/material.dart';
import 'package:mobile_ap/models/order.dart'; 
import 'order_details_page.dart';
import 'add_order_page.dart'; // <-- NEW IMPORT

class ViewOrdersPage extends StatefulWidget {
  const ViewOrdersPage({super.key});

  @override
  State<ViewOrdersPage> createState() => _ViewOrdersPageState();
}

class _ViewOrdersPageState extends State<ViewOrdersPage> {
  final List<Order> allOrders = [
    Order(orderId: '001', customerName: 'Alice Johnson', product: 'Bouquet of Roses', dueDate: '2025-05-01', status: 'Pending'),
    Order(orderId: '002', customerName: 'Bob Smith', product: 'Custom Gift Basket', dueDate: '2025-05-03', status: 'Delivered'),
    Order(orderId: '003', customerName: 'Catherine Lee', product: 'Chocolate Box', dueDate: '2025-05-05', status: 'Cancelled'),
    Order(orderId: '004', customerName: 'Daniel Green', product: 'Personalized Mug', dueDate: '2025-05-07', status: 'Pending'),
    Order(orderId: '005', customerName: 'Ella Brown', product: 'Photo Frame', dueDate: '2025-05-08', status: 'Delivered'),
  ];

  List<Order> filteredOrders = [];
  String selectedStatus = 'All';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredOrders = List.from(allOrders);
  }

  void _filterOrders() {
    setState(() {
      filteredOrders = allOrders.where((order) {
        final matchesStatus = selectedStatus == 'All' || order.status == selectedStatus;
        final matchesSearch = order.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            order.orderId.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    searchQuery = query;
    _filterOrders();
  }

  void _onStatusChanged(String status) {
    selectedStatus = status;
    _filterOrders();
  }

  void _addOrder(Order newOrder) {
    setState(() {
      allOrders.add(newOrder);
      _filterOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Orders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by customer name or order ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Pending'),
                  _buildFilterChip('Delivered'),
                  _buildFilterChip('Cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: ListTile(
                      title: Text('Order ID: ${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer: ${order.customerName}'),
                            Text('Product: ${order.product}'),
                            Text('Due Date: ${order.dueDate}'),
                            const SizedBox(height: 8),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderDetailsPage(order: order)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newOrder = await Navigator.push<Order>(
            context,
            MaterialPageRoute(builder: (context) => const AddOrderPage()),
          );
          if (newOrder != null) {
            _addOrder(newOrder);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedStatus == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.blue.shade300,
        onSelected: (_) => _onStatusChanged(label),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == 'Pending') {
      color = Colors.orange;
    } else if (status == 'Delivered') {
      color = Colors.green;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}