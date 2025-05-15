import 'package:flutter/material.dart';
import 'package:mobile_ap/pastel_theme.dart';
 
 class FreeShippingPage extends StatefulWidget {
   const FreeShippingPage({super.key});
 
   @override
   State<FreeShippingPage> createState() => _FreeShippingPageState();
 }
 
 class _FreeShippingPageState extends State<FreeShippingPage> {
   final _formKey = GlobalKey<FormState>();
   final TextEditingController _minimumOrderController = TextEditingController();
   bool _limitByRegion = false;
   List<String> _selectedRegions = [];
   final List<String> _availableRegions = [
     'North America', 'Europe', 'Asia', 'South America', 'Africa', 'Australia'
   ];
   
   DateTime _startDate = DateTime.now();
   DateTime _endDate = DateTime.now().add(const Duration(days: 30));
 
   @override
   void dispose() {
     _minimumOrderController.dispose();
     super.dispose();
   }
 
   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
     final DateTime? picked = await showDatePicker(
       context: context,
       initialDate: isStartDate ? _startDate : _endDate,
       firstDate: isStartDate ? DateTime.now() : _startDate,
       lastDate: DateTime.now().add(const Duration(days: 365)),
     );
     if (picked != null) {
       setState(() {
         if (isStartDate) {
           _startDate = picked;
           // Ensure end date is not before start date
           if (_endDate.isBefore(_startDate)) {
             _endDate = _startDate.add(const Duration(days: 1));
           }
         } else {
           _endDate = picked;
         }
       });
     }
   }
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Free Shipping Promotion'),
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
                         'Free Shipping Requirements',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 20),
                       TextFormField(
                         controller: _minimumOrderController,
                         decoration: const InputDecoration(
                           labelText: 'Minimum Order Amount (\$)',
                           hintText: 'Enter 0 for no minimum',
                           border: OutlineInputBorder(),
                         ),
                         keyboardType: TextInputType.number,
                         validator: (value) {
                           if (value == null || value.isEmpty) {
                             return 'Please enter a value';
                           }
                           final num? parsedValue = num.tryParse(value);
                           if (parsedValue == null || parsedValue < 0) {
                             return 'Please enter a valid amount';
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
                         'Promotion Period',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 20),
                       ListTile(
                         title: const Text('Start Date'),
                         subtitle: Text(
                           '${_startDate.toLocal()}'.split(' ')[0],
                           style: const TextStyle(fontSize: 16),
                         ),
                         trailing: const Icon(Icons.calendar_today),
                         onTap: () {
                           _selectDate(context, true);
                         },
                       ),
                       ListTile(
                         title: const Text('End Date'),
                         subtitle: Text(
                           '${_endDate.toLocal()}'.split(' ')[0],
                           style: const TextStyle(fontSize: 16),
                         ),
                         trailing: const Icon(Icons.calendar_today),
                         onTap: () {
                           _selectDate(context, false);
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
                         'Region Limitations',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 10),
                       SwitchListTile(
                         title: const Text('Limit by Region'),
                         value: _limitByRegion,
                         onChanged: (value) {
                           setState(() {
                             _limitByRegion = value;
                             if (!value) {
                               _selectedRegions = [];
                             }
                           });
                         },
                       ),
                       if (_limitByRegion) ...[
                         const SizedBox(height: 10),
                         const Text('Select Regions:'),
                         const SizedBox(height: 5),
                         ..._availableRegions.map((region) {
                           return CheckboxListTile(
                             title: Text(region),
                             value: _selectedRegions.contains(region),
                             onChanged: (checked) {
                               setState(() {
                                 if (checked!) {
                                   _selectedRegions.add(region);
                                 } else {
                                   _selectedRegions.remove(region);
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
                     // Save the free shipping promotion
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Free shipping promotion created successfully!')),
                     );
                     // Navigate back or to confirmation screen
                     Navigator.pop(context);
                   }
                 },
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 15),
                   backgroundColor: PastelTheme.primary,
                   foregroundColor: PastelTheme.cardColor,
                 ),
                 child: const Text('Save Free Shipping Promotion'),
               ),
             ],
           ),
         ),
       ),
     );
   }
 }