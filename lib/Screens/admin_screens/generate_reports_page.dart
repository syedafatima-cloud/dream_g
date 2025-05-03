import 'package:flutter/material.dart';
 import 'package:intl/intl.dart';
 
 class GenerateReportsPage extends StatefulWidget {
   const GenerateReportsPage({super.key});
 
   @override
   GenerateReportsPageState createState() => GenerateReportsPageState();
 }
 
 class GenerateReportsPageState extends State<GenerateReportsPage> {
   final _formKey = GlobalKey<FormState>();
   DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
   DateTime _endDate = DateTime.now();
   String _reportType = 'Sales';
   bool _isGenerating = false;
   bool _reportGenerated = false;
   
   final List<String> _reportTypes = ['Sales', 'Inventory', 'Orders', 'Products'];
   
   // Mock data for reports
   final Map<String, List<Map<String, dynamic>>> _reportData = {
     'Sales': [
       {'date': '2025-04-20', 'amount': 1250.00, 'orders': 15},
       {'date': '2025-04-21', 'amount': 980.50, 'orders': 12},
       {'date': '2025-04-22', 'amount': 1450.75, 'orders': 18},
       {'date': '2025-04-23', 'amount': 875.25, 'orders': 10},
       {'date': '2025-04-24', 'amount': 1560.00, 'orders': 20},
     ],
     'Inventory': [
       {'product': 'Red Roses Bouquet', 'stock': 25, 'reorder_level': 10},
       {'product': 'Birthday Gift Box', 'stock': 15, 'reorder_level': 8},
       {'product': 'Anniversary Special', 'stock': 8, 'reorder_level': 5},
       {'product': 'Chocolate Hamper', 'stock': 12, 'reorder_level': 7},
       {'product': 'Mixed Flowers Vase', 'stock': 18, 'reorder_level': 8},
     ],
   };
 
   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
     final DateTime? picked = await showDatePicker(
       context: context,
       initialDate: isStartDate ? _startDate : _endDate,
       firstDate: DateTime(2020),
       lastDate: DateTime.now(),
     );
     if (picked != null) {
       setState(() {
         if (isStartDate) {
           _startDate = picked;
           // Ensure end date is not before start date
           if (_endDate.isBefore(_startDate)) {
             _endDate = _startDate;
           }
         } else {
           _endDate = picked;
         }
       });
     }
   }
 
   void _generateReport() {
     if (_formKey.currentState!.validate()) {
       setState(() {
         _isGenerating = true;
       });
       
       // Simulate report generation
       Future.delayed(const Duration(seconds: 2), () {
         setState(() {
           _isGenerating = false;
           _reportGenerated = true;
         });
       });
     }
   }
 
   Widget _buildReportContent() {
     if (_reportType == 'Sales') {
       return Column(
         children: [
           const Padding(
             padding: EdgeInsets.symmetric(vertical: 16.0),
             child: Text(
               'Sales Report',
               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
             ),
           ),
           Container(
             padding: const EdgeInsets.all(16.0),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(8.0),
               boxShadow: [
                 BoxShadow(
                   color: Colors.grey..withValues(alpha: 20),
                   spreadRadius: 1,
                   blurRadius: 3,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(
                   'Date Range:',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 Text(
                   '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   'Summary:',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 8),
                 _buildSalesTable(),
                 const SizedBox(height: 24),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     ElevatedButton.icon(
                       onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Report downloaded successfully')),
                         );
                       },
                       icon: const Icon(Icons.download),
                       label: const Text('Download PDF'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.green,
                         foregroundColor: Colors.white,
                       ),
                     ),
                     const SizedBox(width: 16),
                     ElevatedButton.icon(
                       onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Report sent by email')),
                         );
                       },
                       icon: const Icon(Icons.email),
                       label: const Text('Email Report'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blue,
                         foregroundColor: Colors.white,
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ],
       );
     } else if (_reportType == 'Inventory') {
       return Column(
         children: [
           const Padding(
             padding: EdgeInsets.symmetric(vertical: 16.0),
             child: Text(
               'Inventory Report',
               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
             ),
           ),
           Container(
             padding: const EdgeInsets.all(16.0),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(8.0),
               boxShadow: [
                 BoxShadow(
                   color: Colors.grey.withOpacity(0.3),
                   spreadRadius: 1,
                   blurRadius: 3,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(
                   'Current Inventory Status:',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 8),
                 _buildInventoryTable(),
                 const SizedBox(height: 24),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     ElevatedButton.icon(
                       onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Inventory report downloaded')),
                         );
                       },
                       icon: const Icon(Icons.download),
                       label: const Text('Download PDF'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.green,
                         foregroundColor: Colors.white,
                       ),
                     ),
                     const SizedBox(width: 16),
                     ElevatedButton.icon(
                       onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Inventory report sent by email')),
                         );
                       },
                       icon: const Icon(Icons.email),
                       label: const Text('Email Report'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blue,
                         foregroundColor: Colors.white,
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ],
       );
     } else {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text(
             '$_reportType report generation is not implemented yet.',
             style: const TextStyle(fontSize: 16),
           ),
         ),
       );
     }
   }
 
   Widget _buildSalesTable() {
     return SingleChildScrollView(
       scrollDirection: Axis.horizontal,
       child: DataTable(
         columns: const [
           DataColumn(label: Text('Date')),
           DataColumn(label: Text('Amount (USD)')),
           DataColumn(label: Text('Orders')),
         ],
         rows: _reportData['Sales']!.map((item) {
           return DataRow(
             cells: [
               DataCell(Text(item['date'])),
               DataCell(Text('\$${item['amount'].toStringAsFixed(2)}')),
               DataCell(Text('${item['orders']}')),
             ],
           );
         }).toList(),
       ),
     );
   }
 
   Widget _buildInventoryTable() {
     return SingleChildScrollView(
       scrollDirection: Axis.horizontal,
       child: DataTable(
         columns: const [
           DataColumn(label: Text('Product')),
           DataColumn(label: Text('Current Stock')),
           DataColumn(label: Text('Reorder Level')),
           DataColumn(label: Text('Status')),
         ],
         rows: _reportData['Inventory']!.map((item) {
           String status = item['stock'] <= item['reorder_level'] 
               ? 'Low Stock' 
               : 'In Stock';
           Color statusColor = item['stock'] <= item['reorder_level']
               ? Colors.red
               : Colors.green;
           
           return DataRow(
             cells: [
               DataCell(Text(item['product'])),
               DataCell(Text('${item['stock']}')),
               DataCell(Text('${item['reorder_level']}')),
               DataCell(
                 Text(
                   status,
                   style: TextStyle(
                     color: statusColor,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
             ],
           );
         }).toList(),
       ),
     );
   }
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Generate Reports'),
         backgroundColor: Colors.blue,
         foregroundColor: Colors.white,
         elevation: 0,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () => Navigator.pop(context),
         ),
       ),
       body: SingleChildScrollView(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Form(
               key: _formKey,
               child: Card(
                 elevation: 4,
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Report Parameters',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 16),
                       Row(
                         children: [
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Text('Start Date:'),
                                 const SizedBox(height: 8),
                                 InkWell(
                                   onTap: () => _selectDate(context, true),
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 12,
                                       vertical: 12,
                                     ),
                                     decoration: BoxDecoration(
                                       border: Border.all(color: Colors.grey),
                                       borderRadius: BorderRadius.circular(4),
                                     ),
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           DateFormat('MMM dd, yyyy').format(_startDate),
                                         ),
                                         const Icon(Icons.calendar_today, size: 16),
                                       ],
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Text('End Date:'),
                                 const SizedBox(height: 8),
                                 InkWell(
                                   onTap: () => _selectDate(context, false),
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 12,
                                       vertical: 12,
                                     ),
                                     decoration: BoxDecoration(
                                       border: Border.all(color: Colors.grey),
                                       borderRadius: BorderRadius.circular(4),
                                     ),
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           DateFormat('MMM dd, yyyy').format(_endDate),
                                         ),
                                         const Icon(Icons.calendar_today, size: 16),
                                       ],
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Report Type:'),
                           const SizedBox(height: 8),
                           DropdownButtonFormField<String>(
                             value: _reportType,
                             decoration: InputDecoration(
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               contentPadding: const EdgeInsets.symmetric(
                                 horizontal: 12,
                                 vertical: 12,
                               ),
                             ),
                             items: _reportTypes.map((String type) {
                               return DropdownMenuItem<String>(
                                 value: type,
                                 child: Text(type),
                               );
                             }).toList(),
                             onChanged: (String? newValue) {
                               if (newValue != null) {
                                 setState(() {
                                   _reportType = newValue;
                                   _reportGenerated = false;
                                 });
                               }
                             },
                             validator: (value) {
                               if (value == null || value.isEmpty) {
                                 return 'Please select a report type';
                               }
                               return null;
                             },
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),
                       Center(
                         child: ElevatedButton(
                           onPressed: _isGenerating ? null : _generateReport,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.blue,
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(
                               horizontal: 32,
                               vertical: 12,
                             ),
                           ),
                           child: _isGenerating
                               ? const Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     SizedBox(
                                       width: 16,
                                       height: 16,
                                       child: CircularProgressIndicator(
                                         color: Colors.white,
                                         strokeWidth: 2,
                                       ),
                                     ),
                                     SizedBox(width: 8),
                                     Text('Generating...'),
                                   ],
                                 )
                               : const Text('Generate Report'),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
             if (_reportGenerated) _buildReportContent(),
           ],
         ),
       ),
     );
   }
 }