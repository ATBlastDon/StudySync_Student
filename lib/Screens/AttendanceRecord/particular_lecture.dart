import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studysync_student/Screens/AttendanceRecord/particular_sheet.dart';

class ParticularLecture extends StatefulWidget {
  final String year;
  final String sem;
  final String sub;
  final String type;
  final String fullName;
  final String rollNo;
  final String optionalSubject; // Pass empty string if not applicable

  const ParticularLecture({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.sub,
    required this.type,
    required this.optionalSubject,
    required this.fullName,
  });

  @override
  State<ParticularLecture> createState() =>
      _ParticularLectureState();
}

class _ParticularLectureState extends State<ParticularLecture> {
  DateTime? fromDate;
  DateTime? toDate;

  double averagePercentage = 0.0;
  List<Map<String, dynamic>> attendanceData = [];

  /// Determines if the subject requires an extra path layer.
  bool get isDLOCOrILOC =>
      widget.sub.startsWith('DLOC') || widget.sub.startsWith('ILOC');

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> fetchAttendanceData() async {
    if (fromDate == null || toDate == null) {
      Fluttertoast.showToast(
        msg: "Please select both from and to dates",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      Query query;

      if (isDLOCOrILOC) {
        query = firestore
            .collection('attendance')
            .doc(widget.year)
            .collection(widget.sem)
            .doc(widget.sub)
            .collection(widget.optionalSubject)
            .doc(widget.type)
            .collection('lecture')
            .where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate!))
            .where('created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate!));
      } else {
        query = firestore
            .collection('attendance')
            .doc(widget.year)
            .collection(widget.sem)
            .doc(widget.sub)
            .collection(widget.type)
            .where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate!))
            .where('created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate!));
      }

      QuerySnapshot querySnapshot = await query.get();

      List<Map<String, dynamic>> data = [];
      double totalPercentage = 0.0;

      for (var doc in querySnapshot.docs) {
        final lecture = doc.data() as Map<String, dynamic>;
        if (lecture.containsKey('percentage')) {
          double percentage =
              double.tryParse(lecture['percentage'].toString()) ?? 0.0;
          data.add(lecture);
          totalPercentage += percentage;
        }
      }

      double average = data.isNotEmpty ? totalPercentage / data.length : 0.0;

      setState(() {
        attendanceData = data;
        averagePercentage = average;
      });

      if (attendanceData.isNotEmpty) {
        _navigateToAttendanceSheet();
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Error fetching attendance data",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _navigateToAttendanceSheet() {
    if (attendanceData.length > 10) {
      Fluttertoast.showToast(
        msg: "Too many days to fit in PDF. Please narrow down the date range.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticularSheet(
          year: widget.year,
          sem: widget.sem,
          sub: widget.sub,
          type: widget.type,
          optionalSubject: widget.optionalSubject,
          fromDate: fromDate!,
          toDate: toDate!,
          attendanceData: attendanceData,
          rollNo: widget.rollNo,
          fullName: widget.fullName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrapping entire content in a SingleChildScrollView for vertical scrolling
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
          icon:
          const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Center( // Center the text
                  child: RichText( // Use RichText for bolding "Note:"
                    textAlign: TextAlign.center, // Center the text within RichText
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Note: ", // Make "Note:" bold
                          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black,fontSize: 22),
                        ),
                        TextSpan(
                          text:
                          "\nSelect the date range for which you'd like to view or generate the attendance sheet.\nVery wide date ranges might not be supported.",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              FadeInUp(
                duration: const Duration(milliseconds: 900),
                child: ListTile(
                  title: const Text('From Date',
                      style: TextStyle(fontFamily: 'Outfit')),
                  subtitle: Text(
                    fromDate == null
                        ? 'Select a date'
                        : '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}',
                    style: const TextStyle(fontFamily: 'Outfit'),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: ListTile(
                  title: const Text('To Date',
                      style: TextStyle(fontFamily: 'Outfit')),
                  subtitle: Text(
                    toDate == null
                        ? 'Select a date'
                        : '${toDate!.day}/${toDate!.month}/${toDate!.year}',
                    style: const TextStyle(fontFamily: 'Outfit'),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
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
                            colors: [Colors.greenAccent, Colors.teal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: MaterialButton(
                          minWidth: double.infinity,
                          height: 60,
                          onPressed: fetchAttendanceData,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            alignment: Alignment.center,
                            child: const Text(
                              'Generate Attendance Sheet',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
