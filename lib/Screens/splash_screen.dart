import 'package:flutter/material.dart';
import 'package:mobile_ap/Screens/login_page.dart';
import 'package:mobile_ap/Screens/signup.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
            const SizedBox(height: 30),
            _buildButton(context, "Login", Colors.pinkAccent, const LoginPage()),
            const SizedBox(height: 15),
            _buildButton(context, "Register", Colors.orangeAccent, const Signup()),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconButton(Icons.g_translate),
                const SizedBox(width: 20),
                _buildIconButton(Icons.facebook),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color color, Widget page) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
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
        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return IconButton(
      onPressed: () {}, // Implement authentication logic
      icon: Icon(icon, size: 40, color: Colors.white),
    );
  }
}
