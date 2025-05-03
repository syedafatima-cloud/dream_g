import 'package:flutter/material.dart';
 
 class DiscountPage extends StatefulWidget {
   const DiscountPage({super.key});
 
   @override
   State<DiscountPage> createState() => _DiscountPageState();
 }
 
 class _DiscountPageState extends State<DiscountPage> {
   final _formKey = GlobalKey<FormState>();
   String _discountType = 'Percentage';
   final TextEditingController _valueController = TextEditingController();
   final TextEditingController _minPurchaseController = TextEditingController();
   bool _applyToAllProducts = true;
   List<String> _selectedCategories = [];
   final List<String> _availableCategories = [
     'Flowers', 'Gift Baskets', 'Chocolates', 'Teddy Bears', 'Cakes'
   ];
 
   @override
   void dispose() {
     _valueController.dispose();
     _minPurchaseController.dispose();
     super.dispose();
   }
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Create Discount'),
         centerTitle: true,
       ),
       body: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Form(
           key: _formKey,
           child: ListView(
             children: [
               Card(
                 elevation: 4,
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Discount Details',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 20),
                       DropdownButtonFormField<String>(
                         decoration: const InputDecoration(
                           labelText: 'Discount Type',
                           border: OutlineInputBorder(),
                         ),
                         value: _discountType,
                         items: ['Percentage', 'Fixed Amount']
                             .map((type) => DropdownMenuItem(
                                   value: type,
                                   child: Text(type),
                                 ))
                             .toList(),
                         onChanged: (value) {
                           setState(() {
                             _discountType = value!;
                           });
                         },
                       ),
                       const SizedBox(height: 16),
                       TextFormField(
                         controller: _valueController,
                         decoration: InputDecoration(
                           labelText: _discountType == 'Percentage' 
                               ? 'Discount Percentage (%)' 
                               : 'Discount Amount (\$)',
                           border: const OutlineInputBorder(),
                         ),
                         keyboardType: TextInputType.number,
                         validator: (value) {
                           if (value == null || value.isEmpty) {
                             return 'Please enter a value';
                           }
                           final num? parsedValue = num.tryParse(value);
                           if (parsedValue == null) {
                             return 'Please enter a valid number';
                           }
                           if (_discountType == 'Percentage' && 
                               (parsedValue < 0 || parsedValue > 100)) {
                             return 'Percentage must be between 0 and 100';
                           }
                           return null;
                         },
                       ),
                       const SizedBox(height: 16),
                       TextFormField(
                         controller: _minPurchaseController,
                         decoration: const InputDecoration(
                           labelText: 'Minimum Purchase Amount (\$)',
                           border: OutlineInputBorder(),
                         ),
                         keyboardType: TextInputType.number,
                         validator: (value) {
                           if (value != null && value.isNotEmpty) {
                             final num? parsedValue = num.tryParse(value);
                             if (parsedValue == null || parsedValue < 0) {
                               return 'Please enter a valid amount';
                             }
                           }
                           return null;
                         },
                       ),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 16),
               Card(
                 elevation: 4,
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Apply Discount To',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 10),
                       SwitchListTile(
                         title: const Text('Apply to all products'),
                         value: _applyToAllProducts,
                         onChanged: (value) {
                           setState(() {
                             _applyToAllProducts = value;
                             if (value) {
                               _selectedCategories = [];
                             }
                           });
                         },
                       ),
                       if (!_applyToAllProducts) ...[
                         const SizedBox(height: 10),
                         const Text('Select Categories:'),
                         const SizedBox(height: 5),
                         ..._availableCategories.map((category) {
                           return CheckboxListTile(
                             title: Text(category),
                             value: _selectedCategories.contains(category),
                             onChanged: (checked) {
                               setState(() {
                                 if (checked!) {
                                   _selectedCategories.add(category);
                                 } else {
                                   _selectedCategories.remove(category);
                                 }
                               });
                             },
                           );
                         }),
                       ],
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 20),
               ElevatedButton(
                 onPressed: () {
                   if (_formKey.currentState!.validate()) {
                     // Save the discount
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Discount created successfully!')),
                     );
                     // Navigate back or to confirmation screen
                     Navigator.pop(context);
                   }
                 },
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 15),
                   backgroundColor: Colors.purple,
                   foregroundColor: Colors.white,
                 ),
                 child: const Text('Save Discount'),
               ),
             ],
           ),
         ),
       ),
     );
   }
 }