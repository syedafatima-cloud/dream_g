import 'package:flutter/material.dart';
import 'package:mobile_ap/models/order.dart'; 

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _orderIdController,
                decoration: const InputDecoration(labelText: 'Order ID'),
                validator: (value) => value!.isEmpty ? 'Please enter Order ID' : null,
              ),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (value) => value!.isEmpty ? 'Please enter Customer Name' : null,
              ),
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(labelText: 'Product'),
                validator: (value) => value!.isEmpty ? 'Please enter Product' : null,
              ),
              TextFormField(
                controller: _dueDateController,
                decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                validator: (value) => value!.isEmpty ? 'Please enter Due Date' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _status,
                items: ['Pending', 'Delivered', 'Cancelled'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitOrder,
                child: const Text('Submit Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}