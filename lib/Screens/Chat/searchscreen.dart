import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studysync_student/Screens/Chat/chatscreen.dart';

class SearchScreen extends StatefulWidget {
  final String currentUserEmail;
  final String year;
  final String sem;
  final String ay;
  final String dept;

  // Constructor to receive the current user's email
  const SearchScreen({super.key, required this.currentUserEmail, required this.year, required this.sem, required this.ay, required this.dept});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final studentsQuery = FirebaseFirestore.instance
        .collection('students')
        .doc(widget.dept)
        .collection(widget.ay)
        .doc(widget.year)
        .collection(widget.sem)
        .get(); // Fetch all students for the given year

    final teachersQuery = FirebaseFirestore.instance
        .collection('teachers')
        .get(); // Fetch all teachers

    final studentsSnapshot = await studentsQuery;
    final teachersSnapshot = await teachersQuery;

    final List<Map<String, dynamic>> combinedResults = [];

    // Filter students whose fname, mname, or sname contains the query
    for (var doc in studentsSnapshot.docs) {
      final data = doc.data();
      final fullName =
          '${data['fname']} ${data['mname'] ?? ''} ${data['sname']}';
      if (fullName.toLowerCase().contains(query.toLowerCase())) {
        data['fullName'] = fullName;
        data['profilePhotoUrl'] = data['profilePhotoUrl']; // Assign the profile photo URL
        data['role'] = 'Student';
        data['email'] = doc['email']; // Assign the actual email from the document
        data['rollNo'] = doc.id; // Include the student's roll number
        data['year'] = widget.year;
        if (data['email'] != widget.currentUserEmail) {
          combinedResults.add(data);
        }
      }
    }

    // Filter teachers whose fname, mname, or sname contains the query
    for (var doc in teachersSnapshot.docs) {
      final data = doc.data();
      final fullName =
          '${data['fname']} ${data['mname'] ?? ''} ${data['sname']}';
      if (fullName.toLowerCase().contains(query.toLowerCase())) {
        data['fullName'] = fullName;
        data['profilePhotoUrl'] = data['profilePhotoUrl']; // Assign the profile photo URL
        data['role'] = 'Teacher';
        data['email'] = doc['email']; // Assign the actual email from the document
        data['id'] = doc.id;
        data['year'] = "Computer Science AIML"; // Sample year, adjust as needed
        if (data['email'] != widget.currentUserEmail) {
          combinedResults.add(data);
        }
      }
    }

    setState(() {
      _searchResults = combinedResults;
    });

    if (_searchResults.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No students or teachers found.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'S E A R C H',
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
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.grey[100],
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          FadeInDown(
            duration: const Duration(milliseconds: 500), // Set the duration of the animation
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                style: TextStyle(fontFamily: "Outfit"),
                controller: _searchController,
                onChanged: (text) {
                  _search(text); // Automatically search when the text is changed
                },
                decoration: InputDecoration(
                  labelText: 'Search',
                  labelStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _search(''); // Clear search results when the clear button is pressed
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await navigateToChatScreen(result['role'], widget.currentUserEmail, result['email'], result['fullName'], widget.year , widget.sem, widget.ay, widget.dept);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0), // Reduced vertical padding
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: result['profilePhotoUrl'] != null
                                  ? CachedNetworkImageProvider(result['profilePhotoUrl'] as String)
                                  : const AssetImage('assets/profilephoto/default_profile_image.jpg') as ImageProvider<Object>,
                            ),
                            title: Text(
                              result['fullName'] ?? 'No Name',
                              style: const TextStyle(fontFamily: "Outfit", fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result['role'] ?? 'No Role', // Providing a fallback for role
                                  style: const TextStyle(fontFamily: "Outfit", fontSize: 16),
                                ),
                                Text(
                                  result['year'] ?? 'No Year', // Providing a fallback for year
                                  style: const TextStyle(fontFamily: "Outfit", fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Add a divider except for the last item with reduced padding
                      if (index < _searchResults.length - 1)
                        const Divider(color: Colors.black26, thickness: 1, height: 0), // Adjusted height for less space
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> navigateToChatScreen(String role, String currentUserEmail, String peerUserEmail, String chatUserName, String year, String sem, String ay, String dept) async {
    if (role == 'Student' || role == 'Teacher') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUseremail: currentUserEmail, // Pass the current user's email
            peerUseremail: peerUserEmail, // Pass the searched user's email
            chatusername: chatUserName, // Pass the searched user's name
            year: year,
            sem: sem,
            ay: ay,
            dept: dept,
          ),
        ),
      );
    }
  }
}