import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:studysync_student/Screens/Chat/wallpaper.dart';

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
  File? _imageFile;
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
      padding: const EdgeInsets.symmetric(horizontal: 8), // Add horizontal padding
      decoration: BoxDecoration(
        color: Colors.white, // Background color for the input area
        borderRadius: BorderRadius.circular(12.0), // Rounded corners for the whole input area
        boxShadow: [ // Add a subtle shadow
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
            icon: const Icon(Icons.image, color: Colors.green),
            onPressed: () {
              _getImage();
            },
          ),
          Expanded(
            child: TextField(
              style: TextStyle(fontFamily: "Outfit"),
              controller: _textEditingController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(fontFamily: 'Outfit', color: Colors.grey), // Style the hint text
                border: InputBorder.none, // Remove the border from the TextField
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Adjust padding inside TextField
              ),
            ),
          ),
          IconButton( // Use IconButton instead of FloatingActionButton for consistency
            icon: const Icon(Icons.send_rounded, color: Colors.green), // Use a rounded send icon
            onPressed: () {
              _sendMessage(0);
            },
          ),
        ],
      ),
    );
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

  void _sendMessage(int messageType) async {
    String messageContent = _textEditingController.text.trim();
    if (messageContent.isNotEmpty || messageType == 1) {
      _textEditingController.clear();
      DocumentReference messageRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection('chats')
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

      if (messageType == 1 && _imageFile != null) {
        // Upload image to storage and get URL
        String imageUrl = await _uploadImageToStorage(_imageFile!);
        messageContent = imageUrl;
      }

      messageRef.set({
        'idFrom': widget.currentUseremail,
        'idTo': widget.peerUseremail,
        'timestamp': DateTime.now(),
        'content': messageContent,
        'type': messageType,
        'status': 'unread',
      });
      _listScrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to send',style: TextStyle(fontFamily: "Outfit",))));
    }
  }

  void _sendImageMessage(File imageFile) async {
    final imageUrl = await _uploadImageToStorage(imageFile);

    DocumentReference messageRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection('chats')
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    messageRef.set({
      'idFrom': widget.currentUseremail,
      'idTo': widget.peerUseremail,
      'timestamp': DateTime.now(),
      'content': imageUrl,
      'type': 1, // 1 for image message type
      'status': 'unread',
    });

    _listScrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }


  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      // Get a reference to the Firebase Storage location
      Reference ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}');

      // Upload the file to Firebase Storage
      UploadTask uploadTask = ref.putFile(imageFile);

      // Get the download URL once the upload is complete
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Return the URL of the uploaded image
      return downloadUrl;
    } catch (error) {
      // Handle any errors that occur during the upload process
      return ''; // Return an empty string if an error occurs
    }
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

  Future<void> _confirmDeleteMessage(DocumentSnapshot document) async {
    bool? confirm = await showDialog<bool>( // Specify return type <bool>
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.delete_outline, color: Colors.red, size: 28), // Red delete icon
              SizedBox(width: 12),
              Text('Delete Message', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Are you sure you want to delete this message?', style: TextStyle(fontFamily: 'Outfit')),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
              label: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Delete', style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                textStyle: const TextStyle(fontFamily: "Outfit"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        );
      },
    );


    if (confirm == true) {
      try {
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


  String _getGroupChatId(String currentUserId, String peerUserId) {
    return currentUserId.hashCode <= peerUserId.hashCode ? '$currentUserId-$peerUserId' : '$peerUserId-$currentUserId';
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }
}

class FullScreenImage extends StatelessWidget {
  final String url;
  const FullScreenImage({super.key, required this.url});

  Future<void> _downloadImage(String imageUrl) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final String timestamp = formatter.format(DateTime.now());
    const savedDir = '/storage/emulated/0/Download/Attendance/Images';
    final fileName = 'attendance_$timestamp.jpg';

    // Check if the directory exists, if not, create it
    final Directory directory = Directory(savedDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Enqueue the download task
    await FlutterDownloader.enqueue(
      url: imageUrl,
      savedDir: savedDir,
      fileName: fileName,
      showNotification: false, // Set this to false to disable the notification
    );


    // Display toast message when the image is saved
    Fluttertoast.showToast(
      msg: "Image saved successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: url,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.black54,
                mini: true,
                onPressed: () => _downloadImage(url),
                child: Icon(Icons.download_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}