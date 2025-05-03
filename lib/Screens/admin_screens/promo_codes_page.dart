import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 import 'dart:math';
 
 class PromoCodesPage extends StatefulWidget {
   const PromoCodesPage({super.key});
 
   @override
   State<PromoCodesPage> createState() => _PromoCodesPageState();
 }
 
 class _PromoCodesPageState extends State<PromoCodesPage> {
   final _formKey = GlobalKey<FormState>();
   final TextEditingController _codeController = TextEditingController();
   final TextEditingController _discountValueController = TextEditingController();
   final TextEditingController _usageLimitController = TextEditingController();
   String _discountType = 'Percentage';
   bool _generateRandomCode = false;
   int _codeLength = 8;
   
   final List<Map<String, dynamic>> _generatedCodes = [];
 
   @override
   void dispose() {
     _codeController.dispose();
     _discountValueController.dispose();
     _usageLimitController.dispose();
     super.dispose();
   }
 
   String _generateCode() {
     const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
     Random rnd = Random();
     return String.fromCharCodes(
       Iterable.generate(
         _codeLength, 
         (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
       )
     );
   }
 
   void _generateNewCode() {
     setState(() {
       _codeController.text = _generateCode();
     });
   }
 
   void _addPromoCode() {
     if (_formKey.currentState!.validate()) {
       setState(() {
         _generatedCodes.add({
           'code': _codeController.text,
           'type': _discountType,
           'value': _discountValueController.text,
           'usageLimit': _usageLimitController.text.isNotEmpty 
             ? int.parse(_usageLimitController.text) 
             : null,
         });
         
         // Reset form for next code
         if (_generateRandomCode) {
           _generateNewCode();
         } else {
           _codeController.clear();
         }
         _discountValueController.clear();
         _usageLimitController.clear();
       });
       
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Promo code added successfully!')),
       );
     }
   }
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Promo Codes'),
         centerTitle: true,
       ),
       body: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             Expanded(
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
                               'Promo Code Details',
                               style: TextStyle(
                                 fontSize: 18,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(height: 20),
                             SwitchListTile(
                               title: const Text('Generate Random Code'),
                               value: _generateRandomCode,
                               onChanged: (value) {
                                 setState(() {
                                   _generateRandomCode = value;
                                   if (value) {
                                     _generateNewCode();
                                   } else {
                                     _codeController.clear();
                                   }
                                 });
                               },
                             ),
                             if (_generateRandomCode) ...[
                               Row(
                                 children: [
                                   Expanded(
                                     child: Slider(
                                       value: _codeLength.toDouble(),
                                       min: 6,
                                       max: 12,
                                       divisions: 6,
                                       label: _codeLength.toString(),
                                       onChanged: (value) {
                                         setState(() {
                                           _codeLength = value.toInt();
                                           _generateNewCode();
                                         });
                                       },
                                     ),
                                   ),
                                   Text('Length: $_codeLength'),
                                 ],
                               ),
                             ],
                             TextFormField(
                               controller: _codeController,
                               readOnly: _generateRandomCode,
                               decoration: InputDecoration(
                                 labelText: 'Promo Code',
                                 hintText: _generateRandomCode ? null : 'e.g., SUMMER2025',
                                 border: const OutlineInputBorder(),
                                 suffixIcon: _generateRandomCode
                                     ? IconButton(
                                         icon: const Icon(Icons.refresh),
                                         onPressed: _generateNewCode,
                                         tooltip: 'Generate new code',
                                       )
                                     : null,
                               ),
                               validator: (value) {
                                 if (value == null || value.isEmpty) {
                                   return 'Please enter a promo code';
                                 }
                                 return null;
                               },
                               inputFormatters: [
                                 FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                 if (!_generateRandomCode)
                                   FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                               ],
                             ),
                             const SizedBox(height: 16),
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
                               controller: _discountValueController,
                               decoration: InputDecoration(
                                 labelText: _discountType == 'Percentage' 
                                     ? 'Discount Percentage (%)' 
                                     : 'Discount Amount (\$)',
                                 border: const OutlineInputBorder(),
                               ),
                               keyboardType: TextInputType.number,
                               validator: (value) {
                                 if (value == null || value.isEmpty) {
                                   return 'Please enter a discount value';
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
                               controller: _usageLimitController,
                               decoration: const InputDecoration(
                                 labelText: 'Usage Limit (Optional)',
                                 hintText: 'Leave empty for unlimited use',
                                 border: OutlineInputBorder(),
                               ),
                               keyboardType: TextInputType.number,
                               validator: (value) {
                                 if (value != null && value.isNotEmpty) {
                                   final int? parsedValue = int.tryParse(value);
                                   if (parsedValue == null || parsedValue <= 0) {
                                     return 'Please enter a valid number';
                                   }
                                 }
                                 return null;
                               },
                             ),
                             const SizedBox(height: 20),
                             SizedBox(
                               width: double.infinity,
                               child: ElevatedButton(
                                 onPressed: _addPromoCode,
                                 style: ElevatedButton.styleFrom(
                                   padding: const EdgeInsets.symmetric(vertical: 15),
                                   backgroundColor: Colors.orange,
                                   foregroundColor: Colors.white,
                                 ),
                                 child: const Text('Add Promo Code'),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                     if (_generatedCodes.isNotEmpty) ...[
                       const SizedBox(height: 20),
                       Card(
                         elevation: 4,
                         child: Padding(
                           padding: const EdgeInsets.all(16.0),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text(
                                 'Generated Promo Codes',
                                 style: TextStyle(
                                   fontSize: 18,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                               const SizedBox(height: 10),
                               ListView.builder(
                                 shrinkWrap: true,
                                 physics: const NeverScrollableScrollPhysics(),
                                 itemCount: _generatedCodes.length,
                                 itemBuilder: (context, index) {
                                   final code = _generatedCodes[index];
                                   return ListTile(
                                     title: Text(code['code']),
                                     subtitle: Text(
                                       '${code['type']}: ${code['value']}${code['type'] == 'Percentage' ? '%' : '\$'} ${code['usageLimit'] != null ? '(Limit: ${code['usageLimit']})' : '(Unlimited)'}',
                                     ),
                                     trailing: IconButton(
                                       icon: const Icon(Icons.delete),
                                       onPressed: () {
                                         setState(() {
                                           _generatedCodes.removeAt(index);
                                         });
                                       },
                                     ),
                                   );
                                 },
                               ),
                             ],
                           ),
                         ),
                       ),
                     ],
                   ],
                 ),
               ),
             ),
             ElevatedButton(
              
                   onPressed: () {
                 // Save all promo codes
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('All promo codes saved successfully!')),
                 );
               },
               style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 15),
                 backgroundColor: Colors.blue,
                 foregroundColor: Colors.white,
               ),
               child: const Text('Save All Promo Codes'),
             ),
           ],
         ),
       ),
     );
   }
 }