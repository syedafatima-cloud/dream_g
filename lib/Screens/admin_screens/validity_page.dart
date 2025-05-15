import 'package:flutter/material.dart';
import 'package:mobile_ap/pastel_theme.dart';
 
 class ValidityPeriodPage extends StatefulWidget {
   const ValidityPeriodPage({super.key});
 
   @override
   State<ValidityPeriodPage> createState() => _ValidityPeriodPageState();
 }
 
 class _ValidityPeriodPageState extends State<ValidityPeriodPage> {
   final _formKey = GlobalKey<FormState>();
   
   // Dates
   DateTime _startDate = DateTime.now();
   DateTime _endDate = DateTime.now().add(const Duration(days: 30));
   TimeOfDay _startTime = TimeOfDay.now();
   TimeOfDay _endTime = TimeOfDay.now().add(minutes: 30);
   
   // Validity settings
   bool _enableTimeRestriction = false;
   final List<bool> _selectedDays = List.filled(7, true); // Sun-Sat
   final List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
   
   // Apply to promotions
   final List<String> _selectedPromotions = [];
   final List<String> _availablePromotions = [
     'Summer Sale 2025', 
     'Back to School', 
     'Valentine\'s Day', 
     'Mother\'s Day Special',
     'New Year\'s Bundle'
   ];
 
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
 
   Future<void> _selectTime(BuildContext context, bool isStartTime) async {
     final TimeOfDay? picked = await showTimePicker(
       context: context,
       initialTime: isStartTime ? _startTime : _endTime,
     );
     if (picked != null) {
       setState(() {
         if (isStartTime) {
           _startTime = picked;
         } else {
           _endTime = picked;
         }
       });
     }
   }
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Validity Period'),
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
                         'Date Range',
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
                         onTap: () => _selectDate(context, true),
                       ),
                       ListTile(
                         title: const Text('End Date'),
                         subtitle: Text(
                           '${_endDate.toLocal()}'.split(' ')[0],
                           style: const TextStyle(fontSize: 16),
                         ),
                         trailing: const Icon(Icons.calendar_today),
                         onTap: () => _selectDate(context, false),
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
                         'Time Restrictions',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 10),
                       SwitchListTile(
                         title: const Text('Enable Time Restrictions'),
                         value: _enableTimeRestriction,
                         onChanged: (value) {
                           setState(() {
                             _enableTimeRestriction = value;
                           });
                         },
                       ),
                       if (_enableTimeRestriction) ...[
                         const SizedBox(height: 10),
                         ListTile(
                           title: const Text('Start Time'),
                           subtitle: Text(_startTime.format(context)),
                           trailing: const Icon(Icons.access_time),
                           onTap: () => _selectTime(context, true),
                         ),
                         ListTile(
                           title: const Text('End Time'),
                           subtitle: Text(_endTime.format(context)),
                           trailing: const Icon(Icons.access_time),
                           onTap: () => _selectTime(context, false),
                         ),
                         const SizedBox(height: 16),
                         const Text(
                           'Active Days',
                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 8),
                         Wrap(
                           spacing: 8.0,
                           children: List.generate(7, (index) {
                             return ChoiceChip(
                               label: Text(_weekdays[index]),
                               selected: _selectedDays[index],
                               onSelected: (selected) {
                                 setState(() {
                                   _selectedDays[index] = selected;
                                 });
                               },
                             );
                           }),
                         ),
                       ],
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
                         'Apply To Promotions',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 10),
                       const Text('Select promotional campaigns:'),
                       const SizedBox(height: 5),
                       ..._availablePromotions.map((promo) {
                         return CheckboxListTile(
                           title: Text(promo),
                           value: _selectedPromotions.contains(promo),
                           onChanged: (checked) {
                             setState(() {
                               if (checked!) {
                                 _selectedPromotions.add(promo);
                               } else {
                                 _selectedPromotions.remove(promo);
                               }
                             });
                           },
                         );
                       }),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 20),
               ElevatedButton(
                 onPressed: () {
                   if (_formKey.currentState!.validate()) {
                     // Save the validity settings
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Validity period saved successfully!')),
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
                 child: const Text('Save Validity Settings'),
               ),
             ],
           ),
         ),
       ),
     );
   }
 }
 
 // Extension to add minutes to TimeOfDay
 extension TimeOfDayExtension on TimeOfDay {
   TimeOfDay add({int minutes = 0}) {
     final totalMinutes = hour * 60 + minute + minutes;
     final newHour = (totalMinutes ~/ 60) % 24;
     final newMinute = totalMinutes % 60;
     return TimeOfDay(hour: newHour, minute: newMinute);
   }
 }