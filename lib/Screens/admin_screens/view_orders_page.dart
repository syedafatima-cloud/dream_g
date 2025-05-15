import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:mobile_ap/models/order.dart';
import 'order_details_page.dart';
import 'add_order_page.dart';

class ViewOrdersPage extends StatefulWidget {
  const ViewOrdersPage({super.key});

  @override
  State<ViewOrdersPage> createState() => _ViewOrdersPageState();
}

class _ViewOrdersPageState extends State<ViewOrdersPage> {
  List<Order> allOrders = [];
  List<Order> filteredOrders = [];
  String selectedStatus = 'All';
  String searchQuery = '';
  bool isLoading = true;
  String? errorMessage;

  // Status color mapping using PastelTheme colors
  final Map<String, Color> statusColors = {
    'pending': Color(0xFFFFC8DD),     // PastelTheme.secondary
    'processing': Color.fromARGB(255, 197, 157, 216), // PastelTheme.primary
    'shipped': Color(0xFF9EC2FF),     // A soft blue
    'delivered': Color(0xFFABD8C6),   // PastelTheme.success
    'cancelled': Color(0xFFFFADAD),   // PastelTheme.error
  };
  
  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    firestore.FirebaseFirestore.instance
      .collection('orders')
      .snapshots()
      .listen(
        (snapshot) {
          if (mounted) {
            setState(() {
              allOrders = snapshot.docs.map((doc) {
                final data = doc.data();
                final docId = doc.id;
                
                return Order(
                  orderId: docId,
                  customerName: data['shippingAddress']?['name'] ?? 'Unknown',
                  product: (data['items'] != null && (data['items'] as List).isNotEmpty) 
                      ? '${(data['items'] as List).length} items' 
                      : 'No items',
                  dueDate: data['orderDate'] != null 
                      ? _formatTimestamp(data['orderDate'] as firestore.Timestamp) 
                      : 'Unknown',
                  status: data['status'] ?? 'pending',
                );
              }).toList();
              
              _filterOrders();
              isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              errorMessage = 'Failed to load orders: $error';
              isLoading = false;
            });
          }
        },
      );
  }

  String _formatTimestamp(firestore.Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _filterOrders() {
    setState(() {
      filteredOrders = allOrders.where((order) {
        final matchesStatus = selectedStatus == 'All' || 
                             order.status.toLowerCase() == selectedStatus.toLowerCase();
        final matchesSearch = order.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                            order.orderId.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      _filterOrders();
    });
  }

  void _onStatusChanged(String status) {
    setState(() {
      selectedStatus = status;
      _filterOrders();
    });
  }

  void _addOrder(Order newOrder) {
    firestore.FirebaseFirestore.instance
        .collection('orders')
        .add(newOrder.toMap())
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order added successfully'),
          backgroundColor: Color(0xFFABD8C6), // PastelTheme.success
          behavior: SnackBarBehavior.floating,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add order: $error'),
          backgroundColor: Color(0xFFFFADAD), // PastelTheme.error
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Access theme colors
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = theme.textTheme.bodySmall?.color;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchOrders();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newOrder = await Navigator.push<Order>(
            context,
            MaterialPageRoute(builder: (context) => const AddOrderPage()),
          );
          if (newOrder != null) {
            _addOrder(newOrder);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
        // FloatingActionButton uses the theme's floatingActionButtonTheme
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    final theme = Theme.of(context);
    final inputBackground = Color(0x25AAAAAA); // PastelTheme.inputBackground
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: theme.cardColor,
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: inputBackground,
              borderRadius: BorderRadius.circular(1000), // More rounded corners
                border: Border.all(style: BorderStyle.none),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                prefixIcon: Icon(Icons.search, color: theme.textTheme.bodySmall?.color),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: theme.textTheme.bodySmall?.color),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            _filterOrders();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 16),
          
          // Status filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('pending'),
                _buildFilterChip('processing'),
                _buildFilterChip('shipped'),
                _buildFilterChip('delivered'),
                _buildFilterChip('cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }
    
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Color(0xFFFFADAD)), // PastelTheme.error
            const SizedBox(height: 16),
            Text(errorMessage!, 
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: theme.textTheme.bodySmall?.color?.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty || selectedStatus != 'All'
                  ? 'No matching orders found'
                  : 'No orders yet',
              style: theme.textTheme.titleMedium,
            ),
            if (searchQuery.isNotEmpty || selectedStatus != 'All')
              TextButton(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    selectedStatus = 'All';
                    _filterOrders();
                  });
                },
                child: Text('Clear Filters', style: TextStyle(color: theme.primaryColor)),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final statusColor = statusColors[order.status.toLowerCase()] ?? Colors.grey;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final statusUpdated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => OrderDetailsPage(order: order)),
              );
              
              // If status was updated in details page, refresh orders list
              if (statusUpdated == true) {
                _filterOrders();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Customer initial avatar and name
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.primaryColor.withOpacity(0.2),
                              radius: 20,
                              child: Text(
                                order.customerName.isNotEmpty 
                                    ? order.customerName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.customerName,
                                    style: theme.textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '# ${order.orderId}',
                                    style: theme.textTheme.bodySmall,  
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(1000),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          _capitalizeFirstLetter(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  Divider(
                    height: 24,
                    color: Color(0x25AAAAAA), // PastelTheme.divider
                  ),
                  
                  // Order details
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    order.product,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: theme.textTheme.bodySmall?.color),
                                const SizedBox(width: 8),
                                Text(
                                  'Due: ${order.dueDate}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // View details button
                      Container(
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_forward,
                          color: theme.primaryColor,
                          size: 20,
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
  }

  Widget _buildFilterChip(String status) {
    final theme = Theme.of(context);
    final bool isSelected = selectedStatus.toLowerCase() == status.toLowerCase();
    final displayText = status == 'All' ? 'All' : _capitalizeFirstLetter(status);
    final chipColor = status == 'All' ? theme.primaryColor : (statusColors[status] ?? Colors.grey);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(displayText),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : chipColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: theme.cardColor,
        selectedColor: chipColor,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(1000),
          side: BorderSide(
            color: chipColor.withOpacity(isSelected ? 0 : 0.5),
          ),
        ),
        onSelected: (_) => _onStatusChanged(status),
      ),
    );
  }
}