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
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black,),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Our Team",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
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
            const SizedBox(height: 40),
            Center(
              child: FadeInDown(
                duration: const Duration(milliseconds: 1000),
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
            ),
            const SizedBox(height: 20),
            Center(
              child: FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: const Center(
                  child: Text(
                    "At StudySync, \nWe are committed to revolutionizing attendance management through cutting-edge technology. \n\nOur mission is to empower organizations with a seamless, efficient, and secure system that leverages QR codes to simplify attendance tracking, ensuring accuracy and convenience for all stakeholders. \n\nOur system offers real-time monitoring of attendance data, comprehensive reporting features, and integration capabilities with existing organizational systems. \n\nWith our user-friendly interface and robust security measures, we aim to provide a reliable solution for attendance management, freeing up valuable time and resources for organizations to focus on their core objectives. \n\nJoin us on this journey to transform the way attendance is managed and make a positive impact on organizations worldwide.",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center, // Center the text horizontally
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, String name, String role, String routeName, String imagePath) {
    return FadeInDown(
      duration: const Duration(milliseconds: 1000),
      child: TeamMemberTile(
        image: AssetImage(imagePath),
        name: name,
        role: role,
        onTap: () {
          switch (routeName) {
            case 'MayankProfile':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MayankProfile()),
              );
              break;
            case 'AtharvProfile':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AtharvProfile()),
              );
              break;
            case 'ShambhaviProfile':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShambhaviProfile()),
              );
              break;
            case 'AnujaProfile':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnujaProfile()),
              );
              break;
            default:
            // Handle default case or do nothing
          }
        },
      ),
    );
  }

}

class TeamMemberTile extends StatelessWidget {
  final ImageProvider image;
  final String name;
  final String role;
  final Function()? onTap;

  const TeamMemberTile({
    super.key,
    required this.image,
    required this.name,
    required this.role,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: image,
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        role,
        style: const TextStyle(
          fontFamily: 'Outfit',
        ),
      ),
    );
  }
}
