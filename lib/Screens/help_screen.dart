import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      query: 'subject=Help Needed',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+1234567890',
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _openChat(BuildContext context) {
    // Replace with your chat screen navigation if available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat support coming soon...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 243, 177, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 🔄 Firestore FAQ Loader
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('help_faqs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No FAQs found.");
                }

                final faqs = snapshot.data!.docs;

                return Column(
                  children: faqs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ExpansionTile(
                      title: Text(data['question'] ?? 'No question'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(data['answer'] ?? 'No answer'),
                        )
                      ],
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Need More Help?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.email),
              label: const Text("Email Support"),
              onPressed: _launchEmail,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade200),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text("Call Support"),
              onPressed: _launchPhone,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade200),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text("Live Chat"),
              onPressed: () => _openChat(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade200),
            ),
          ],
        ),
      ),
    );
  }
}
