import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studysync_student/AboutUs/aboutteam.dart';
import 'package:studysync_student/Screens/AttendanceAnnouncement/announcement.dart';
import 'package:studysync_student/Screens/AttendanceAnnouncement/faceregistration.dart';
import 'package:studysync_student/Screens/AttendanceRecord/attendance_home.dart';
import 'package:studysync_student/Screens/Chat/searchscreen.dart';
import 'package:studysync_student/Screens/Forms/leave_forms.dart';
import 'package:studysync_student/Screens/Forms/forms.dart';
import 'package:studysync_student/Screens/Lecture/dloc.dart';
import 'package:studysync_student/Screens/Marks/marks_home.dart';
import 'package:studysync_student/Screens/NoticeBoard/noticeboard.dart';
import 'package:studysync_student/Screens/Security/privacysecurity.dart';
import 'package:studysync_student/Screens/StudentHome/student_content.dart';
import 'package:studysync_student/Screens/StudentHome/studentprofile.dart';
import 'package:studysync_student/Screens/StudentHome/teacher_content.dart';
import 'package:studysync_student/Screens/WebView/mywebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class StudentInternal extends StatefulWidget {
  final String year;
  final String sem;
  const StudentInternal({super.key, required this.year, required this.sem});

  @override
  State<StudentInternal> createState() => _StudentInternalState();
}

class _StudentInternalState extends State<StudentInternal> {
  String _selectedSection = 'students';
  String? _userFullName;
  String? _userEmail;
  String? _userBatch;
  String? _userMentor;
  String _email = '';
  String? _userRollNo;
  String? _userProfilePhotoUrl;
  static const String famt = 'https://famt.akronsystems.com/pLogin.aspx';

  // Connectivity flag and subscription
  bool _isConnected = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((result) {
      // When running on platforms where result might be a List, handle it:
      final ConnectivityResult connectivityResult =
      result.isNotEmpty
          ? result.first
          : result as ConnectivityResult;
      setState(() {
        _isConnected = (connectivityResult != ConnectivityResult.none);
      });
    });
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .map<ConnectivityResult>((result) {
      // If the result is a List, extract the first element.
      return result.isNotEmpty ? result.first : ConnectivityResult.none;
    }).listen((connectivityResult) {
      setState(() {
        _isConnected = (connectivityResult != ConnectivityResult.none);
      });
    });

    fetchUserData();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email!;
      });
      await fetchUserInfo(user.email!);
    }
  }

  Future<void> fetchUserInfo(String email) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.year)
          .collection(widget.sem)
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          _userFullName =
          '${userData['fname']} ${userData['mname'] ?? ''} ${userData['sname'] ?? ''}';
          _userProfilePhotoUrl = userData['profilePhotoUrl'];
          _userEmail = userData['email'];
          _userRollNo = userData['rollNo'];
          _userBatch = userData['batch'];
          _userMentor = userData['mentor'];
        });

        if (_userRollNo != null) {
          fetchAttendanceInfo();
        }
        if (_userRollNo != null && widget.year != "SE") {
          fetchDLOCInfo();
        }

        if(!mounted) return;
        if (_userBatch == "none") {
          _showBatchRequiredDialog(context);
          await Future.delayed(const Duration(seconds: 1)); // 1 second delay
        }

        if(!mounted) return;
        if (_userMentor == "none") {
          _showMentorDialog(context);
          await Future.delayed(const Duration(seconds: 1)); // 1 second delay
        }

      } else {
        Fluttertoast.showToast(
          msg: 'User Not Found in Database',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (error) {
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

  Future<void> fetchDLOCInfo() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.year)
          .collection(widget.sem)
          .doc(_userRollNo!)
          .collection("optional_subjects")
          .doc(widget.sem)
          .get();

      if (!documentSnapshot.exists ||
          documentSnapshot.data() == null ||
          documentSnapshot.data()!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDLOCRequiredDialog(context);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error occurred: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> fetchAttendanceInfo() async {
    try {
      // First, check the global notification setting from Firestore.
      DocumentSnapshot<Map<String, dynamic>> notificationSnapshot =
      await FirebaseFirestore.instance
          .collection('students')
          .doc("notification")
          .get();
      bool notificationEnabled = notificationSnapshot.data()?['value'] ?? false;

      // If notifications are not enabled, do nothing.
      if (!notificationEnabled) return;

      // Now fetch the student's attendance record.
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.year)
          .collection(widget.sem)
          .doc("records")
          .collection("rollno")
          .doc(_userRollNo!)
          .get();

      final userData = documentSnapshot.data()!;
      final overall = userData['overall'] ?? 0.0;

      // If overall attendance is less than 75.0, show the dialog.
      if(!mounted) return;
      if (overall < 75.0) {
        _showAttendanceRequiredDialog(context, overall);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg:
        "No Attendance Record Found. Update Attendance Record from Attendance Record-Cumulative Attendance Page.",
      );
    }
  }

  Future<void> _showDLOCRequiredDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book, // Your icon
                    size: 50,
                    color: Colors.yellowAccent,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Optional Subject Required",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Please fill in your Optional Subject information in your profile.",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      "Go to Fill the Information",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectionSubjects(
                            year: widget.year,
                            sem: widget.sem,
                            rollNo: _userRollNo!,
                            batch: _userBatch!,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttendanceRequiredDialog(BuildContext context, double overall) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded, // You can change the icon
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Low Attendance Alert!",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(
                          text: "Your overall attendance is ",
                        ),
                        TextSpan(
                          text: "${overall.toStringAsFixed(1)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: " which is below 75%.",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      "Okay",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMentorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.assignment_ind,
                    size: 50,
                    color: Colors.yellowAccent,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Mentor Selection Required",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Please fill in your Mentor information in your profile.",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      "Go to Fill the Information",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentProfile(
                            studentmail: _email,
                            studentyear: widget.year,
                            sem: widget.sem,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBatchRequiredDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.group, // Changed icon
                    size: 50,
                    color: Colors.yellowAccent,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Batch Information Required", // Changed title
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Please fill in your batch information in your profile.", // Changed message
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Slightly smaller button radius
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      "Go to Fill the Information", // Changed button text
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentProfile(
                            studentmail: _email,
                            studentyear: widget.year,
                            sem: widget.sem,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          // Conditionally show text or a loading indicator based on connectivity
          child: _isConnected
              ? const Text(
            'S T U D Y  S Y N C',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          )
              : const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.black, strokeWidth: 3.0,
            ),
          ),
        ),
        actions: [
          FadeInRight(
            duration: const Duration(milliseconds: 600),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(
                      currentUserEmail: _email,
                      year: widget.year,
                      sem: widget.sem,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              iconSize: 30,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: FadeInLeft(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _userFullName ?? 'Username',
                  style: const TextStyle(fontFamily: 'Outfit'),
                ),
              ),
              accountEmail: FadeInLeft(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  _userEmail ?? 'user@example.com',
                  style: const TextStyle(fontFamily: 'Outfit'),
                ),
              ),
              currentAccountPicture: FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: GestureDetector(
                  onTap: () => _showZoomedProfile(context),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: _userProfilePhotoUrl != null
                        ? CachedNetworkImageProvider(_userProfilePhotoUrl!)
                        : null,
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 500),
              child: ListTile(
                title: const Text(
                  'Your Profile',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfile(
                        studentmail: _email,
                        studentyear: widget.year,
                        sem: widget.sem,
                      ),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: ListTile(
                title: const Text(
                  'Attendance Records',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceHome(
                        year: widget.year,
                        sem: widget.sem,
                        rollNo: _userRollNo!,
                        batch: _userBatch!,
                        fullName: _userFullName!,
                      ),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: ListTile(
                title: const Text(
                  'Face Registration',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceRegistrationScreen(),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: ListTile(
                title: const Text(
                  'Fill the marks',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarksHome(
                        year: widget.year,
                        sem: widget.sem,
                        rollNo: _userRollNo!,
                        batch: _userBatch!,
                        fullName: _userFullName!,
                      ),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: ListTile(
                title: const Text(
                  'Subject Selection',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectionSubjects(
                        year: widget.year,
                        sem: widget.sem,
                        rollNo: _userRollNo!,
                        batch: _userBatch!,
                      ),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 800),
              child: ListTile(
                title: const Text(
                  'FAMT Login',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyWebView(url: famt),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 900),
              child: ListTile(
                title: const Text(
                  'Compensation Request',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaveForms(
                        year: widget.year,
                        sem: widget.sem,
                        rollNo: _userRollNo!,
                        name: _userFullName!,
                        mentor: _userMentor!,
                      ),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 1000),
              child: ListTile(
                title: const Text(
                  'Submitted Requests',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Forms(
                        year: widget.year,
                        rollNo: _userRollNo!,
                        sem: widget.sem,
                      ),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 1100),
              child: ListTile(
                title: const Text(
                  'Privacy & Security',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacySettingsScreen(),
                    ),
                  );
                },
              ),
            ),
            FadeInLeft(
              duration: const Duration(milliseconds: 1200),
              child: ListTile(
                title: const Text(
                  'About Team',
                  style: TextStyle(fontFamily: 'Outfit'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutTeam()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: Colors.black),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FadeInLeft(
                      duration: const Duration(milliseconds: 500),
                      child: TextButton(
                        onPressed: () {
                          setState(() => _selectedSection = 'students');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _selectedSection == 'students'
                              ? Colors.black
                              : Colors.white,
                        ),
                        child: const Text(
                          'Students',
                          style: TextStyle(
                              fontFamily: 'Outfit', fontSize: 17),
                        ),
                      ),
                    ),
                    FadeInRight(
                      duration: const Duration(milliseconds: 500),
                      child: TextButton(
                        onPressed: () {
                          setState(() => _selectedSection = 'teachers');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _selectedSection == 'teachers'
                              ? Colors.black
                              : Colors.white,
                        ),
                        child: const Text(
                          'Teachers',
                          style: TextStyle(
                              fontFamily: 'Outfit', fontSize: 17),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _selectedSection == 'students'
                  ? FadeIn(
                duration: const Duration(milliseconds: 500),
                child: StudentsContent(_email, widget.year, sem: widget.sem),
              )
                  : FadeIn(
                duration: const Duration(milliseconds: 500),
                child: TeachersContent(_email, widget.year, sem: widget.sem),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 10,
            left: 36,
            child: BounceInUp(
              key: const ValueKey('fab1'),
              duration: const Duration(milliseconds: 500),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoticeBoard(year: widget.year),
                      ),
                    );
                  },
                  tooltip: 'Notice Board',
                  backgroundColor: Colors.transparent,
                  elevation: 5,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.feed, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: BounceInUp(
              key: const ValueKey('fab2'),
              duration: const Duration(milliseconds: 500),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: FloatingActionButton(
                  onPressed: () => _openAttendanceAnnouncement(
                      context,
                      widget.year,
                      _userRollNo!,
                      widget.sem,
                      _userBatch!,
                      _userFullName!),
                  tooltip: 'Scan QR Code',
                  backgroundColor: Colors.transparent,
                  elevation: 5,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.announcement_outlined, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showZoomedProfile(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.0)),
              ),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: CircleAvatar(
                  radius: 150,
                  backgroundColor: Colors.white,
                  backgroundImage: _userProfilePhotoUrl != null
                      ? CachedNetworkImageProvider(_userProfilePhotoUrl!)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _openAttendanceAnnouncement(BuildContext context, String year,
    String rollNo, String sem, String batch, String fullName) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AttendanceAnnouncement(
        classYear: year,
        rollNo: rollNo,
        sem: sem,
        batch: batch,
        fullName: fullName,
      ),
    ),
  );
}