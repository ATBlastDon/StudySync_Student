import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:studysync_student/Screens/Repeated_Functions/show_zoom_profile.dart';
import 'package:studysync_student/Screens/Security/privacysecurity.dart';
import 'package:studysync_student/Screens/StudentHome/missing_screen.dart';
import 'package:studysync_student/Screens/StudentHome/student_content.dart';
import 'package:studysync_student/Screens/StudentHome/studentprofile.dart';
import 'package:studysync_student/Screens/StudentHome/teacher_content.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class StudentInternal extends StatefulWidget {
  final String year;
  final String sem;
  final String dept;
  final String ay;
  final String clg;

  const StudentInternal({
    super.key,
    required this.year,
    required this.sem,
    required this.dept,
    required this.ay,
    required this.clg
  });

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

  // Connectivity flag and subscription
  bool _isConnected = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Notification plugin instance
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _isLoading = false;
  bool isUpdating = false;


  @override
  void initState() {
    super.initState();

    // Initialize connectivity
    Connectivity().checkConnectivity().then((result) {
      final ConnectivityResult connectivityResult =
      result.isNotEmpty ? result.first : result as ConnectivityResult;
      setState(() {
        _isConnected = (connectivityResult != ConnectivityResult.none);
      });
    });
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .map<ConnectivityResult>((result) =>
    result.isNotEmpty ? result.first : ConnectivityResult.none)
        .listen((connectivityResult) {
      setState(() {
        _isConnected = (connectivityResult != ConnectivityResult.none);
      });
    });

    // Initialize flutter_local_notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_notification_icon');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permission using permission_handler
    _requestNotificationPermission();

    fetchUserData();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      debugPrint('Notification permission granted');
    } else {
      debugPrint('Notification permission denied');
    }
  }


  Future<void> fetchUserData() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email!;
      });
      await fetchUserInfo(user.email!);
    }

    setState(() {
      _isLoading = false; // Stop loading after fetching data
    });
  }

  Future<void> fetchUserInfo(String email) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection("students")
          .doc(widget.ay)
          .collection(widget.year)
          .doc(widget.sem)
          .collection('details')
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

        List<String> missingReq = [];
        if (userData['batch'] == null ||
            userData['batch'].toString().trim().isEmpty ||
            userData['batch'] == "none") {
          missingReq.add('batch');
        }
        if (userData['mentor'] == null ||
            userData['mentor'].toString().trim().isEmpty ||
            userData['mentor'] == "none") {
          missingReq.add('mentor');
        }

        if (widget.year != "SE" && _userRollNo != null) {
          bool isDLOCFilled = await checkDLOCFilled();
          if (!isDLOCFilled) {
            missingReq.add('dloc');
          }
        }

        if (missingReq.isNotEmpty && mounted) {
          // If there are missing requirements, navigate to the MissingRequirementsScreen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MissingRequirementsScreen(
                  missingRequirements: missingReq,
                  year: widget.year,
                  sem: widget.sem,
                  dept: widget.dept,
                  ay: widget.ay,
                  rollNo: _userRollNo!,
                  batch: _userBatch!,
                  studentEmail: _email,
                  clg: widget.clg,
                  onRequirementsUpdated: () {
                    // Refresh user data after updates.
                    fetchUserData();
                  },
                ),
              ),
            ).then((_) {
              // Once the screen is popped, fetch attendance info.
              if (_userRollNo != null) {
                fetchAttendanceInfo();
              }
            });
          });
        } else {
          // No missing requirements – trigger attendance check immediately.
          if (_userRollNo != null) {
            fetchAttendanceInfo();
          }
        }
      } else {
        Fluttertoast.showToast(msg: 'User Not Found in Database');
      }
    } catch (error) {
      Fluttertoast.showToast(msg: 'Error occurred: $error');
    }
  }

  Future<bool> checkDLOCFilled() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection("students")
          .doc(widget.ay)
          .collection(widget.year)
          .doc(widget.sem)
          .collection('details')
          .doc(_userRollNo!)
          .collection("optional_subjects")
          .doc(widget.sem)
          .get();

      return doc.exists && doc.data() != null && doc.data()!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchAttendanceInfo() async {
    try {
      // Check global notification setting.
      DocumentSnapshot<Map<String, dynamic>> notificationSnapshot =
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc("warning_notification")
          .get();
      bool notificationEnabled = notificationSnapshot.data()?['value'] ?? false;

      // If notifications are not enabled, do nothing.
      if (!notificationEnabled) return;

      // Fetch the student's attendance record.
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection("students")
          .doc(widget.ay)
          .collection(widget.year)
          .doc(widget.sem)
          .collection("records")
          .doc(_userRollNo!)
          .get();

      final userData = documentSnapshot.data()!;
      final overall = userData['overall'] ?? 0.0;

      if (!mounted) return;
      // Instead of showing a dialog, send a notification if attendance is below 75%.
      if (overall < 75.0) {
        _showAttendanceNotification(overall);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg:
        "No Attendance Record Found. Update Attendance Record from Attendance Record-Cumulative Attendance Page.",
      );
    }
  }

  Future<void> _showAttendanceNotification(double overall) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'attendance_channel',
      'Attendance',
      channelDescription: 'Notification channel for attendance alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Attendance Alert!',
      'Your current attendance is ${overall.toStringAsFixed(1)}% which is below the required 75%',
      platformChannelSpecifics,
      payload: 'attendance_alert',
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator(color: Colors.black,)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
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
              color: Colors.black,
              strokeWidth: 3.0,
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
                      dept: widget.dept,
                      ay: widget.ay,
                      clg: widget.clg
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
        backgroundColor: Colors.white,
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
                  onTap: () {
                    showZoomedProfile(context, _userProfilePhotoUrl);
                  },
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
                        dept: widget.dept,
                        ay: widget.ay,
                        sem: widget.sem,
                        clg: widget.clg,
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
                        ay: widget.ay,
                        dept: widget.dept,
                        clg: widget.clg,
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
                        dept: widget.dept,
                        ay: widget.ay,
                        clg: widget.clg,
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
                        dept: widget.dept,
                        ay: widget.ay,
                        clg: widget.clg,
                      ),
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
                        dept: widget.dept,
                        ay: widget.ay,
                        clg: widget.clg
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
                        dept: widget.dept,
                        ay: widget.ay,
                        clg: widget.clg,
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
                      builder: (context) => PrivacySettingsScreen(
                        year: widget.year,
                        rollNo: _userRollNo!,
                        sem: widget.sem,
                        dept: widget.dept,
                        ay: widget.ay,
                        clg: widget.clg,
                      ),
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
                    MaterialPageRoute(builder: (context) => const AboutTeam()),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: Colors.black),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 17),
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
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 17),
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
                child: StudentsContent(sem: widget.sem, dept: widget.dept, ay: widget.ay, email: _email, clg: widget.clg, year: widget.year,),
              )
                  : FadeIn(
                duration: const Duration(milliseconds: 500),
                child: TeachersContent(sem: widget.sem, dept: widget.dept, ay: widget.ay, email: _email, clg: widget.clg, year: widget.year,),
              ),
            ),
          ),
        ],
      ),
      // Inside your StudentInternal widget build method, where the floatingActionButton is defined.
        floatingActionButton: Stack(
          children: [
            // NoticeBoard FloatingActionButton wrapped in StreamBuilder.
            Positioned(
              bottom: 10,
              left: 40,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .doc("noticeboard")
                    .collection("notices")
                    .where('dept', isEqualTo: widget.dept)
                    .where('ay', isEqualTo: widget.ay)
                    .where('clg', isEqualTo: widget.clg)
                    .where('batch', whereIn: [widget.year, 'ALL'])
                    .snapshots(),
                builder: (context, snapshot) {
                  bool hasNewNotice = false;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final unreadDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final List<dynamic> readBy = data['readby'] ?? [];
                      return !readBy.contains(_userRollNo);
                    }).toList();
                    hasNewNotice = unreadDocs.isNotEmpty;
                  }

                  return Stack(
                    children: [
                      BounceInUp(
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
                                  builder: (context) => NoticeBoard(
                                    year: widget.year,
                                    dept: widget.dept,
                                    ay: widget.ay,
                                    rollNo: _userRollNo!,
                                    clg: widget.clg,
                                  ),
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
                      if (hasNewNotice)
                        Positioned(
                          bottom: 40,
                          left: 40,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            // Second FloatingActionButton (fab2) outside the stream builder.
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
                        _userFullName!,
                        widget.dept,
                        widget.ay,
                        widget.clg
                    ),
                    tooltip: 'Scan QR Code',
                    backgroundColor: Colors.transparent,
                    elevation: 5,
                    shape: const CircleBorder(),
                    child:
                    const Icon(Icons.announcement_outlined, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        )
    );
  }
}

void _openAttendanceAnnouncement(
    BuildContext context,
    String year,
    String rollNo,
    String sem,
    String batch,
    String fullName,
    String dept,
    String ay,
    String clg) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AttendanceAnnouncement(
        classYear: year,
        rollNo: rollNo,
        sem: sem,
        batch: batch,
        fullName: fullName,
        dept: dept,
        ay: ay,
        clg: clg
      ),
    ),
  );
}