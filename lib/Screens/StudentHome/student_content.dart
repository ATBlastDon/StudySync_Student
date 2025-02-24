import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studysync_student/Screens/Chat/chatscreen.dart';

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
  const StudentsContent(this._email, this.year, {super.key, required this.sem});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(year)
          .collection(sem)
          .where('approvalStatus', isEqualTo: 'approved')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No approved students found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final studentDocument = snapshot.data!.docs[index];
            final studentData = studentDocument.data() as Map<String, dynamic>;
            final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

            // Do not show yourself.
            if (studentData['email'] == currentUserEmail) {
              return const SizedBox.shrink();
            }

            String fullName = '${studentData['fname']} ${studentData['sname'] ?? ''}';
            final profilePhotoUrl = studentData['profilePhotoUrl'] as String?;
            final peerEmail = studentData['email'];
            final groupChatId = generateGroupChatId(currentUserEmail!, peerEmail);

            return FadeInUp(
              duration: Duration(milliseconds: index * 100),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _openChatScreen(
                      context,
                      studentDocument.id,
                      _email,
                      peerEmail,
                      fullName,
                      year,
                      sem,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black26)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: profilePhotoUrl != null
                                ? CachedNetworkImageProvider(profilePhotoUrl)
                                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(fontSize: 18, fontFamily: 'Outfit'),
                            ),
                          ),
                          // Unread indicator: blue dot if there are unread messages.
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('messages')
                                .doc(groupChatId)
                                .collection('chats')
                                .where('status', isEqualTo: 'unread')
                                .where('idFrom', isNotEqualTo: currentUserEmail)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                return Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index != snapshot.data!.docs.length - 1)
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
    String chatUserEmail, String chatUserName, String year, String sem) async {
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
      ),
    ),
  );
}
