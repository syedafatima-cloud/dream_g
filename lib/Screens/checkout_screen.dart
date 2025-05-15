import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_ap/pastel_theme.dart';
import 'package:mobile_ap/screens/order_tracking_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';


class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final String currency;         

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.currency,      
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
        style: GoogleFonts.inter(
          fontSize: 15, 
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
  
  // Gift Media features
  String? _selectedGiftOption;
  File? _selectedImage;
  File? _audioFile;
  String? _audioUrl;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder record = AudioRecorder();
  bool _isRecording = false;
  String? _generatedQrData;
  bool _isQrGenerated = false;
  final AudioPlayer player = AudioPlayer();
  bool _isPlaying = false;
  StreamSubscription<void>? _playerCompleteSubscription;
  
  String? _selectedPaymentMethod;
  bool _sameDayDelivery = false;
  bool _isDiscountApplied = false;
  double _discountAmount = 0.0;
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
  
  // Calculate final total
  double calculateFinalTotal() {
    double total = widget.totalAmount;
    if (_sameDayDelivery) {
      total += _sameDayDeliveryCost;
    }
    if (_isDiscountApplied) {
      total -= _discountAmount;
    }
    return total;
  }
  
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    // Set up player complete listener
    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
  }
  
  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.camera.request();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _messageLinkController.dispose();
    _discountCodeController.dispose();
    _cardMessageController.dispose();
    record.dispose();
    _playerCompleteSubscription?.cancel();
    player.dispose();
    super.dispose();
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
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: PastelTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
  
  // Image picker method
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedGiftOption = 'image';
        _audioFile = null;
        _audioUrl = null;
      });
    }
  }
  
  // Camera method
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _selectedGiftOption = 'image';
        _audioFile = null;
        _audioUrl = null;
      });
    }
  }
  
  // Voice recording methods
  Future<void> _startRecording() async {
    try {
      if (await record.hasPermission()) {
        Directory tempDir = await getTemporaryDirectory();
        String path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        // Start recording with the path
        await record.start(const RecordConfig(), path: path);
        
        setState(() {
          _isRecording = true;
          _selectedGiftOption = 'voice';
          _selectedImage = null;
          _imageUrl = null;
        });
      }
    } catch (e) {
      print('Error recording: $e');
    }
  }
  
  Future<void> _stopRecording() async {
    try {
      String? path = await record.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioFile = File(path);
        }
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }
  
  Future<void> _playRecording() async {
    if (_audioFile != null) {
      try {
        await player.play(DeviceFileSource(_audioFile!.path));
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        print('Error playing audio: $e');
      }
    } else if (_audioUrl != null) {
      try {
        await player.play(UrlSource(_audioUrl!));
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        print('Error playing audio URL: $e');
      }
    }
  }
  
  Future<void> _stopPlaying() async {
    await player.stop();
    setState(() {
      _isPlaying = false;
    });
  }
  
  // Generate QR code for media
  Future<void> _generateQRCode() async {
    if (_selectedGiftOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a gift option first!",
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      );
      return;
    }
    
    try {
      String uniqueId = const Uuid().v4();
      String? mediaUrl;
      
      // For debugging
      print('Selected gift option: $_selectedGiftOption');
      print('Selected image: $_selectedImage');
      print('Audio file: $_audioFile');
      print('Card message: ${_cardMessageController.text}');
      
      // Upload media to Firebase Storage
      if (_selectedGiftOption == 'image' && _selectedImage != null) {
        // Create a simple text URL for testing instead of Firebase upload
        // This avoids Firebase configuration issues
        mediaUrl = 'image_url_$uniqueId';
        setState(() {
          _imageUrl = mediaUrl;
        });
        print('Generated image URL: $mediaUrl');
      } else if (_selectedGiftOption == 'voice' && _audioFile != null) {
        // Create a simple text URL for testing instead of Firebase upload
        // This avoids Firebase configuration issues
        mediaUrl = 'audio_url_$uniqueId';
        setState(() {
          _audioUrl = mediaUrl;
        });
        print('Generated audio URL: $mediaUrl');
      } else if (_selectedGiftOption == 'text' && _cardMessageController.text.isNotEmpty) {
        // For text, we'll just use the message directly
        mediaUrl = _cardMessageController.text;
        print('Using text as URL: $mediaUrl');
      } else {
        // If we get here, there's no valid content for the selected option
        throw Exception('No valid content for the selected gift option');
      }
      
      if (mediaUrl.isNotEmpty) {
        setState(() {
          _generatedQrData = mediaUrl;
          _isQrGenerated = true;
        });
        print('QR code generated with data: $mediaUrl');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "QR code generated successfully!",
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: PastelTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        );
      } else {
        throw Exception('Generated media URL is null or empty');
      }
    } catch (e) {
      print('Error generating QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to generate QR code. Please try again: ${e.toString()}",
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      );
    }
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              backgroundColor: PastelTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          );
          return;
        }

        // Create address data
        final addressData = {
          'name': _nameController.text,
          'address': _addressController.text,
          'city': _selectedCity,
          'phone': _phoneController.text,
        };

        // Save address for future use
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .add(addressData);

        final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(); // Create global order ID

            
        // Prepare gift media data
        Map<String, dynamic> giftMediaData = {};
        if (_selectedGiftOption != null) {
          giftMediaData = {
            'type': _selectedGiftOption,
            'message': _cardMessageController.text,
          };
          
          if (_imageUrl != null) {
            giftMediaData['mediaUrl'] = _imageUrl;
          } else if (_audioUrl != null) {
            giftMediaData['mediaUrl'] = _audioUrl;
          }
          
          if (_isQrGenerated && _generatedQrData != null) {
            giftMediaData['qrCodeData'] = _generatedQrData;
          }
        }

        final orderData = {
        'orderId': orderRef.id,
        'userId': user.uid, // ✅ Add this line
        'orderDate': Timestamp.now(),
        'total': calculateFinalTotal(),
        'currency': widget.currency,
        'paymentMethod': _selectedPaymentMethod,
        'shippingAddress': addressData,
        'items': widget.cartItems,
        'sameDayDelivery': _sameDayDelivery,
        'discountApplied': _isDiscountApplied,
        'discountAmount': _discountAmount,
        'specialMessage': _messageLinkController.text,
        'giftMedia': giftMediaData,
        'status': 'pending',
      };


        await orderRef.set(orderData);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(
              orderId: orderRef.id,
              userId: user.uid,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to place order. Please try again.",
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: PastelTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        );
      }
    } else if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a payment method!",
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: PastelTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      );
    }
  }

  // Modern input decoration with shorter height
  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: PastelTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: PastelTheme.divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: PastelTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: PastelTheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: PastelTheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true, // Makes the field more compact
    );
  }
  
  // Modern unified section card with subtle shadow
  Widget _buildSectionCard({required Widget child, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        color: PastelTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:PastelTheme.cardShadow,
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme();
    
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        primaryTextTheme: textTheme,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Checkout",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
          backgroundColor: PastelTheme.primary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        backgroundColor: PastelTheme.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Main content with padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shipping Details Card
                      Container(
                        decoration: BoxDecoration(
                          color: PastelTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: PastelTheme.cardShadow,
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: PastelTheme.primary.withOpacity(0.1),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.local_shipping_outlined, size: 18, color: PastelTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Shipping Details",
                                    style: GoogleFonts.inter(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.w600,
                                      color: PastelTheme.textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Form fields
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: _getInputDecoration("Full Name"),
                                    style: GoogleFonts.inter(
                                      color: PastelTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                    validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _addressController,
                                    decoration: _getInputDecoration("Address"),
                                    style: GoogleFonts.inter(
                                      color: PastelTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                    validator: (value) => value!.isEmpty ? "Please enter your address" : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    decoration: _getInputDecoration("City"),
                                    value: _selectedCity,
                                    dropdownColor: Colors.white,
                                    icon: Icon(Icons.arrow_drop_down, color: PastelTheme.primary),
                                    style: GoogleFonts.inter(
                                      color: PastelTheme.textPrimary,
                                      fontSize: 14,
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
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: _getInputDecoration("Phone Number"),
                                    style: GoogleFonts.inter(
                                      color: PastelTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                    validator: (value) => value!.isEmpty ? "Please enter your phone number" : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Payment Methods Card
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment, size: 18, color: PastelTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Payment Method",
                                  style: GoogleFonts.inter(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Payment methods
                            Column(
                              children: [
                                _buildPaymentOption(
                                  title: "Cash on Delivery",
                                  value: "cash_on_delivery",
                                  icon: Icons.payments_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildPaymentOption(
                                  title: "Credit/Debit Card",
                                  value: "card",
                                  icon: Icons.credit_card,
                                ),
                                const SizedBox(height: 12),
                                _buildPaymentOption(
                                  title: "Bank Transfer",
                                  value: "bank_transfer",
                                  icon: Icons.account_balance,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Delivery Options Card
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: PastelTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Delivery Options",
                                  style: GoogleFonts.inter(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Same day delivery option
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _sameDayDelivery = !_sameDayDelivery;
                                });
                              },
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: _sameDayDelivery 
                                        ? PastelTheme.primary
                                        : PastelTheme.divider,
                                    width: 1.5,
                                  ),
                                  color: _sameDayDelivery
                                      ? PastelTheme.primary.withOpacity(0.08)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _sameDayDelivery,
                                        onChanged: (value) {
                                          setState(() {
                                            _sameDayDelivery = value!;
                                          });
                                        },
                                        activeColor: PastelTheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Same Day Delivery",
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: PastelTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            "Extra ${widget.currency} ${_sameDayDeliveryCost.toStringAsFixed(0)}",
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: PastelTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Discount Card
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.discount, size: 18, color: PastelTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Discount Code",
                                  style: GoogleFonts.inter(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _discountCodeController,
                                    decoration: _getInputDecoration("Enter discount code"),
                                    enabled: !_isDiscountApplied,
                                    style: GoogleFonts.inter(
                                      color: PastelTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                 const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _isDiscountApplied ? null : _applyDiscount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PastelTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Text(
                                    _isDiscountApplied ? "Applied" : "Apply",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isDiscountApplied)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: PastelTheme.success,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Discount of ${widget.currency} ${_discountAmount.toStringAsFixed(2)} applied",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: PastelTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      // Gift Options Card
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.card_giftcard, size: 18, color: PastelTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Gift Options",
                                  style: GoogleFonts.inter(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Gift card message
                            TextFormField(
                              controller: _cardMessageController,
                              decoration: _getInputDecoration("Gift card message")
                                  .copyWith(hintText: "Write a special message (optional)"),
                              style: GoogleFonts.inter(
                                color: PastelTheme.textPrimary,
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    _selectedGiftOption = 'text';
                                  });
                                }
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Gift media options
                            Text(
                              "Add media to gift card",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: PastelTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Image option
                                _buildMediaOption(
                                  icon: Icons.photo_library_outlined,
                                  label: "Gallery",
                                  isSelected: _selectedGiftOption == 'image' && _selectedImage != null,
                                  onTap: _pickImage,
                                ),
                                
                                // Camera option
                                _buildMediaOption(
                                  icon: Icons.camera_alt_outlined,
                                  label: "Camera",
                                  isSelected: _selectedGiftOption == 'image' && _selectedImage != null,
                                  onTap: _takePhoto,
                                ),
                                
                                // Voice message option
                                _buildMediaOption(
                                  icon: _isRecording ? Icons.mic : Icons.mic_none_outlined,
                                  label: "Voice",
                                  isSelected: _selectedGiftOption == 'voice' && (_audioFile != null || _audioUrl != null),
                                  onTap: _handleRecording,
                                  color: _isRecording ? Colors.red : null,
                                ),
                              ],
                            ),
                            
                            // Preview selected media
                            if (_selectedImage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Selected image:",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: PastelTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImage!,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            // Audio playback controls
                            if (_audioFile != null || _audioUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Voice message:",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: PastelTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: _togglePlayback,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: PastelTheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _isPlaying ? Icons.stop : Icons.play_arrow,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: PastelTheme.primary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: FractionallySizedBox(
                                              widthFactor: _isPlaying ? 0.5 : 0, // This would be dynamic in a real app
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: PastelTheme.primary,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                            // Generate QR code button
                            if (_selectedGiftOption != null && 
                                ((_selectedGiftOption == 'image' && _selectedImage != null) || 
                                 (_selectedGiftOption == 'voice' && _audioFile != null) ||
                                 (_selectedGiftOption == 'text' && _cardMessageController.text.isNotEmpty)))
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _isQrGenerated ? null : _generateQRCode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: PastelTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    icon: Icon(Icons.qr_code, size: 18),
                                    label: Text(
                                      _isQrGenerated ? "QR Code Generated" : "Generate QR Code",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                            // Display generated QR code
                            if (_isQrGenerated && _generatedQrData != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: PastelTheme.cardShadow,
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: QrImageView(
                                          data: _generatedQrData!,
                                          version: QrVersions.auto,
                                          size: 180,
                                          backgroundColor: Colors.white,
                                          foregroundColor: PastelTheme.accent,
                                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Scan to view gift media",
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: PastelTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Special Message Link Card
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.link, size: 18, color: PastelTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Special Message Link",
                                  style: GoogleFonts.inter(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _messageLinkController,
                              decoration: _getInputDecoration("Add a video or message link (optional)")
                                  .copyWith(hintText: "YouTube, Instagram, etc."),
                              style: GoogleFonts.inter(
                                color: PastelTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Order Summary Card
                      _buildSectionCard(
                        isLast: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, size: 18, color: PastelTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Order Summary",
                                  style: GoogleFonts.inter(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Order items list
                            ...widget.cartItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${item['quantity']}x ${item['name']}",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: PastelTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${widget.currency} ${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PastelTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            
                            Divider(color: PastelTheme.divider, height: 24),
                            
                            // Subtotal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Subtotal",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: PastelTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  "${widget.currency} ${widget.totalAmount.toStringAsFixed(2)}",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: PastelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Same day delivery charge if applicable
                            if (_sameDayDelivery)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Same Day Delivery",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: PastelTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      "+ ${widget.currency} ${_sameDayDeliveryCost.toStringAsFixed(2)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: PastelTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            // Discount if applicable
                            if (_isDiscountApplied)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Discount",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: PastelTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      "- ${widget.currency} ${_discountAmount.toStringAsFixed(2)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: PastelTheme.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            const SizedBox(height: 12),
                            
                            // Total
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PastelTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: PastelTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "${widget.currency} ${calculateFinalTotal().toStringAsFixed(2)}",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: PastelTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Place Order Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _placeOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PastelTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  "Place Order",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  
  // Helper method to build payment option
  Widget _buildPaymentOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    bool isSelected = _selectedPaymentMethod == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? PastelTheme.primary : PastelTheme.divider,
            width: 1.5,
          ),
          color: isSelected ? PastelTheme.primary.withOpacity(0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? PastelTheme.primary : PastelTheme.divider,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PastelTheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: PastelTheme.textPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PastelTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method for recording audio
  Future<void> _handleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  // Helper method for playing/stopping audio
  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _stopPlaying();
    } else {
      await _playRecording();
    }
  }

  // Helper method to build media option
  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? PastelTheme.primary.withOpacity(0.1)
              : PastelTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? PastelTheme.primary : PastelTheme.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: PastelTheme.cardShadow,
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color ?? (isSelected ? PastelTheme.primary : PastelTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? PastelTheme.primary : PastelTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}