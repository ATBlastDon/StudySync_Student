import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studysync_student/Screens/AttendanceRecord/cumulative_sheet.dart';

class CumulativeAttendance extends StatefulWidget {
  final String rollNo;
  final String year;
  final String batch;
  final String sem;
  final String fullName;
  final String ay;
  final String dept;

  const CumulativeAttendance({
    super.key,
    required this.rollNo,
    required this.fullName,
    required this.year,
    required this.batch,
    required this.sem,
    required this.ay,
    required this.dept,
  });

  @override
  State<CumulativeAttendance> createState() => _CumulativeAttendanceState();
}

class _CumulativeAttendanceState extends State<CumulativeAttendance> {
  // Instead of local mappings, we now load the configuration from Firebase.
  Map<String, dynamic> subjectsMapping = {};
  bool isMappingLoading = true;
  bool isLoading = false;
  String? errorMessage;

  // List of subjects selected by the user.
  List<String> selectedSubjects = [];

  // List of students fetched from Firebase.
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _fetchSubjectsMapping();
  }

  /// Fetch the subjects mapping from Firestore.
  Future<void> _fetchSubjectsMapping() async {
    setState(() => isMappingLoading = true);
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
        setState(() {
          errorMessage = "Subjects mapping not found";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading subjects mapping: $e";
      });
    } finally {
      setState(() => isMappingLoading = false);
    }
  }

  /// Returns available semesters for the given year.
  List<String> getAvailableSemesters(String year) {
    if (subjectsMapping.containsKey(year)) {
      final classMap = subjectsMapping[year] as Map<String, dynamic>;
      return classMap.keys.toList();
    }
    return [];
  }

  /// Returns available subjects for the given year and sem by combining
  /// both theory and lab subjects.
  List<String> getAvailableSubjects(String year, String sem) {
    List<String> subjectsList = [];
    if (subjectsMapping.containsKey(year)) {
      final classMap = subjectsMapping[year] as Map<String, dynamic>;
      if (classMap.containsKey(sem)) {
        final semData = classMap[sem] as Map<String, dynamic>;
        if (semData.containsKey("theory")) {
          subjectsList.addAll(List<String>.from(semData["theory"]));
        }
        if (semData.containsKey("lab")) {
          subjectsList.addAll(List<String>.from(semData["lab"]));
        }
      }
    }
    // Optional: Remove duplicates and sort.
    subjectsList = subjectsList.toSet().toList()..sort();
    return subjectsList;
  }

  /// Returns available optional subjects for a given subject.
  /// Checks the "dloc" and "iloc" keys in the mapping.
  List<String> getAvailableOptionalSubjects(String year, String sem, String subject) {
    if (subjectsMapping.containsKey(year)) {
      final classMap = subjectsMapping[year] as Map<String, dynamic>;
      if (classMap.containsKey(sem)) {
        final semData = classMap[sem] as Map<String, dynamic>;
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

  /// Fetch approved students for the given year and sem.
  Future<List<Map<String, dynamic>>> fetchApprovedStudents(String year, String sem) async {
    List<Map<String, dynamic>> fetchedStudents = [];
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.dept)
          .collection(widget.ay)
          .doc(year)
          .collection(sem)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      for (var doc in querySnapshot.docs) {
        fetchedStudents.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching students: $e');
    }
    return fetchedStudents;
  }

  Future<void> _fetchStudents() async {
    if (selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one subject',
              style: TextStyle(fontFamily: 'Outfit')),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> fetchedStudents =
    await fetchApprovedStudents(widget.year, widget.sem);

    setState(() {
      students = fetchedStudents;
      isLoading = false;
    });

    if (!mounted) return;
    if (students.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CumulativeSheet(
            selectedClass: widget.year,
            selectedSem: widget.sem,
            selectedSubjects: selectedSubjects,
            rollNo: widget.rollNo,
            fullName: widget.fullName,
            ay: widget.ay,
            dept: widget.dept,
            batch: widget.batch,
          ),
        ),
      );
    }
  }

  /// Build checkboxes for subjects using the Firebase mapping.
  List<Widget> _buildSubjectCheckboxes() {
    // Get regular subjects from Firebase mapping.
    List<String> theorySubjects = [];
    List<String> labSubjects = [];
    if (subjectsMapping.containsKey(widget.year)) {
      final classMap = subjectsMapping[widget.year] as Map<String, dynamic>;
      if (classMap.containsKey(widget.sem)) {
        final semData = classMap[widget.sem] as Map<String, dynamic>;
        if (semData.containsKey("theory")) {
          theorySubjects = List<String>.from(semData["theory"]);
        }
        if (semData.containsKey("lab")) {
          labSubjects = List<String>.from(semData["lab"]);
        }
      }
    }
    List<String> regularSubjects = [...theorySubjects, ...labSubjects];

    // Get optional subjects from both "dloc" and "iloc" keys.
    List<String> optionalSubjects = [];
    if (subjectsMapping.containsKey(widget.year)) {
      final classMap = subjectsMapping[widget.year] as Map<String, dynamic>;
      if (classMap.containsKey(widget.sem)) {
        final semData = classMap[widget.sem] as Map<String, dynamic>;
        if (semData.containsKey("dloc") && semData["dloc"] is Map) {
          optionalSubjects.addAll((semData["dloc"] as Map<String, dynamic>).keys);
        }
        if (semData.containsKey("iloc") && semData["iloc"] is Map) {
          optionalSubjects.addAll((semData["iloc"] as Map<String, dynamic>).keys);
        }
      }
    }

    // Combine the lists and remove duplicates.
    List<String> allSubjects = [...regularSubjects, ...optionalSubjects];
    allSubjects = allSubjects.toSet().toList()..sort();

    return allSubjects.map((subject) {
      return CheckboxListTile(
        title: Text(subject, style: const TextStyle(fontFamily: 'Outfit')),
        value: selectedSubjects.contains(subject),
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedSubjects.add(subject);
            } else {
              selectedSubjects.remove(subject);
            }
          });
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Attendance Options",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                      ),
                      children: <TextSpan>[
                        const TextSpan(
                          text: "Note:\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                          "Select the subjects to fetch Student Attendance.",
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Subjects',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    ..._buildSubjectCheckboxes(),
                  ],
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
                          onPressed: _fetchStudents,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Fetch',
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
              if (isLoading) const CircularProgressIndicator(color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
