import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:studysync_student/Screens/AttendanceAnnouncement/passwordscanner.dart';

class ListOfAttendance extends StatelessWidget {
  final List<Map<String, dynamic>> announcements;

  const ListOfAttendance({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          child: const Text(
            'L E C T U R E S   L I S T',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.teal.shade100,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return _buildAttendanceCard(context, announcement);
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, Map<String, dynamic> announcement) {
    Theme.of(context);
    final formattedCreated = DateFormat('hh:mm a').format(announcement['created_at']);
    final formattedExpiry = DateFormat('hh:mm a').format(announcement['expires_at']);
    final subject = announcement['optional_sub'] != 'N/A' && announcement['optional_sub'] != null
        ? announcement['optional_sub']
        : announcement['subject'];

    return FadeInRight(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade100,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.lightGreen, Colors.cyan],
              ),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white),
          ),
          title: Text(
            'Attendance: $subject',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(
                        announcement['type'],
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Colors.teal.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Set borderRadius here
                        side: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, y • hh:mm a').format(announcement['created_at']),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailRow(Icons.school_outlined,
                          '${announcement['year']} • Sem ${announcement['sem']}'),
                      _buildTimeChip(
                          Icons.access_time, formattedCreated, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailRow(Icons.groups_outlined,
                          'Batch : ${announcement['batch']}'),
                      _buildTimeChip(
                          Icons.timer_off_outlined, formattedExpiry, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Colors.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.mobile_friendly,
                        size: 20,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Give Attendance',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.black
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        // Make the button background transparent so the gradient shows.
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        DateTime currentTime = DateTime.now();
                        if (currentTime.isAfter(announcement['expires_at'])) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Time Out!',
                                style: TextStyle(fontFamily: "Outfit"),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Passwordscanner(
                                subjectName: announcement['subject'],
                                type: announcement['type'],
                                batch: announcement['batch'],
                                rollNo: announcement['rollNo'],
                                year: announcement['year'],
                                optionalSubject: announcement['optional_sub'],
                                sem: announcement['sem'],
                                pass: announcement['password'],
                                created: DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(announcement['created_at']),
                                fullName: announcement['fullName'],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}