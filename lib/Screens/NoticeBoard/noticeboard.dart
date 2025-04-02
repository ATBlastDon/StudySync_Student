import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:studysync_student/Screens/Repeated_Functions/full_screen_image.dart';

final logger = Logger();

class NoticeBoard extends StatefulWidget {
  final String year;
  final String dept;
  final String ay;
  final String rollNo;

  const NoticeBoard({
    super.key,
    required this.year,
    required this.dept,
    required this.ay,
    required this.rollNo});

  @override
  State<NoticeBoard> createState() => _NoticeBoardState();
}

class _NoticeBoardState extends State<NoticeBoard> {
  bool _isMarkingNotices = false;

  @override
  void initState() {
    super.initState();
    _markNotices();
  }

  Future<void> _markNotices() async {
    setState(() {
      _isMarkingNotices = true;
    });

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .doc("noticeboard")
        .collection("notices")
        .where('dept', isEqualTo: widget.dept)
        .where('ay', isEqualTo: widget.ay)
        .where('batch', whereIn: [widget.year, 'ALL'])
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> readBy = data['readby'] ?? [];

      if (!readBy.contains(widget.rollNo)) {
        await doc.reference.update({
          'readby': FieldValue.arrayUnion([widget.rollNo])
        });
      }
    }

    setState(() {
      _isMarkingNotices = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    // While marking is in progress, show a full screen CircularProgressIndicator.
    if (_isMarkingNotices) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.grey[100],
          title: FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: const Text(
              'N O T I C E   B O A R D',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          elevation: 10,
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.black,)),
      );
    }

    // Once marking is complete, show the notice list.
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.grey[100],
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'N O T I C E   B O A R D',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        elevation: 10,
      ),
      body: _buildNoticeList(),
    );
  }


  Widget _buildNoticeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .doc(widget.dept)
          .collection(widget.ay)
          .doc('ALL') // Fetch ALL notices
          .collection('details')
          .snapshots(),
      builder: (context, allSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notices')
              .doc(widget.dept)
              .collection(widget.ay)
              .doc(widget.year) // Fetch Batch notices (BE, SE, TE)
              .collection('details')
              .snapshots(),
          builder: (context, batchSnapshot) {
            if (allSnapshot.connectionState == ConnectionState.waiting ||
                batchSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black,));
            }

            if (allSnapshot.hasError || batchSnapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading notices: ${allSnapshot.error ?? batchSnapshot.error}',
                  style: const TextStyle(
                      fontFamily: "Outfit", color: Colors.red),
                ),
              );
            }

            List<Notice> notices = [];

            // Add "ALL" notices
            if (allSnapshot.hasData && allSnapshot.data!.docs.isNotEmpty) {
              notices.addAll(allSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Notice(
                  id: doc.id,
                  title: data['title'] ?? 'No Title',
                  subtitle: data['subtitle'] ?? 'No Subtitle',
                  time: data['time'] ?? '',
                  batch: data['batch'] ?? '',
                  author: data['author'] ?? 'Unknown Author',
                  imageUrl: data['imageUrl'],
                );
              }));
            }

            // Add batch-specific notices
            if (batchSnapshot.hasData && batchSnapshot.data!.docs.isNotEmpty) {
              notices.addAll(batchSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Notice(
                  id: doc.id,
                  title: data['title'] ?? 'No Title',
                  subtitle: data['subtitle'] ?? 'No Subtitle',
                  time: data['time'] ?? '',
                  batch: data['batch'] ?? '',
                  author: data['author'] ?? 'Unknown Author',
                  imageUrl: data['imageUrl'],
                );
              }));
            }

            // Sort notices by time (latest first)
            notices.sort((a, b) => b.time.compareTo(a.time));

            if (notices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No notices available.',
                      style: TextStyle(fontFamily: "Outfit", fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                return NoticeTile(
                  notice: notices[index],
                  onTap: () {
                    _showMessageDialog(context, notices[index].title,
                        notices[index].subtitle, notices[index].author, notices[index].time);
                  },
                  onImageTap: () {
                    if (notices[index].imageUrl != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(
                            url: notices[index].imageUrl!,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showMessageDialog(BuildContext context, String title, String? subtitle,
      String author, String time) {
    final parsedTime = DateTime.parse(time);
    final formattedDate = DateFormat('EEEE,  MMM d, y').format(parsedTime);
    final formattedTime = DateFormat('hh:mm a').format(parsedTime);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center( // Center the 'Notice Details' text
                  child: Text(
                    'Notice Details',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal[600],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 15),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                const Divider(height: 30),
                _buildDetailRow(Icons.person, author),
                _buildDetailRow(Icons.timer,
                    '$formattedDate at $formattedTime'),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal[600]),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class Notice {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String author;
  final String batch;
  final String? imageUrl;

  Notice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.author,
    required this.batch,
    this.imageUrl,
  });
}

class NoticeTile extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;
  final VoidCallback onImageTap;

  const NoticeTile({
    super.key,
    required this.notice,
    required this.onTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final truncatedSubtitle = notice.subtitle
        .split(' ')
        .length > 8
        ? '${notice.subtitle.split(' ').sublist(0, 8).join(' ')}...'
        : notice.subtitle;

    final parsedTime = DateTime.parse(notice.time);
    final formattedDate = DateFormat('MMM d').format(parsedTime);
    final formattedTime = DateFormat('hh:mm a').format(parsedTime);

    // Wrap the tile with a FadeInUp animation
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          borderRadius: BorderRadius.circular(15),
          elevation: 4,
          shadowColor: Colors.green[100],
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.green[100]!,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: Colors.green[800],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      notice.title,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      notice.batch,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                truncatedSubtitle,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (notice.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: GestureDetector(
                          onTap: onImageTap,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: notice.imageUrl!,
                              placeholder: (context, url) => Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 150,
                                color: Colors.red[50],
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                              fit: BoxFit.cover,
                              height: 150,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '$formattedDate • $formattedTime',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'By ${notice.author}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}