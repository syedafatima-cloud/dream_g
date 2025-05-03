import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Pastel theme colors (kept the same)
class PastelTheme {
  static const Color primary = Color.fromARGB(255, 197, 157, 216); // Soft blue
  static const Color secondary = Color(0xFFFFC8DD); // Soft pink
  static const Color accent = Color.fromARGB(255, 75, 77, 68); // Light blue
  static const Color background = Color(0xFFF8EDEB); // Soft cream
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF445566); // Darker blue-gray (adjusted for professionalism)
  static const Color textSecondary = Color(0xFF7A8999); // Medium blue-gray (adjusted for professionalism)
  static const Color success = Color(0xFFABD8C6); // Mint green
  static const Color error = Color(0xFFFFADAD); // Soft red
}

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final String currency;         
  final double exchangeRate; 

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.currency,      
    required this.exchangeRate,   
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class CheckoutSectionTitle extends StatelessWidget {
  final String title;
  
  const CheckoutSectionTitle({super.key, required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 19, 
          fontWeight: FontWeight.w600,
          color: PastelTheme.textPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageLinkController = TextEditingController();
  final TextEditingController _discountCodeController = TextEditingController();
  final TextEditingController _cardMessageController = TextEditingController();

  String? _generatedQRData;
  String? _selectedPaymentMethod;
  bool _sameDayDelivery = false;
  bool _isDiscountApplied = false;
  double _discountAmount = 0.0;

  final TextEditingController _cityController = TextEditingController();
String? _selectedCity;

// List of Pakistani cities for dropdown
final List<String> _pakistaniCities = [
  'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad', 
  'Multan', 'Peshawar', 'Quetta', 'Sialkot', 'Gujranwala',
  'Hyderabad', 'Abbottabad', 'Bahawalpur', 'Sargodha', 'Sukkur',
  'Larkana', 'Sheikhupura', 'Rahim Yar Khan', 'Jhang', 'Gujrat'
];
  // Define costs
  final double _sameDayDeliveryCost = 500;
  
  double _convertCurrency(double amount) {
    return widget.currency == 'PKR' ? amount * widget.exchangeRate : amount;
  }

  void _applyDiscount() {
    String code = _discountCodeController.text.trim();
    if (code.isNotEmpty) {
      // For this example, we'll accept any code and give 10% off
      setState(() {
        _discountAmount = widget.totalAmount * 0.1; // 10% discount
        _isDiscountApplied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Discount applied successfully!",
            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: PastelTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    }
  }

  double get _finalTotal {
    double total = widget.totalAmount;
    if (_sameDayDelivery) {
      total += _sameDayDeliveryCost;
    }
    if (_isDiscountApplied) {
      total -= _discountAmount;
    }
    return total;
  }

  void _placeOrder() async {
  if (_formKey.currentState!.validate() && _selectedPaymentMethod != null) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "User not logged in!",
              style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: PastelTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        );
        return;
      }

      // Save the address to Firebase
      final addressData = {
        'fullName': _nameController.text,
        'address': _addressController.text,
        'city': _selectedCity,
        'phoneNumber': _phoneController.text,
        'timestamp': Timestamp.now(),
      };

      // Save address to user's addresses collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add(addressData);

      // Create order data
      final orderData = {
        'orderDate': Timestamp.now(),
        'total': _finalTotal,
        'currency': widget.currency,
        'exchangeRate': widget.exchangeRate,
        'paymentMethod': _selectedPaymentMethod,
        'shippingAddress': addressData,
        'sameDayDelivery': _sameDayDelivery,
        'items': widget.cartItems.map((item) => {
          'name': item['name'],
          'quantity': item['quantity'],
          'price': item['price'],
        }).toList(),
      };

      // Save order to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Order placed successfully!",
            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: PastelTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );

      // Optional: Clear form or go to home
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to place order. Please try again.",
            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    }
  } else if (_selectedPaymentMethod == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Please select a payment method!",
          style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),
        ),
        backgroundColor: PastelTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}



  // Custom input decoration
  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.nunitoSans(
        color: PastelTheme.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: PastelTheme.accent.withOpacity(0.4), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: PastelTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: PastelTheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: PastelTheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.nunitoSansTextTheme();
    
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        primaryTextTheme: textTheme,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Checkout",
            style: GoogleFonts.nunitoSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
          backgroundColor: PastelTheme.primary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
        ),
        backgroundColor: PastelTheme.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CheckoutSectionTitle(title: "Shipping Details"),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: _getInputDecoration("Full Name"),
                        style: GoogleFonts.nunitoSans(
                          color: PastelTheme.textPrimary,
                          fontSize: 15,
                        ),
                        validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressController,
                        decoration: _getInputDecoration("Address"),
                        style: GoogleFonts.nunitoSans(
                          color: PastelTheme.textPrimary,
                          fontSize: 15,
                        ),
                        validator: (value) => value!.isEmpty ? "Please enter your address" : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: _getInputDecoration("City"),
                        value: _selectedCity,
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: PastelTheme.primary),
                        style: GoogleFonts.nunitoSans(
                          color: PastelTheme.textPrimary,
                          fontSize: 15,
                        ),
                        items: _pakistaniCities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                        validator: (value) => value == null ? "Please select a city" : null,
                      ),
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _getInputDecoration("Phone Number"),
                        style: GoogleFonts.nunitoSans(
                          color: PastelTheme.textPrimary,
                          fontSize: 15,
                        ),
                        validator: (value) => value!.isEmpty ? "Please enter your phone number" : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CheckoutSectionTitle(title: "Your Items"),
                      const SizedBox(height: 15),
                      
                      // Displaying Cart Items in ListView
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.cartItems.length,
                        itemBuilder: (context, index) {
                          var item = widget.cartItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: PastelTheme.accent.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item['imageUrl'], 
                                  width: 60, 
                                  height: 60, 
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                item['name'], 
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.w600,
                                  color: PastelTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                "${widget.currency == 'PKR' ? 'PKR' : '\$'}${_convertCurrency(item['price'])} × ${item['quantity']}",
                                style: GoogleFonts.nunitoSans(
                                  color: PastelTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Text(
                                "${widget.currency == 'PKR' ? 'PKR' : '\$'}${_convertCurrency(item['price'] * item['quantity']).toStringAsFixed(2)}",
                                style: GoogleFonts.nunitoSans(
                                  fontWeight: FontWeight.w600,
                                  color: PastelTheme.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CheckoutSectionTitle(title: "Add Special Message (optional)"),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _messageLinkController,
                        decoration: _getInputDecoration("Paste link to your video/voice message"),
                        style: GoogleFonts.nunitoSans(
                          color: PastelTheme.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _generatedQRData = _messageLinkController.text.trim();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PastelTheme.secondary,
                            foregroundColor: PastelTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Generate QR Code",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 15, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_generatedQRData != null && _generatedQRData!.isNotEmpty)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: PastelTheme.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: PastelTheme.accent.withOpacity(0.3), width: 1),
                            ),
                            child: QrImageView(
                              data: _generatedQRData!,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: PastelTheme.primary,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: PastelTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CheckoutSectionTitle(title: "Select Payment Method"),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        decoration: _getInputDecoration("Payment Method"),
                        value: _selectedPaymentMethod,
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: PastelTheme.primary),
                        style: GoogleFonts.nunitoSans(
                          color: PastelTheme.textPrimary,
                          fontSize: 15,
                        ),
                        items: [
                          'Cash on Delivery',
                          'Credit/Debit Card',
                          'Easypaisa/JazzCash',
                        ].map((method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        },
                        validator: (value) => value == null ? "Please select a payment method" : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Same Day Delivery Option
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: _sameDayDelivery ? PastelTheme.accent.withOpacity(0.2) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: PastelTheme.accent.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Same Day Delivery",
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "PKR 500",
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: 14, 
                                    color: PastelTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _sameDayDelivery,
                              onChanged: (value) {
                                setState(() {
                                  _sameDayDelivery = value;
                                });
                              },
                              activeColor: PastelTheme.primary,
                              activeTrackColor: PastelTheme.accent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const CheckoutSectionTitle(title: "Add Discount Code (Optional)"),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _discountCodeController,
                              decoration: _getInputDecoration("Enter Discount Code"),
                              style: GoogleFonts.nunitoSans(
                                color: PastelTheme.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _applyDiscount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PastelTheme.secondary,
                              foregroundColor: PastelTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Apply",
                              style: GoogleFonts.nunitoSans(
                                fontSize: 15, 
                                fontWeight: FontWeight.w600,
                                color: PastelTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_isDiscountApplied)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: PastelTheme.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: PastelTheme.success),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: PastelTheme.success, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "10% discount applied!",
                                  style: GoogleFonts.nunitoSans(
                                    color: PastelTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PastelTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PastelTheme.primary.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Summary",
                        style: GoogleFonts.nunitoSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: PastelTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Subtotal:",
                            style: GoogleFonts.nunitoSans(
                              color: PastelTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "PKR ${(widget.totalAmount).toStringAsFixed(0)}",
                            style: GoogleFonts.nunitoSans(
                              color: PastelTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (_sameDayDelivery) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Same Day Delivery:",
                              style: GoogleFonts.nunitoSans(
                                color: PastelTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "PKR ${_sameDayDeliveryCost.toStringAsFixed(0)}",
                              style: GoogleFonts.nunitoSans(
                                color: PastelTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (_isDiscountApplied) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Discount (10%):",
                              style: GoogleFonts.nunitoSans(
                                color: PastelTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "- PKR ${_convertCurrency(_discountAmount).toStringAsFixed(0)}",
                              style: GoogleFonts.nunitoSans(
                                color: PastelTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      const Divider(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Amount:",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              color: PastelTheme.textPrimary,
                            ),
                          ),
                          Text(
                            "PKR ${_finalTotal.toStringAsFixed(0)}",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              color: PastelTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PastelTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      "Place Order",
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PastelTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}