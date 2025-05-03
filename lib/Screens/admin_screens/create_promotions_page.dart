import 'package:flutter/material.dart';
 
 class CreatePromotionsPage extends StatelessWidget {
   const CreatePromotionsPage({super.key});
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Create Promotions'),
         centerTitle: true,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () => Navigator.pop(context),
         ),
       ),
       body: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             const Text(
               'Select Promotion Type',
               style: TextStyle(
                 fontSize: 18,
                 fontWeight: FontWeight.bold,
               ),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 30),
             Expanded(
               child: GridView.count(
                 crossAxisCount: 2,
                 crossAxisSpacing: 15,
                 mainAxisSpacing: 15,
                 children: [
                   _buildPromotionTypeButton(
                     context,
                     'Discount',
                     Icons.discount,
                     '/discount',
                     Colors.purple,
                   ),
                   _buildPromotionTypeButton(
                     context,
                     'Free Shipping',
                     Icons.local_shipping,
                     '/freeShipping',
                     Colors.green,
                   ),
                   _buildPromotionTypeButton(
                     context,
                     'Promo Codes',
                     Icons.confirmation_number,
                     '/promoCodes',
                     Colors.orange,
                   ),
                   _buildPromotionTypeButton(
                     context,
                     'Validity Period',
                     Icons.timer,
                     '/validityPeriod',
                     Colors.blue,
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
     );
   }
 
   Widget _buildPromotionTypeButton(
     BuildContext context,
     String title,
     IconData icon,
     String routeName,
     Color color,
   ) {
     return InkWell(
       onTap: () => Navigator.pushNamed(context, routeName),
       child: Container(
         decoration: BoxDecoration(
           color: color,
           borderRadius: BorderRadius.circular(10),
           boxShadow: [
             BoxShadow(
               color: Colors.grey.withOpacity(0.3),
               spreadRadius: 1,
               blurRadius: 5,
               offset: const Offset(0, 3),
             ),
           ],
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               icon,
               size: 50,
               color: Colors.white,
             ),
             const SizedBox(height: 10),
             Text(
               title,
               style: const TextStyle(
                 color: Colors.white,
                 fontWeight: FontWeight.bold,
                 fontSize: 16,
               ),
               textAlign: TextAlign.center,
             ),
           ],
         ),
       ),
     );
   }
 }