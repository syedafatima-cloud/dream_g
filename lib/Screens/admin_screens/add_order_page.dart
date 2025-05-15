import 'package:flutter/material.dart';
import 'package:mobile_ap/models/order.dart';
import 'package:mobile_ap/screens/addresses_screen.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _productController = TextEditingController();
  final _dueDateController = TextEditingController();
  String _status = 'Pending';

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      final newOrder = Order(
        orderId: _orderIdController.text,
        customerName: _customerNameController.text,
        product: _productController.text,
        dueDate: _dueDateController.text,
        status: _status,
      );
      Navigator.pop(context, newOrder);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Order'),
        centerTitle: true,
        backgroundColor: PastelTheme.primary,
        foregroundColor: PastelTheme.secondary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _orderIdController,
                    decoration: _buildInputDecoration('Order ID', Icons.confirmation_number),
                    validator: (value) => value!.isEmpty ? 'Please enter Order ID' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: _buildInputDecoration('Customer Name', Icons.person),
                    validator: (value) => value!.isEmpty ? 'Please enter Customer Name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _productController,
                    decoration: _buildInputDecoration('Product', Icons.shopping_bag),
                    validator: (value) => value!.isEmpty ? 'Please enter Product' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dueDateController,
                    decoration: _buildInputDecoration('Due Date (YYYY-MM-DD)', Icons.date_range),
                    validator: (value) => value!.isEmpty ? 'Please enter Due Date' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _buildInputDecoration('Status', Icons.assignment_turned_in),
                    items: ['Pending', 'Delivered', 'Cancelled'].map((status) {
                      return DropdownMenuItem(value: status, child: Text(status));
                    }).toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitOrder,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Submit Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PastelTheme.primary,
                        foregroundColor: PastelTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
