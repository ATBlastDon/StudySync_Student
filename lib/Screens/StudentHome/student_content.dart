import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studysync_student/Screens/Chat/chatscreen.dart';
import 'package:studysync_student/Screens/Repeated_Functions/show_zoom_profile.dart';

/// Helper: Generate a unique chat id based on the two emails.
String generateGroupChatId(String currentUserEmail, String peerUserEmail) {
  if (currentUserEmail.hashCode <= peerUserEmail.hashCode) {
    return '$currentUserEmail-$peerUserEmail';
  } else {
    return '$peerUserEmail-$currentUserEmail';
  }
}

/// Helper: Mark unread messages as read in a given conversation.
Future<void> markMessagesAsRead(String groupChatId, String currentUserEmail) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('messages')
      .doc(groupChatId)
      .collection('chats')
      .where('status', isEqualTo: 'unread')
      .where('idFrom', isNotEqualTo: currentUserEmail)
      .get();

  WriteBatch batch = FirebaseFirestore.instance.batch();
  for (var doc in querySnapshot.docs) {
    batch.update(doc.reference, {'status': 'read'});
  }
  await batch.commit();
}


class StudentsContent extends StatelessWidget {
  final String _email;
  final String year;
  final String sem;
  final String ay;
  final String dept;

  const StudentsContent(this._email, this.year, {super.key, required this.sem, required this.ay, required this.dept});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(dept)
          .collection(ay)
          .doc(year)
          .collection(sem)
          .where('approvalStatus', isEqualTo: 'approved')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No Students Yet'));
        }

        // Filter out the logged in user.
        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['email'] != _email;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No Students Yet'));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final studentDocument = filteredDocs[index];
            final studentData = studentDocument.data() as Map<String, dynamic>;
            final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
            // Prepare display values.
            String fullName = '${studentData['fname']} ${studentData['sname'] ?? ''}';
            final profilePhotoUrl = studentData['profilePhotoUrl'] as String?;
            final peerEmail = studentData['email'];
            final groupChatId = generateGroupChatId(currentUserEmail!, peerEmail);

            return FadeInUp(
              duration: Duration(milliseconds: index * 100),
              child: Column(
                children: [
                  ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        showZoomedProfile(
                          context,
                          profilePhotoUrl ?? 'assets/images/default_profile_image.png',
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: profilePhotoUrl != null
                            ? CachedNetworkImageProvider(profilePhotoUrl)
                            : const AssetImage('assets/images/default_profile_image.png') as ImageProvider,
                      ),
                    ),
                    title: Text(
                      fullName,
                      style: const TextStyle(fontSize: 18, fontFamily: 'Outfit'),
                    ),
                    subtitle: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('messages')
                          .doc(groupChatId)
                          .collection('chats')
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, recentSnapshot) {
                        if (recentSnapshot.hasData && recentSnapshot.data!.docs.isNotEmpty) {
                          final lastMsgDoc = recentSnapshot.data!.docs.first;
                          final messageType = lastMsgDoc['type'];
                          String lastMessage = lastMsgDoc['content'] as String;
                          if (messageType == 1) {
                            lastMessage = "Image";
                          }
                          if (messageType == 2) {
                            lastMessage = "PDF";
                          }
                          String prefix = lastMsgDoc['idFrom'] == currentUserEmail ? "You: " : "New Msg: ";
                          return Text(
                            "$prefix$lastMessage",
                            style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Outfit'),
                            overflow: TextOverflow.ellipsis,
                          );
                        } else {
                          return const Text(
                            "",
                            style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Outfit'),
                          );
                        }
                      },
                    ),
                    trailing: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('messages')
                          .doc(groupChatId)
                          .collection('chats')
                          .where('status', isEqualTo: 'unread')
                          .where('idFrom', isNotEqualTo: currentUserEmail)
                          .snapshots(),
                      builder: (context, unreadSnapshot) {
                        if (unreadSnapshot.hasData && unreadSnapshot.data!.docs.isNotEmpty) {
                          int unreadCount = unreadSnapshot.data!.docs.length;
                          return Container(
                            width: unreadCount > 9 ? 24 : 18,
                            height: 18,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Outfit",
                                  fontSize: unreadCount > 9 ? 10 : 14,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    onTap: () {
                      _openChatScreen(context, studentDocument.id, _email, peerEmail, fullName, year, sem, ay, dept);
                    },
                  ),
                  if (index != filteredDocs.length - 1)
                    const Divider(color: Colors.black26, height: 0),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


void _openChatScreen(BuildContext context, String chatUserId, String currentUserEmail,
    String chatUserEmail, String chatUserName, String year, String sem, String ay, String dept) async {
  final navigator = Navigator.of(context);
  final groupChatId = generateGroupChatId(currentUserEmail, chatUserEmail);
  await markMessagesAsRead(groupChatId, currentUserEmail);
  navigator.push(
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        currentUseremail: currentUserEmail,
        peerUseremail: chatUserEmail,
        chatusername: chatUserName,
        year: year,
        sem: sem,
        ay: ay,
        dept: dept,
      ),
    ),
  );
}