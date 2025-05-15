import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_ap/models/order.dart' as model;
import 'package:mobile_ap/pastel_theme.dart'; // Import the PastelTheme

class OrderDetailsPage extends StatefulWidget {
  final model.Order order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late String selectedStatus;
  bool isUpdating = false;

  // Status color mapping using PastelTheme colors
  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'processing': PastelTheme.primary, // Using theme primary color for processing
    'shipped': Color.fromARGB(255, 177, 147, 196), // Lighter purple
    'delivered': PastelTheme.success, // Using theme success color
    'cancelled': PastelTheme.error, // Using theme error color
  };

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.order.status;
  }

  void _updateStatus() async {
    if (selectedStatus == widget.order.status) {
      // No change in status, show message and return
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No changes to update'),
          backgroundColor: PastelTheme.primary.withOpacity(0.8),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      isUpdating = true;
    });
    
    try {
      // Update the order status in Firestore
      await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.order.orderId)
        .update({'status': selectedStatus.toLowerCase()});
      
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${_capitalizeFirstLetter(selectedStatus)}'),
            backgroundColor: PastelTheme.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Pop back to previous screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate status was updated
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: PastelTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final displayStatus = _capitalizeFirstLetter(selectedStatus);
    final statusColor = statusColors[selectedStatus] ?? Colors.grey;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PastelTheme.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Date Header Section
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order ID',
                            style: TextStyle(
                              color: PastelTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Display status chip
                          Chip(
                            label: Text(
                              displayStatus,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: statusColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderId,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: PastelTheme.divider),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Due Date',
                            style: TextStyle(
                              color: PastelTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            order.dueDate,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: PastelTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Customer Information Section
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: PastelTheme.secondary.withOpacity(0.3),
                          child: Icon(Icons.person, color: PastelTheme.primary),
                        ),
                        title: Text(
                          order.customerName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: PastelTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Customer',
                          style: TextStyle(color: PastelTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Product Details Section
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: PastelTheme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.inventory_2,
                                color: PastelTheme.primary,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.product,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // If you have additional product details, display them here
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Update Status Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1000), // Using rounded corners from theme
                          border: Border.all(color: PastelTheme.divider),
                          color: PastelTheme.inputBackground,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: displayStatus,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: PastelTheme.primary),
                            items: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled']
                                .map((status) => DropdownMenuItem(
                                      value: status, 
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColors[status.toLowerCase()] ?? PastelTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: isUpdating 
                                ? null 
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedStatus = value.toLowerCase();
                                      });
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isUpdating ? null : _updateStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PastelTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1000), // Using rounded corners from theme
                            ),
                            elevation: 0,
                          ),
                          child: isUpdating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Update Status',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: isUpdating 
                              ? null 
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: PastelTheme.primary),
                            foregroundColor: PastelTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1000), // Using rounded corners from theme
                            ),
                          ),
                          child: Text(
                            'Back to Orders',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}