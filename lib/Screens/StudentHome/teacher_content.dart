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


class TeachersContent extends StatelessWidget {
  final String _email;
  final String year;
  final String sem;
  final String ay;
  final String dept;

  const TeachersContent(this._email, this.year, {super.key, required this.sem, required this.ay, required this.dept});


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black,));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No teachers found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final teacherDocument = snapshot.data!.docs[index];
            final teacherData = teacherDocument.data() as Map<String, dynamic>;
            final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

            // Do not show yourself.
            if (teacherData['email'] == currentUserEmail) {
              return const SizedBox.shrink();
            }

            String fullName = '${teacherData['fname']} ${teacherData['sname'] ?? ''}';
            final profilePhotoUrl = teacherData['profilePhotoUrl'] as String?;
            final peerEmail = teacherData['email'];
            final groupChatId = generateGroupChatId(currentUserEmail!, peerEmail);

            return FadeInUp(
              duration: Duration(milliseconds: index * 100),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePhotoUrl != null
                          ? CachedNetworkImageProvider(profilePhotoUrl)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
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
                          String prefix = lastMsgDoc['idFrom'] == currentUserEmail ? "You: " : "New: ";
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
                              color: Colors.blue,
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
                      _openChatScreen(context, teacherDocument.id, _email, peerEmail, fullName, year, sem, ay, dept);
                    },
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
    String chatUserEmail, String chatUserName, String year, String sem, String ay, String dept) async {
  final groupChatId = generateGroupChatId(currentUserEmail, chatUserEmail);
  final navigator = Navigator.of(context);
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