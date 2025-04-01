import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentLinkPage extends StatelessWidget {
  final String dept;
  final String ay;
  final String sem;
  final String year;

  const StudentLinkPage({
    super.key,
    required this.dept,
    required this.ay,
    required this.sem,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final CollectionReference linksRef = FirebaseFirestore.instance
        .collection('links')
        .doc(dept)
        .collection(ay)
        .doc(year)
        .collection(sem);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: const Text(
            'L I N K S',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: linksRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: FadeIn(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: FadeIn(
                duration: const Duration(milliseconds: 600),
                child: const Text(
                  'No links available.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String title = data['title'] ?? 'No Title';
              final String url = data['url'] ?? '';
              final String description = data['description'] ?? '';
              // 'link' is the same as url
              final String link = url;

              return FadeInUp(
                duration: Duration(milliseconds: 500 + (index * 100)),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black45,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _launchURL(url);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.blueGrey.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  link,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    // Ensure URL starts with "https://"
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
