import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:studysync_student/Screens/AttendanceRecord/cumulative_attendance.dart';
import 'package:studysync_student/Screens/AttendanceRecord/lecture_attendance.dart';

class AttendanceHome extends StatefulWidget {
  final String year;
  final String sem;
  final String rollNo;
  final String batch;
  final String ay;
  final String dept;
  final String fullName;
  final String clg;


  const AttendanceHome({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.batch,
    required this.fullName,
    required this.ay,
    required this.dept,
    required this.clg

  });

  @override
  State<AttendanceHome> createState() => _AttendanceHomeState();
}

class _AttendanceHomeState extends State<AttendanceHome> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Attendance Options",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Please Read note given below and choose your option",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Note:",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Text.rich( // Use Text.rich
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                    ),
                    children: <TextSpan>[
                      const TextSpan(
                        text: "• ",
                      ),
                      const TextSpan(
                        text: "Lecture Attendance: ", // Bold text
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const TextSpan(
                        text: "In this section, students can check the days they attended lectures or labs for a particular subject in the attendance sheet.\n\n",
                      ),
                      const TextSpan(
                        text: "• ",
                      ),
                      const TextSpan(
                        text: "Cumulative Attendance: ", // Bold text
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const TextSpan(
                        text: "This section provides students with a comprehensive overview of their overall attendance across all subjects. It displays the total number of lectures attended and the percentage of attendance, helping students track their progress and ensure they meet the required attendance criteria.",
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: const Border(
                        bottom: BorderSide(color: Colors.black),
                        top: BorderSide(color: Colors.black),
                        left: BorderSide(color: Colors.black),
                        right: BorderSide(color: Colors.black),
                      ),
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(50), // Keeps it rounded
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.greenAccent, Colors.teal], // Your required colors
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50), // Matches button shape
                        ),
                        child: MaterialButton(
                          minWidth: double.infinity,
                          height: 60,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LectureAttendance(
                                  year: widget.year,
                                  sem: widget.sem,
                                  rollNo: widget.rollNo,
                                  batch: widget.batch,
                                  fullName: widget.fullName,
                                  ay: widget.ay,
                                  dept: widget.dept,
                                  clg: widget.clg
                                ),
                              ),
                            );
                          },
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            "Lecture Attendance",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black, // Ensures readability on gradient
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(50),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orangeAccent, Colors.deepOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: MaterialButton(
                          minWidth: double.infinity,
                          height: 60,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CumulativeAttendance(
                                  year: widget.year,
                                  sem: widget.sem,
                                  rollNo: widget.rollNo,
                                  batch: widget.batch,
                                  fullName: widget.fullName,
                                  ay: widget.ay,
                                  dept: widget.dept,
                                  clg: widget.clg
                                ),
                              ),
                            );
                          },
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            "Cumulative Attendance",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}