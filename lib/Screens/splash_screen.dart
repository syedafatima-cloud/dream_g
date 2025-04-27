import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_ap/screens/login_page.dart';
import 'package:mobile_ap/screens/signup.dart';
import 'package:mobile_ap/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Check if user is logged in
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff9eb3), Color(0xFFffd69e)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SVG Logo
            SvgPicture.asset(
              "assets/logo.svg",
              width: 150,
            ),
            const SizedBox(height: 50),
            
            // Conditional content based on login status
            if (_isLoggedIn) ...[
              // Home Button for logged in users
              _buildButton(context, "Go to Home", Colors.purpleAccent, const HomeScreen()),
            ] else ...[
              // Login Button
              _buildButton(context, "Login", Colors.pinkAccent, const LoginPage()),
              
              const SizedBox(height: 15),
              
              // Register Button
              _buildButton(context, "Register", Colors.orangeAccent, const Signup()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color color, Widget page) {
    return SizedBox(
      width: 250, // Fixed width for consistency
      height: 50,  // Fixed height for better look
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}