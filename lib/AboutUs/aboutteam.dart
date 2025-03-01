import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'anujaprofile.dart';
import 'mayankprofile.dart';
import 'shambhaviprofile.dart';
import 'atharvprofile.dart';

class AboutTeam extends StatelessWidget {
  const AboutTeam({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: const Text(
                "Team members",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildMemberTile(
              context,
              'Mayank Mahesh Sagvekar',
              'Founder & CEO',
              'MayankProfile',
              'assets/profilephoto/Mayank.jpg',
            ),
            _buildMemberTile(
              context,
              'Athrav Balwant Sutar',
              'Lead Developer',
              'AtharvProfile',
              'assets/profilephoto/Atharv.jpg',
            ),
            _buildMemberTile(
              context,
              'Anuja Hemant Patil',
              'UI/UX Designer',
              'AnujaProfile',
              'assets/profilephoto/Anuja.jpg',
            ),
            _buildMemberTile(
              context,
              'Shambhavi Balwant Sutar',
              'Data Analytics',
              'ShambhaviProfile',
              'assets/profilephoto/Shambhavi.jpg',
            ),
            const SizedBox(height: 30),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: const Text(
                "Our Mission",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      "At StudySync, we are on a mission to revolutionize attendance management through innovative technology. Our goal is to empower organizations with a seamless, efficient, and secure system that leverages QR codes to simplify attendance tracking, ensuring accuracy and convenience for all stakeholders.",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Our system offers real-time monitoring of attendance data, comprehensive reporting features, and seamless integration with existing organizational systems. With a user-friendly interface and robust security measures, we aim to provide a reliable solution for attendance management, freeing up valuable time and resources for organizations to focus on their core objectives.",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Join us on this journey to transform the way attendance is managed and make a positive impact on organizations worldwide. Together, we can create a future where attendance tracking is effortless, accurate, and efficient.",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, String name, String role, String routeName, String imagePath) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 800),
      child: GestureDetector(
        onTap: () {
          switch (routeName) {
            case 'MayankProfile':
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MayankProfile()));
              break;
            case 'AtharvProfile':
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AtharvProfile()));
              break;
            case 'ShambhaviProfile':
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ShambhaviProfile()));
              break;
            case 'AnujaProfile':
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnujaProfile()));
              break;
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(imagePath),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}