import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:studysync_student/Screens/Chat/wallpaper.dart';
import 'package:http/http.dart' as http;
import 'package:studysync_student/Screens/Repeated_Functions/full_screen_image.dart';
import 'package:studysync_student/Screens/Repeated_Functions/upload_with_progress.dart';
import 'package:url_launcher/url_launcher.dart';


class ChatScreen extends StatefulWidget {
  final String currentUseremail;
  final String peerUseremail;
  final String chatusername;
  final String year;
  final String ay;
  final String dept;
  final String sem;

  const ChatScreen({super.key,
    required this.currentUseremail,
    required this.peerUseremail,
    required this.chatusername,
    required this.year,
    required this.sem,
    required this.ay,
    required this.dept,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String groupChatId;
  late TextEditingController _textEditingController;
  late ScrollController _listScrollController;
  final int _limit = 20; // Limit for initial load of messages
  late String _studentName = '';
  late String _studentProfilePhotoUrl = '';
  String? backgroundImageUrl;


  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
    _textEditingController = TextEditingController();
    _listScrollController = ScrollController();
    groupChatId = _getGroupChatId(widget.currentUseremail, widget.peerUseremail);
    loadBackgroundImageUrl();
  }

  void loadBackgroundImageUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      backgroundImageUrl = prefs.getString('backgroundImageUrl');
    });
  }

  Future<void> fetchStudentInfo() async {
    QuerySnapshot<Map<String, dynamic>> snapshotStudent =
    await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.dept)
        .collection(widget.ay)
        .doc(widget.year)
        .collection(widget.sem)
        .where('email', isEqualTo: widget.peerUseremail)
        .get();
    QuerySnapshot<Map<String, dynamic>> snapshotTeacher =
    await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: widget.peerUseremail)
        .get();

    if (snapshotStudent.docs.isNotEmpty) {
      Map<String, dynamic> data = snapshotStudent.docs.first.data();
      String fullName = '${data['fname'] ?? ''} ${data['sname'] ?? ''}';
      setState(() {
        _studentName = fullName;
        _studentProfilePhotoUrl = data['profilePhotoUrl'] ?? '';
      });
    } else if (snapshotTeacher.docs.isNotEmpty) {
      Map<String, dynamic> data = snapshotTeacher.docs.first.data();
      String fullName = '${data['fname'] ?? ''} ${data['sname'] ?? ''}';
      setState(() {
        _studentName = fullName;
        _studentProfilePhotoUrl = data['profilePhotoUrl'] ?? '';
      });
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Preview",
                style: TextStyle(fontFamily: "Outfit", fontSize: 18)),
            content: Image.file(imageFile),
            actions: <Widget>[
              TextButton.icon( // Use TextButton.icon
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.cancel, color: Colors.red), // Add icon
                label: const Text("Cancel", style: TextStyle(fontFamily: "Outfit", color: Colors.red)), // Text with icon
              ),
              ElevatedButton.icon( // Use ElevatedButton.icon
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendImageMessage(imageFile);
                },
                icon: const Icon(Icons.send, color: Colors.white), // Add icon
                label: const Text("Send", style: TextStyle(fontFamily: "Outfit", color: Colors.white)), // Text with icon
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _getPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      File pdfFile = File(result.files.single.path!);
      if (!mounted) return;
      // Compute PDF metadata before showing the dialog.
      String pdfName = pdfFile.path.split('/').last;
      int fileSizeBytes = await pdfFile.length();
      String fileSize = "${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB";

      if(!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Prominent PDF icon
                const Icon(
                  Icons.picture_as_pdf,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                // Display file name
                Text(
                  pdfName,
                  style: const TextStyle(
                    fontFamily: "Outfit",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Display file size
                Text(
                  fileSize,
                  style: const TextStyle(
                    fontFamily: "Outfit",
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Send this PDF file?",
                  style: TextStyle(
                    fontFamily: "Outfit",
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  "Cancel",
                  style: TextStyle(fontFamily: "Outfit", color: Colors.red),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendPdfMessage(pdfFile);
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  "Send",
                  style: TextStyle(fontFamily: "Outfit", color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> clearChatHistory(BuildContext context, String groupChatId) async {
    bool confirmClear = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_rounded, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Text('Clear Chat??', style: TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0), // Add padding here
            child: Text(
              'Are you sure you want to clear this chat?\nClearChat Clears the Chats from Both end!!!',
              style: TextStyle(fontFamily: "Outfit"),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
              label: const Text('No', style: TextStyle(fontFamily: "Outfit", color: Colors.grey)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey, // Text color
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Yes', style: TextStyle(fontFamily: "Outfit", color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Background color
                textStyle: const TextStyle(fontFamily: "Outfit"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],);
      },
    );

    if (confirmClear == true) {
      try {
        QuerySnapshot<Map<String, dynamic>> messagesSnapshot =
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(groupChatId)
            .collection('chats')
            .get();

        List<QueryDocumentSnapshot<Map<String, dynamic>>> messages =
            messagesSnapshot.docs;

        for (QueryDocumentSnapshot<Map<String, dynamic>> message in messages) {
          await message.reference.delete();
        }

        Fluttertoast.showToast(
          msg: 'Chat cleared successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.lightBlueAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (error) {
        // Show an error message when an error occurs
        Fluttertoast.showToast(
          msg: 'Error occurred: $error',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(_studentProfilePhotoUrl),
            ),
            const SizedBox(width: 8),
            Text(
              _studentName,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showPopupMenu(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: backgroundImageUrl != null
                ? DecorationImage(
              image: AssetImage(backgroundImageUrl!),
              fit: BoxFit.cover,
            )
                : const DecorationImage( // Use const for AssetImage
              image: AssetImage('assets/wallpaper/default.jpg'), // Path to your default image
              fit: BoxFit.cover,
            ),
            // No need for the color property if you always have an image
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .doc(groupChatId)
                      .collection('chats')
                      .orderBy('timestamp', descending: true)
                      .limit(_limit)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.black,));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No messages yet',style: TextStyle(
                        fontFamily: "Outfit",
                        color: Colors.black,
                        fontSize: 16,
                      ),));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(10.0),
                      itemBuilder: (context, index) {
                        return buildItem(snapshot.data!.docs[index]);
                      },
                      itemCount: snapshot.data!.docs.length,
                      reverse: true,
                      controller: _listScrollController,
                    );
                  },
                ),
              ),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.lightBlueAccent),
            onPressed: _showAttachmentMenu,
          ),
          Expanded(
            child: TextField(
              style: const TextStyle(fontFamily: "Outfit"),
              controller: _textEditingController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.lightBlueAccent),
            onPressed: () => _sendTextMessage(),
          ),
        ],
      ),
    );
  }

  // Show the attachment menu as a modal bottom sheet.
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  "Share Content",
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: "Outfit",
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(24),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildAttachItem("Gallery", Icons.photo_library_rounded,
                        Colors.purple, _getImage),
                    _buildAttachItem("Camera", Icons.camera_alt_rounded,
                        Colors.red, _pickFromCamera),
                    _buildAttachItem("Document", Icons.description_rounded,
                        Colors.orange, _getPdf),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Outfit",
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _pickFromCamera() async {
    Navigator.pop(context); // Close the bottom sheet
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Preview", style: TextStyle(fontFamily: "Outfit", fontSize: 18)),
            content: Image.file(imageFile),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text("Cancel", style: TextStyle(fontFamily: "Outfit", color: Colors.red)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendImageMessage(imageFile);
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Send", style: TextStyle(fontFamily: "Outfit", color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent),
              ),
            ],
          );
        },
      );
    }
  }


  void _showPopupMenu(BuildContext context) {
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        Offset(MediaQuery.of(context).size.width - 50.0, 0),
        Offset(MediaQuery.of(context).size.width, 50.0),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: const Color(0xFFFCFCFC),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text("Clear Chat History",style: TextStyle(fontFamily: "Outfit",)),
            ],
          ),
          onTap: () {
            clearChatHistory(context, groupChatId);
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.image),

              SizedBox(width: 8),
              Text("Change Chat Background",style: TextStyle(fontFamily: "Outfit",)),
            ],
          ),
          onTap: () {
            _showBackgroundSelectionDialog(context);
          },
        ),
      ],
    );
  }

  void _showBackgroundSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WallpaperDialog(
          onWallpaperSelected: (selectedWallpaper) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('backgroundImageUrl', selectedWallpaper!);
            setState(() {
              backgroundImageUrl = selectedWallpaper;
            });
          },
          onClearWallpaper: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('backgroundImageUrl');
            setState(() {
              backgroundImageUrl = null;
            });
          },
        );
      },
    );
  }

  // Unified send message method.
  void _sendTextMessage() async {
    String messageContent = _textEditingController.text.trim();
    if (messageContent.isNotEmpty) {
      _textEditingController.clear();
      DocumentReference messageRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection("chats")
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

      await messageRef.set({
        'idFrom': widget.currentUseremail,
        'idTo': widget.peerUseremail,
        'timestamp': DateTime.now(),
        'content': messageContent,
        'type': 0, // 0 for text message
        'status': 'unread',
      });

      _listScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to send', style: TextStyle(fontFamily: "Outfit")),
        ),
      );
    }
  }

  // Send image message.
  Future<void> _sendImageMessage(File imageFile) async {
    try {
      String path = 'messages/images/$groupChatId/${DateTime.now().millisecondsSinceEpoch}';
      String imageUrl = await uploadFileWithProgress(
        context: context,
        file: imageFile,
        path: path,
      );

      DocumentReference messageRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection('chats')
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

      await messageRef.set({
        'idFrom': widget.currentUseremail,
        'idTo': widget.peerUseremail,
        'timestamp': DateTime.now(),
        'content': imageUrl,
        'type': 1,
        'status': 'unread',
      });

      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error sending image: $e");
    }
  }


// Send PDF message: Upload the PDF and then save the message with metadata.
  Future<void> _sendPdfMessage(File pdfFile) async {
    try {
      String path = 'messages/pdf/$groupChatId/${DateTime.now().millisecondsSinceEpoch}';
      String pdfUrl = await uploadFileWithProgress(
        context: context,
        file: pdfFile,
        path: path,
      );

      // Extract PDF metadata.
      String pdfName = pdfFile.path.split('/').last;
      int sizeInBytes = await pdfFile.length();
      double sizeInMB = sizeInBytes / (1024 * 1024);
      String pdfSize = "${sizeInMB.toStringAsFixed(2)} MB";

      DocumentReference messageRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection("chats")
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

      await messageRef.set({
        'idFrom': widget.currentUseremail,
        'idTo': widget.peerUseremail,
        'timestamp': DateTime.now(),
        'content': pdfUrl,
        'type': 2,
        'status': 'unread',
        'pdfName': pdfName,
        'pdfSize': pdfSize,
      });

      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error sending PDF: $e");
    }
  }


  String _getGroupChatId(String currentUserId, String peerUserId) {
    return currentUserId.hashCode <= peerUserId.hashCode
        ? '$currentUserId-$peerUserId'
        : '$peerUserId-$currentUserId';
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  Widget buildItem(DocumentSnapshot document) {
    int messageType = document['type'];
    String content = document['content'];
    bool isSent = document['idFrom'] == widget.currentUseremail;
    DateTime timestamp = (document['timestamp'] as Timestamp).toDate();
    Widget messageWidget;

    switch (messageType) {
      case 0: // Text message
        messageWidget = Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isSent
                                  ? [Colors.greenAccent, Colors.teal]
                                  : [Colors.lightBlueAccent, Colors.blue],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isSent ? const Radius.circular(20) : Radius.zero,
                              bottomRight: isSent ? Radius.zero : const Radius.circular(20),
                            ),
                          ),
                          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                content,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: "Outfit",
                                  fontSize: 16,
                                ),
                                softWrap: true,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('hh:mm').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withValues(alpha: 0.6),
                                      fontFamily: "Outfit",
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('a').format(timestamp).toLowerCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withValues(alpha: 0.6),
                                      fontFamily: "Outfit",
                                    ),
                                  ),
                                  if (isSent) ...[
                                    const SizedBox(width: 4),
                                    document['status'] == 'read'
                                        ? const Icon(Icons.done_all, size: 16, color: Colors.white)
                                        : const Icon(Icons.done, size: 16, color: Colors.black),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        break;
      case 1: // Image message
        messageWidget = Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FullScreenImage(url: content)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(isSent ? 20 : 0),
                        bottomRight: Radius.circular(isSent ? 0 : 20),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: content,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(timestamp).toLowerCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontFamily: "Outfit",
                              ),
                            ),
                            if (isSent) ...[
                              const SizedBox(width: 4),
                              document['status'] == 'read'
                                  ? const Icon(Icons.done_all, size: 16, color: Colors.white)
                                  : const Icon(Icons.done, size: 16, color: Colors.black),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        break;
      case 2: // PDF message
        final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        final String pdfUrl = data['content'];
        final String pdfName = data.containsKey('pdfName') ? data['pdfName'] : 'Document.pdf';
        final String pdfSize = data.containsKey('pdfSize') ? data['pdfSize'] : 'Unknown size';

        messageWidget = Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: PDF icon with a colored background and file name.
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pdfName,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // File size display.
                Text(
                  pdfSize,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openPdf(pdfUrl, pdfName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.visibility, size: 20, color: Colors.black,),
                      label: const Text('View', style: TextStyle(fontFamily: 'Outfit',color: Colors.black)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _savePdf(pdfUrl, pdfName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.download, size: 20, color: Colors.black),
                      label: const Text('Download', style: TextStyle(fontFamily: 'Outfit',color: Colors.black)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
        break;
        default:
        messageWidget = Container();
    }

    // Wrap the message widget with a GestureDetector only if the message is sent by the current user.
    return isSent
        ? GestureDetector(
      onLongPress: () {
        _confirmDeleteMessage(document);
      },
      child: messageWidget,
    )
        : messageWidget;
  }

  Future<void> _savePdf(String pdfUrl, String pdfName) async {
    try {
      // Create the GET request.
      final request = http.Request('GET', Uri.parse(pdfUrl));
      final response = await http.Client().send(request);
      final contentLength = response.contentLength;

      // Create a notifier to track progress.
      final progressNotifier = ValueNotifier<double>(0.0);
      List<int> bytes = [];
      int received = 0;

      // Create a completer that completes when download finishes.
      final completer = Completer<void>();

      // Listen to the response stream.
      final subscription = response.stream.listen(
            (List<int> newBytes) {
          bytes.addAll(newBytes);
          received += newBytes.length;
          if (contentLength != null) {
            progressNotifier.value = received / contentLength;
          }
        },
        onDone: () {
          completer.complete();
        },
        onError: (e) {
          completer.completeError(e);
        },
        cancelOnError: true,
      );

      // Show progress dialog (non-blocking).
      if(!mounted) return;
      final dialogFuture = showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            content: SizedBox(
              height: 100,
              child: ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, value, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Downloading... ${(value * 100).toStringAsFixed(0)}%", style: TextStyle(fontFamily: "Outfit")),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: value),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );

      // Wait for download completion.
      await completer.future;
      // Once complete, dismiss the progress dialog.
      if(!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await subscription.cancel();

      // Save the file in the desired location.
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        // For Android, use the external storage Download folder.
        downloadsDirectory = Directory('/storage/emulated/0/Download/Attendance/pdf');
      } else {
        // For other platforms (e.g., iOS), attempt to get the downloads directory.
        downloadsDirectory = await getDownloadsDirectory();
      }

      if (downloadsDirectory != null) {
        if (!await downloadsDirectory.exists()) {
          await downloadsDirectory.create(recursive: true);
        }
        final filePath = '${downloadsDirectory.path}/$pdfName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        Fluttertoast.showToast(msg: "Saved to $filePath");
      } else {
        Fluttertoast.showToast(msg: "Unable to get the downloads directory");
      }
      // Await the dialogFuture in case it's still active.
      await dialogFuture;
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving PDF: $e");
    }
  }

  Future<void> _openPdf(String pdfUrl, String pdfName) async {
    final Uri url = Uri.parse(pdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Fluttertoast.showToast(msg: "Could not launch PDF");
    }
  }


  Future<void> _confirmDeleteMessage(DocumentSnapshot document) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.delete_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Delete Message', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Are you sure you want to delete this message?', style: TextStyle(fontFamily: 'Outfit')),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
              label: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Delete', style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      try {
        final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        // If the message is an image (1) or a PDF (2), attempt to delete from storage.
        if (data['type'] == 1 || data['type'] == 2) {
          String fileUrl = data['content'];
          try {
            debugPrint("Attempting to delete file at URL: $fileUrl");
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
            debugPrint("File deleted successfully.");
          } catch (e) {
            // Log the error details for further troubleshooting.
            debugPrint("Error deleting file from storage: $e");
          }
        }
        // Delete the Firestore document regardless.
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(groupChatId)
            .collection('chats')
            .doc(document.id)
            .delete();
        Fluttertoast.showToast(msg: 'Message deleted successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error deleting message: $e');
      }
    }
  }
}