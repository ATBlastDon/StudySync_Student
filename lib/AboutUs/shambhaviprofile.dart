import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:studysync_student/Screens/Repeated_Functions/launch_url.dart';
import 'package:studysync_student/Screens/Repeated_Functions/show_zoom_profile.dart';

class ShambhaviProfile extends StatelessWidget {
  const ShambhaviProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'Shambhavi Balwant Sutar',
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
              colors: [Colors.teal, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
        backgroundColor: Colors.grey[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  showZoomedProfile(context, 'assets/profilephoto/Shambhavi.jpg');
                },
                child: const CircleAvatar(
                  radius: 100,
                  backgroundImage: AssetImage('assets/profilephoto/Shambhavi.jpg'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: const [
                Text(
                  'Data Analyst',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              content:
              "Shambhavi is passionate about software development and innovation. She has extensive experience in building mobile and web applications, focusing on user-friendly interfaces and scalable solutions. She is currently pursuing a degree in Computer Science (AI & ML) and actively contributes to open-source projects.",
            ),
            _buildSectionCard(
              title: 'Education',
              content: 'Finolex Academy of Management and Technology\nBachelor of Engineering in Computer Science (AI & ML)\n2021 - 2025',
              icon: Icons.school_outlined,
            ),
            _buildSectionCard(
              title: 'Skills',
              content: 'Dart, Java, Python, Data Analysis',
              icon: Icons.code,
            ),
            _buildSectionCard(
              title: 'Tools',
              content: 'Android Studio, Visual Studio Code, Jupyter Notebook',
              icon: Icons.build_circle_outlined,
            ),
            const SizedBox(height: 20),
            // Contacts row with PNG icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Image.asset(
                    'assets/icon/github.png',
                    height: 30,
                    width: 30,
                  ),
                  onPressed: () {
                    launchURL('https://github.com/SBS-WORLD');
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Image.asset(
                    'assets/icon/linkedin.png',
                    height: 30,
                    width: 30,
                  ),
                  onPressed: () {
                    // Launch the LinkedIn profile URL using the _launchURL helper from your separate file
                    launchURL('https://www.linkedin.com/in/shambhavi-sutar-355867316');
                  },
                ),
                const SizedBox(width: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {String? title, required String content, IconData? icon}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 28, color: Colors.greenAccent),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                  Text(
                    content,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}