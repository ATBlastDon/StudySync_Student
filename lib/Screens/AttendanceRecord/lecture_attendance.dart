import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studysync_student/Screens/AttendanceRecord/particular_lecture.dart';

class LectureAttendance extends StatefulWidget {
  final String year;
  final String sem;
  final String fullName;
  final String rollNo;
  final String batch;
  final String ay;
  final String dept;

  const LectureAttendance({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.batch,
    required this.fullName,
    required this.ay,
    required this.dept,
  });

  @override
  State<LectureAttendance> createState() => _LectureAttendanceState();
}

class _LectureAttendanceState extends State<LectureAttendance> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Selected values for the dropdowns.
  String? selectedLabOrTheory;
  String? selectedSubject;
  String? selectedOptionalSubject; // Dropdown for optional subject

  List<Map<String, dynamic>> lectures = [];

  /// Firebase subjects mapping.
  Map<String, dynamic> subjectsMapping = {};

  @override
  void initState() {
    super.initState();
    _fetchSubjectsMapping();
  }

  /// Fetch the subjects mapping from Firestore.
  Future<void> _fetchSubjectsMapping() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.dept)
          .get();
      if (snapshot.exists) {
        setState(() {
          subjectsMapping = snapshot.data() as Map<String, dynamic>;
        });
      } else {
        Fluttertoast.showToast(msg: "Subjects mapping not found");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching subjects mapping: $e");
    }
  }

  /// Get available regular subjects for the selected Lab/Theory.
  List<String> getAvailableSubjects() {
    if (subjectsMapping.isNotEmpty &&
        subjectsMapping.containsKey(widget.year) &&
        selectedLabOrTheory != null) {
      final classMap = subjectsMapping[widget.year] as Map<String, dynamic>;
      if (classMap.containsKey(widget.sem)) {
        final semData = classMap[widget.sem] as Map<String, dynamic>;
        // Use lower-case keys for comparison.
        final key = selectedLabOrTheory!.toLowerCase();
        if (key == "lab" && semData.containsKey("lab")) {
          return List<String>.from(semData["lab"]);
        } else if (key == "theory" && semData.containsKey("theory")) {
          return List<String>.from(semData["theory"]);
        }
      }
    }
    return [];
  }

  /// Returns available optional subjects for the given subject.
  List<String> getAvailableOptionalSubjects(String subject) {
    if (subjectsMapping.isNotEmpty &&
        subjectsMapping.containsKey(widget.year)) {
      final classMap = subjectsMapping[widget.year] as Map<String, dynamic>;
      if (classMap.containsKey(widget.sem)) {
        final semData = classMap[widget.sem] as Map<String, dynamic>;
        if (subject.toUpperCase().startsWith("DLOC") && semData.containsKey("dloc")) {
          final dlocMap = semData["dloc"] as Map<String, dynamic>;
          if (dlocMap.containsKey(subject)) {
            return List<String>.from(dlocMap[subject]);
          }
        } else if (subject.toUpperCase().startsWith("ILOC") && semData.containsKey("iloc")) {
          final ilocMap = semData["iloc"] as Map<String, dynamic>;
          if (ilocMap.containsKey(subject)) {
            return List<String>.from(ilocMap[subject]);
          }
        }
      }
    }
    return [];
  }

  Future<void> fetchLectureHistory() async {
    if (_formKey.currentState!.validate()) {
      try {
        Query attendanceQuery;

        // Adjust the query path if an optional subject is selected.
        if ((selectedSubject?.toUpperCase().startsWith('DLOC') == true ||
            selectedSubject?.toUpperCase().startsWith('ILOC') == true) &&
            selectedOptionalSubject != null) {
          // Path: attendance/{year}/{sem}/{subject}/{optionalSubject}/{lab_or_theory}
          attendanceQuery = FirebaseFirestore.instance
              .collection("attendance")
              .doc(widget.dept)
              .collection(widget.ay)
              .doc(widget.year)
              .collection(widget.sem)
              .doc(selectedSubject!) // The base optional subject key.
              .collection(selectedOptionalSubject!) // The chosen optional subject.
              .doc(selectedLabOrTheory!)
              .collection("lecture");
        } else {
          // Default path: attendance/{year}/{sem}/{subject}/{lab_or_theory}
          attendanceQuery = FirebaseFirestore.instance
              .collection("attendance")
              .doc(widget.dept)
              .collection(widget.ay)
              .doc(widget.year)
              .collection(widget.sem)
              .doc(selectedSubject!)
              .collection(selectedLabOrTheory!);
        }

        // If Lab is selected, filter by batch.
        if (selectedLabOrTheory == 'Lab') {
          attendanceQuery = attendanceQuery.where('batch', isEqualTo: widget.batch);
        }

        final snapshot = await attendanceQuery.get();
        lectures.clear();

        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Convert timestamps to DateTime.
            DateTime createdAt = (data['created_at'] as Timestamp).toDate();
            DateTime expiresAt = data['expires_at'] != null
                ? (data['expires_at'] as Timestamp).toDate()
                : DateTime.now();

            lectures.add({
              'year': widget.year,
              'sem': widget.sem,
              'subject': selectedSubject,
              'ay': widget.ay,
              'dept': widget.dept,
              'optional_sub': selectedOptionalSubject ?? 'N/A',
              'type': selectedLabOrTheory,
              'batch': data['batch'],
              'created_at': createdAt,
              'expires_at': expiresAt,
            });
          }

          Fluttertoast.showToast(
            msg: 'Lectures history fetched successfully!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'No Lecture records found.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error fetching Lecture history: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  void _showNoticeDialogue() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          title: Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'Tip',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Outfit',
                    fontSize: 16),
                children: <TextSpan>[
                  TextSpan(
                    text: "Lab/Theory: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "Select whether you want to view Lab or Theory lectures.\n\n",
                  ),
                  TextSpan(
                    text: "Subject: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "Choose the subject for which you want to see the attendance records.\n\n",
                  ),
                  TextSpan(
                    text: "Fetch Result: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "After selecting all the criteria, click 'Fetch Result' to view the attendance records.",
                  ),
                ],
              ),
            ),
          ),
          actionsPadding:
          const EdgeInsets.only(bottom: 16.0, right: 16.0),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: 'Outfit',
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'L E C T U R E   R E C O R D S',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: _showNoticeDialogue,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 30),
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: const Text(
                    "Check Lecture Records",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: DropdownButtonFormField<String>(
                    value: selectedLabOrTheory,
                    items: ['Lab', 'Theory'].map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: TextStyle(fontFamily: 'Outfit'),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLabOrTheory = value;
                        selectedSubject = null;
                        selectedOptionalSubject = null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Lab/Theory',
                      labelStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Subject Dropdown
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: DropdownButtonFormField<String>(
                    value: selectedSubject,
                    items: getAvailableSubjects().map((String subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(
                          subject,
                          style: TextStyle(fontFamily: 'Outfit'),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value;
                        // Reset optional subject when subject changes.
                        selectedOptionalSubject = null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      labelStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // If subject is optional (starts with DLOC or ILOC), show Optional Subject dropdown.
                if (selectedSubject != null &&
                    (selectedSubject!.toUpperCase().startsWith('DLOC') ||
                        selectedSubject!.toUpperCase().startsWith('ILOC')))
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: DropdownButtonFormField<String>(
                      value: selectedOptionalSubject,
                      items: getAvailableOptionalSubjects(selectedSubject!)
                          .map((String optSubj) {
                        return DropdownMenuItem<String>(
                          value: optSubj,
                          child: Text(
                            optSubj,
                            style: TextStyle(fontFamily: 'Outfit'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedOptionalSubject = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Optional Subject',
                        labelStyle: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                      ),
                    ),
                  ),
                if (selectedSubject != null &&
                    (selectedSubject!.toUpperCase().startsWith('DLOC') ||
                        selectedSubject!.toUpperCase().startsWith('ILOC')))
                  const SizedBox(height: 30),
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
                            onPressed: () {
                              if (_formKey.currentState!.validate() &&
                                  selectedLabOrTheory != null &&
                                  selectedSubject != null &&
                                  (!selectedSubject!.toUpperCase().startsWith('DLOC') &&
                                      !selectedSubject!.toUpperCase().startsWith('ILOC') ||
                                      selectedOptionalSubject != null)) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParticularLecture(
                                      year: widget.year,
                                      sem: widget.sem,
                                      type: selectedLabOrTheory!, // Safe to use !
                                      sub: selectedSubject!, // Safe to use !
                                      optionalSubject: selectedOptionalSubject ?? 'N/A',
                                      rollNo: widget.rollNo,
                                      fullName: widget.fullName,
                                      batch: widget.batch,
                                      ay: widget.ay,
                                      dept: widget.dept,
                                    ),
                                  ),
                                );
                              } else {
                                Fluttertoast.showToast(
                                  msg: 'Please select all required fields.',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                              }
                            },
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              alignment: Alignment.center,
                              child: const Text(
                                'Fetch Result',
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
      ),
    );
  }
}
