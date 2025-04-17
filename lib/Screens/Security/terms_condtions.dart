import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'T E R M S  &  C O N D I T I O N S',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to StudySync, a smart academic management solution designed for students, teachers, and educational institutions to streamline attendance, assessments, and communication.\n\n'
                  'Please read these Terms and Conditions carefully before using the StudySync mobile application or web portal. By accessing or using any part of the platform, you agree to be bound by these terms.\n',
              style: TextStyle(fontSize: 16, fontFamily: 'Outfit'),
            ),
            SizedBox(height: 12),
            SectionTitle(title: '1. User Eligibility'),
            BulletPoint(text: 'Only registered students, faculty, and authorized administrative personnel are allowed to access StudySync.'),
            BulletPoint(text: 'Users must provide accurate and complete personal and academic details during registration.'),

            SectionTitle(title: '2. Data Collection and Usage'),
            BulletPoint(text: 'StudySync collects and stores personal data such as name, roll number, photographs, facial data (for recognition) and academic performance.'),
            BulletPoint(text: 'The data collected will only be used for educational and administrative purposes and will not be shared with third parties without consent.'),

            SectionTitle(title: '3. Attendance System'),
            BulletPoint(text: 'Attendance is marked via QR code scanning and/or facial recognition.'),
            BulletPoint(text: 'Proxy attendance through misuse or image manipulation is prohibited and may lead to disciplinary action.'),

            SectionTitle(title: '4. User Responsibilities'),
            BulletPoint(text: 'Users must not attempt to reverse-engineer, tamper with, or bypass the system in any way.'),
            BulletPoint(text: 'Teachers are responsible for verifying attendance and maintaining the integrity of academic data.'),
            BulletPoint(text: 'Students are responsible for checking their attendance and marks regularly and reporting discrepancies.'),

            SectionTitle(title: '5. Security and Privacy'),
            BulletPoint(text: 'StudySync uses encryption and secure authentication to protect user data.'),
            BulletPoint(text: 'Users are responsible for maintaining the confidentiality of their login credentials.'),
            BulletPoint(text: 'In case of a suspected security breach, users must notify the administrator immediately.'),

            SectionTitle(title: '6. Prohibited Conduct'),
            BulletPoint(text: 'Attempting to submit attendance on behalf of another person.'),
            BulletPoint(text: 'Uploading false information, tampering with data, or using unauthorized access.'),
            BulletPoint(text: 'Using StudySync for any non-educational or harmful activities.'),

            SectionTitle(title: '7. Limitation of Liability'),
            BulletPoint(text: 'StudySync and its developers are not liable for any damages or loss of data arising from misuse or technical failure.'),
            BulletPoint(text: 'While best efforts are made to ensure accuracy, occasional errors in attendance or marks may occur and will be resolved promptly.'),

            SectionTitle(title: '8. Modifications to Terms'),
            BulletPoint(text: 'These terms may be updated periodically. Continued use of the platform after changes constitutes acceptance of the new terms.'),

            SectionTitle(title: '9. Termination'),
            BulletPoint(text: 'Users violating these terms may have their access revoked temporarily or permanently.'),
            BulletPoint(text: 'The institution reserves the right to suspend or deactivate accounts in cases of misuse or breach of policy.'),

            SectionTitle(title: '10. Contact Information'),
            BulletPoint(text: 'For any questions or concerns regarding these Terms and Conditions, please contact the StudySync support team at: atharvsutar3102003@gmail.com'),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontFamily: 'Outfit'),
            ),
          ),
        ],
      ),
    );
  }
}
