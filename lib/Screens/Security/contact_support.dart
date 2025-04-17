import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'C O N T A C T   U S',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
        backgroundColor: Colors.grey[100],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SupportCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'For technical support, account issues, or general queries, please contact us at:',
            detail: 'atharvsutar3102003@gmail.com',
          ),
          SizedBox(height: 16),
          SupportCard(
            icon: Icons.access_time_outlined,
            title: 'Support Hours',
            subtitle:
            'Monday to Friday: 9:00 AM – 9:00 PM\nSaturday: 10:00 AM – 2:00 PM\nSunday & Holidays: Closed',
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? detail;

  const SupportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 15, fontFamily: 'Outfit'),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
