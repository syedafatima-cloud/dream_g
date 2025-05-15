import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_ap/screens/addresses_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Adjust route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: PastelTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.person,
            title: "Profile",
            onTap: () {
              // Navigate to profile screen
              Navigator.pushNamed(context, '/profile');
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: "Notifications",
            onTap: () {
              // Navigate to notifications settings
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          _buildSettingItem(
            icon: Icons.language,
            title: "Language",
            onTap: () {
              // Language change logic
            },
          ),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {
              // Navigate to help page
              Navigator.pushNamed(context, '/help');
            },
          ),
          _buildSettingItem(
            icon: Icons.logout,
            title: "Logout",
            onTap: () => _logout(context),
            iconColor: Colors.red,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
