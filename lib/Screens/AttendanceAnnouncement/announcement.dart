import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studysync_student/Screens/AttendanceAnnouncement/listofattendance.dart';

class AttendanceAnnouncement extends StatefulWidget {
  final String classYear; // For example: BE, TE, or SE
  final String rollNo;
  final String sem;
  final String batch;
  final String ay;
  final String dept;
  final String fullName;
  final String clg;

  const AttendanceAnnouncement({
    super.key,
    required this.classYear,
    required this.rollNo,
    required this.sem,
    required this.batch,
    required this.fullName,
    required this.dept,
    required this.ay,
    required this.clg,

  });

  @override
  State<AttendanceAnnouncement> createState() => _AttendanceAnnouncementState();
}

class _AttendanceAnnouncementState extends State<AttendanceAnnouncement> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = false;

  // Firebase subjects mapping loaded from Firestore.
  Map<String, dynamic> subjectsMapping = {};

  // Selected type (Lab or Theory) and subject.
  String? selectedType; // 'Lab' or 'Theory'
  String? selectedSubject; // Chosen subject from the mapping
  String? selectedOptionalSubject; // If applicable, the actual optional subject chosen by the student

  // Student's optional subject selection fetched from the student's document.
  Map<String, String> optionalMapping = {};

  @override
  void initState() {
    super.initState();
    _fetchSubjectsMapping();
    // Fetch the student's optional subject selection.
    fetchOptionalMapping();
  }

  /// Fetch the subjects mapping from Firestore.
  Future<void> _fetchSubjectsMapping() async {
    setState(() => isLoading = true);
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection('subjects')
          .doc('details')
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
      setState(() => isLoading = false);
    }
  }

  String? errorMessage;

  /// Fetch the student's optional subject selections.
  Future<void> fetchOptionalMapping() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection('students')
          .doc(widget.ay)
          .collection(widget.classYear)
          .doc(widget.sem)
          .collection('details')
          .doc(widget.rollNo)
          .collection('optional_subjects')
          .doc(widget.sem)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          optionalMapping = Map<String, String>.from(snapshot.data()!);
        });
      }
    } catch (e) {
      debugPrint('Error fetching optional mapping: $e');
    }
  }

  /// Returns available subjects based on widget.classYear, widget.sem, and selectedType.
  List<String> getAvailableSubjects() {
    if (subjectsMapping.isNotEmpty &&
        subjectsMapping.containsKey(widget.classYear) &&
        (subjectsMapping[widget.classYear] as Map<String, dynamic>).containsKey(widget.sem) &&
        selectedType != null) {
      final semData = (subjectsMapping[widget.classYear] as Map<String, dynamic>)[widget.sem] as Map<String, dynamic>;
      if (selectedType == "Lab" && semData.containsKey("lab")) {
        return List<String>.from(semData["lab"]);
      } else if (selectedType == "Theory" && semData.containsKey("theory")) {
        return List<String>.from(semData["theory"]);
      }
    }
    return [];
  }

  /// Returns available optional subjects for a given subject.
  /// If the subject starts with "DLOC" or "ILOC" (case-insensitive), it looks under the corresponding key.
  List<String> getAvailableOptionalSubjects(String subject) {
    if (subjectsMapping.isNotEmpty &&
        subjectsMapping.containsKey(widget.classYear) &&
        (subjectsMapping[widget.classYear] as Map<String, dynamic>).containsKey(widget.sem)) {
      final semData = (subjectsMapping[widget.classYear] as Map<String, dynamic>)[widget.sem] as Map<String, dynamic>;
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
    return [];
  }

  Future<void> fetchAnnouncements() async {
    // Ensure that subject and type are selected.
    if (selectedSubject == null || selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both Subject and Type.", style: TextStyle(fontFamily: "Outfit")),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      Query attendanceQuery;

      // If the selected subject is optional, use the student's chosen subject.
      if ((selectedSubject?.toUpperCase().startsWith('DLOC') == true ||
          selectedSubject?.toUpperCase().startsWith('ILOC') == true) &&
          selectedOptionalSubject != null) {
        // Path: attendance/{classYear}/{sem}/{selectedSubject}/{selectedOptionalSubject}/{selectedType}/lecture
        attendanceQuery = FirebaseFirestore.instance
            .collection('colleges')
            .doc(widget.clg)
            .collection('departments')
            .doc(widget.dept)
            .collection("attendance")
            .doc(widget.ay)
            .collection(widget.classYear)
            .doc(widget.sem)
            .collection(selectedSubject!)
            .doc(selectedOptionalSubject!) // Base optional subject key.
            .collection(selectedType!); // Chosen optional subject.
      } else {
        // Default path: attendance/{classYear}/{sem}/{selectedSubject}/{selectedType}
        attendanceQuery = FirebaseFirestore.instance
            .collection('colleges')
            .doc(widget.clg)
            .collection('departments')
            .doc(widget.dept)
            .collection('attendance')
            .doc(widget.ay)
            .collection(widget.classYear)
            .doc(widget.sem)
            .collection(selectedSubject!)
            .doc(selectedType!)
            .collection('lecture');
      }

      // If Lab is selected, filter by the student's batch.
      if (selectedType == 'Lab') {
        attendanceQuery = attendanceQuery.where('batch', isEqualTo: widget.batch);
      }

      attendanceQuery = attendanceQuery.orderBy('created_at', descending: true);

      QuerySnapshot attendanceDocs = await attendanceQuery.get();
      announcements.clear();

      for (var attendanceDoc in attendanceDocs.docs) {
        final data = attendanceDoc.data() as Map<String, dynamic>;
        DateTime createdAt = (data['created_at'] as Timestamp).toDate();
        DateTime expiresAt = data['expires_at'] != null
            ? (data['expires_at'] as Timestamp).toDate()
            : DateTime.now();

        announcements.add({
          'rollNo': widget.rollNo,
          'year': widget.classYear,
          'sem': widget.sem,
          'subject': selectedSubject,
          'fullName': widget.fullName,
          'dept': widget.dept,
          'clg': widget.clg,
          'ay': widget.ay,
          'optional_sub': selectedOptionalSubject ?? "N/A",
          'type': selectedType,
          'batch': data['batch'],
          'created_at': createdAt,
          'expires_at': expiresAt,
        });
      }

      // Remove duplicates if any.
      announcements = announcements.toSet().toList();

      if (announcements.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No Announcements found.", style: TextStyle(fontFamily: "Outfit")),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListOfAttendance(announcements: announcements),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 1000),
          child: const Text(
            'A N N O U N C E M E N T',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black,))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Give Attendance",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Center(
                  child: Text.rich(
                    const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Note:\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        TextSpan(
                          text: "Select the following details to fetch Attendance Announcements.",
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
                child: DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['Lab', 'Theory'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: TextStyle(fontFamily: 'Outfit')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                      selectedSubject = null; // Reset subject when type changes
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Lab or Theory',
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: DropdownButtonFormField<String>(
                  value: selectedSubject,
                  items: getAvailableSubjects().map((String subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject, style: TextStyle(fontFamily: 'Outfit')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubject = value;
                      selectedOptionalSubject = null;
                      // When subject changes, if it is an optional category, fetch its selected value.
                      if (value != null &&
                          (value.toUpperCase().startsWith("DLOC") ||
                              value.toUpperCase().startsWith("ILOC")) &&
                          optionalMapping.containsKey(value)) {
                        selectedOptionalSubject = optionalMapping[value];
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Subject',
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  ),
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
                          onPressed: fetchAnnouncements,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          child: const Text(
                            'Fetch Announcement',
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
              const SizedBox(height: 30),
              if (isLoading) const CircularProgressIndicator(color: Colors.black,),
            ],
          ),
        ),
      ),
    );
  }
}
