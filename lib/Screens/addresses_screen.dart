import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Pastel theme colors
class PastelTheme {
  static const Color primary = Color.fromARGB(255, 197, 157, 216); // Soft blue
  static const Color secondary = Color(0xFFFFC8DD); // Soft pink
  static const Color accent = Color.fromARGB(255, 75, 77, 68); // Light blue
  static const Color background = Color(0xFFF8EDEB); // Soft cream
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF445566); // Darker blue-gray
  static const Color textSecondary = Color(0xFF7A8999); // Medium blue-gray
  static const Color success = Color(0xFFABD8C6); // Mint green
  static const Color error = Color(0xFFFFADAD); // Soft red
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  _AddressesScreenState createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> _getUserAddresses() {
    final user = _auth.currentUser;
    if (user == null) {
      // Return an empty stream if user not logged in
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'fullName': data['fullName'] ?? '',
                'address': data['address'] ?? '',
                'city': data['city'] ?? '',
                'phoneNumber': data['phoneNumber'] ?? '',
              };
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PastelTheme.background,
      appBar: AppBar(
        backgroundColor: PastelTheme.primary,
        elevation: 0,
        title: Text(
          'Your Addresses',
          style: GoogleFonts.nunitoSans(
            textStyle: TextStyle(
              color: PastelTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: PastelTheme.textPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getUserAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PastelTheme.primary),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.nunitoSans(
                  textStyle: TextStyle(
                    color: PastelTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: PastelTheme.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No addresses found',
                    style: GoogleFonts.nunitoSans(
                      textStyle: TextStyle(
                        color: PastelTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add a new address to get started',
                    style: GoogleFonts.nunitoSans(
                      textStyle: TextStyle(
                        color: PastelTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final addresses = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final addr = addresses[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: PastelTheme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: PastelTheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.home_outlined,
                              color: PastelTheme.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr['fullName'],
                                  style: GoogleFonts.nunitoSans(
                                    textStyle: TextStyle(
                                      color: PastelTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  addr['address'],
                                  style: GoogleFonts.nunitoSans(
                                    textStyle: TextStyle(
                                      color: PastelTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${addr['city']} • ${addr['phoneNumber']}',
                                  style: GoogleFonts.nunitoSans(
                                    textStyle: TextStyle(
                                      color: PastelTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PastelTheme.primary,
        child: Icon(
          Icons.add,
          color: PastelTheme.cardColor,
        ),
        onPressed: () {
          // Navigation for adding new address
          // You can implement this functionality
        },
      ),
    );
  }
}