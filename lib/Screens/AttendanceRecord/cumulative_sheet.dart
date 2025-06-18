import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class CumulativeSheet extends StatefulWidget {
  final String selectedClass; // e.g. "BE" or "TE"
  final String selectedSem;   // e.g. "7" or "5"
  final String rollNo;        // Single student's roll number
  final String fullName;
  final String batch;
  final String ay;
  final String dept;
  final String clg;
  /// Teacher‐selected subjects (a combined list of regular subjects and optional subject category keys)
  final List<String> selectedSubjects;

  const CumulativeSheet({
    super.key,
    required this.selectedClass,
    required this.selectedSem,
    required this.rollNo,
    required this.fullName,
    required this.selectedSubjects,
    required this.batch,
    required this.ay,
    required this.dept,
    required this.clg,
  });

  @override
  State<CumulativeSheet> createState() => _CumulativeSheetState();
}

class _CumulativeSheetState extends State<CumulativeSheet> {
  /// Attendance data structure:
  /// { rollNo: { "subject (mode)" : { 'present': int, 'total': int } } }
  Map<String, Map<String, Map<String, int>>> attendanceData = {};

  /// The student's stored optional selections.
  Map<String, String> studentOptionalSelections = {};
  bool isLoading = true;

  /// Firebase subjects mapping.
  Map<String, dynamic> subjectsMapping = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// Initialize by fetching the subjects mapping from Firebase,
  /// then regular attendance, student's optional selections, and optional attendance.
  Future<void> _initData() async {
    await _fetchSubjectsMapping();
    await _fetchRegularAttendance();
    await _fetchStudentOptionalSelections();
    await _fetchOptionalAttendance();
    setState(() {
      isLoading = false;
    });
    await _updateFirebaseRecords();
  }

  /// Fetch the subjects mapping from Firestore.
  Future<void> _fetchSubjectsMapping() async {
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
        Fluttertoast.showToast(msg: "Subjects mapping not found");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading subjects mapping: $e");
    }
  }

  /// Helper to get optional keys from the Firebase mapping.
  List<String> _getOptionalKeys() {
    List<String> optionalKeys = [];
    if (subjectsMapping.isNotEmpty) {
      final semMap = (subjectsMapping[widget.selectedClass] as Map<
          String,
          dynamic>?)?[widget.selectedSem] as Map<String, dynamic>? ?? {};
      final dlocMap = semMap['dloc'] as Map<String, dynamic>? ?? {};
      final ilocMap = semMap['iloc'] as Map<String, dynamic>? ?? {};
      optionalKeys = [...dlocMap.keys, ...ilocMap.keys];
    }
    return optionalKeys;
  }

  /// Fetch regular subject attendance for the student.
  Future<void> _fetchRegularAttendance() async {
    final firestore = FirebaseFirestore.instance;
    String rollNo = widget.rollNo;

    // Determine optional subject keys using the Firebase mapping.
    List<String> optionalKeys = _getOptionalKeys();
    // Regular subjects: those in selectedSubjects not in the optional keys.
    List<String> regularSubjects =
    widget.selectedSubjects.where((s) => !optionalKeys.contains(s)).toList();

    try {
      for (String subject in regularSubjects) {
        for (String mode in ['Theory', 'Lab']) {
          // Skip lab mode for project subjects.
          if (mode == 'Lab' &&
              (subject.toUpperCase().startsWith("MAJOR PROJECT") ||
                  subject.toUpperCase().startsWith("MINI PROJECT"))) {
            continue;
          }
          QuerySnapshot lecturesSnapshot = await firestore
              .collection('colleges')
              .doc(widget.clg)
              .collection('departments')
              .doc(widget.dept)
              .collection('attendance')
              .doc(widget.ay)
              .collection(widget.selectedClass)
              .doc(widget.selectedSem)
              .collection(subject)
              .doc(mode)
              .collection('lecture')
              .get();

          int totalLectures = 0;
          int presentCount = 0;
          for (var lectureDoc in lecturesSnapshot.docs) {
            // For Lab mode, only count lectures where the batch matches.
            if (mode == 'Lab') {
              var lectureData = lectureDoc.data() as Map<String, dynamic>;
              if (lectureData['batch'] != widget.batch) {
                continue;
              }
            }
            totalLectures++; // Count valid lecture.
            DocumentSnapshot presentSnapshot = await firestore
                .collection('colleges')
                .doc(widget.clg)
                .collection('departments')
                .doc(widget.dept)
                .collection('attendance_record')
                .doc(widget.ay)
                .collection(widget.selectedClass)
                .doc(widget.selectedSem)
                .collection(subject)
                .doc(mode)
                .collection('lecture')
                .doc(lectureDoc.id)
                .collection('rollNumbers')
                .doc(rollNo)
                .get();

            if (presentSnapshot.exists &&
                presentSnapshot['approvalStatus'] == 'present') {
              presentCount++;
            }
          }
          String key = "$subject ($mode)";
          attendanceData.putIfAbsent(rollNo, () => {});
          attendanceData[rollNo]![key] = {
            'present': presentCount,
            'total': totalLectures,
          };
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error in _fetchRegularAttendance: $e");
    }
  }

  /// Fetch the student's stored optional subject selections from Firestore.
  Future<void> _fetchStudentOptionalSelections() async {
    final firestore = FirebaseFirestore.instance;
    String rollNo = widget.rollNo;
    try {
      DocumentSnapshot doc = await firestore
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection('students')
          .doc(widget.ay)
          .collection(widget.selectedClass)
          .doc(widget.selectedSem)
          .collection('details')
          .doc(rollNo)
          .collection('optional_subjects')
          .doc(widget.selectedSem)
          .get();
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            studentOptionalSelections[key] = value.toString();
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error in _fetchStudentOptionalSelections: $e");
    }
  }

  /// Fetch optional subject attendance for the student.
  Future<void> _fetchOptionalAttendance() async {
    final firestore = FirebaseFirestore.instance;
    String rollNo = widget.rollNo;

    // Determine optional subject keys from the Firebase mapping.
    List<String> optionalKeys = _getOptionalKeys();
    // From the teacher–selected subjects, pick those that are optional.
    List<String> optionalSubjects = widget.selectedSubjects.where((s) =>
        optionalKeys.contains(s)).toList();

    for (String category in optionalSubjects) {
      // Get the student's chosen subject for this optional category.
      String? chosenSubject = studentOptionalSelections[category];
      if (chosenSubject == null || chosenSubject.isEmpty) continue;
      // Decide which modes to process.
      List<String> modes = (category.toUpperCase().startsWith('ILOC') ||
          category.toUpperCase().startsWith('MAJOR PROJECT') ||
          category.toUpperCase().startsWith('MINI PROJECT'))
          ? ['Theory']
          : ['Theory', 'Lab'];

      for (String mode in modes) {
        int presentCount = 0;
        int totalLectures = 0;
        try {
          QuerySnapshot lecturesSnapshot = await firestore
              .collection('colleges')
              .doc(widget.clg)
              .collection('departments')
              .doc(widget.dept)
              .collection('attendance')
              .doc(widget.ay)
              .collection(widget.selectedClass)
              .doc(widget.selectedSem)
              .collection(category)
              .doc(chosenSubject)
              .collection(mode)
              .get();
          for (var lectureDoc in lecturesSnapshot.docs) {
            // For Lab mode, validate the lecture's batch.
            if (mode == 'Lab') {
              var lectureData = lectureDoc.data() as Map<String, dynamic>;
              if (lectureData['batch'] != widget.batch) {
                continue;
              }
            }
            totalLectures++;
            DocumentSnapshot presentDoc = await firestore
                .collection('colleges')
                .doc(widget.clg)
                .collection('departments')
                .doc(widget.dept)
                .collection('attendance_record')
                .doc(widget.ay)
                .collection(widget.selectedClass)
                .doc(widget.selectedSem)
                .collection(category)
                .doc(chosenSubject)
                .collection(mode)
                .doc(lectureDoc.id)
                .collection('rollNumbers')
                .doc(rollNo)
                .get();
            if (presentDoc.exists &&
                presentDoc['approvalStatus'] == 'present') {
              presentCount++;
            }
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Error in _fetchOptionalAttendance: $e");
        }
        String key = "$category ($mode)";
        attendanceData.putIfAbsent(rollNo, () => {});
        attendanceData[rollNo]![key] = {
          'present': presentCount,
          'total': totalLectures,
        };
      }
    }
  }

  /// Update Firebase with the calculated attendance for this student.
  Future<void> _updateFirebaseRecords() async {
    final firestore = FirebaseFirestore.instance;
    String rollNo = widget.rollNo;
    if (attendanceData.containsKey(rollNo)) {
      Map<String, dynamic> studentRecord = {};
      Map<String, dynamic> subjectsData = {};
      double sumPercentages = 0.0;
      int count = 0;

      attendanceData[rollNo]!.forEach((subject, data) {
        String subjectKeyForSaving = subject;
        // If this subject is an optional one (DLOC/ILOC), update it with the student's chosen subject.
        if (subject.toUpperCase().startsWith("DLOC") ||
            subject.toUpperCase().startsWith("ILOC")) {
          // Assume the subject key format is "CATEGORY (Mode)" e.g. "DLOC5 (Theory)".
          List<String> parts = subject.split(" ");
          String category = parts.first; // e.g. "DLOC5"
          String modePart = parts.length > 1 ? parts.sublist(1).join(" ") : "";
          // Check if the student has a stored optional selection for this category.
          if (studentOptionalSelections.containsKey(category)) {
            String optionalSubject = studentOptionalSelections[category]!;
            subjectKeyForSaving = optionalSubject + (modePart.isNotEmpty ? " " + modePart : "");
          } else {
            // If no optional selection is recorded, you may choose to skip saving this subject.
            // Uncomment the next line to skip, or leave it to use the default subject key.
            // return;
          }
        }

        int present = data['present']!;
        int total = data['total']!;
        double percentage = total > 0 ? (present / total * 100) : 0;

        subjectsData[subjectKeyForSaving] = {
          'present': present,
          'total': total,
          'percentage': percentage,
        };
        sumPercentages += percentage;
        count++;
      });

      double overallPercentage = count > 0 ? (sumPercentages / count) : 0;
      studentRecord['subjects'] = subjectsData;
      studentRecord['overall'] = overallPercentage;

      await firestore
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection("students")
          .doc(widget.ay)
          .collection(widget.selectedClass)
          .doc(widget.selectedSem)
          .collection('records')
          .doc(rollNo)
          .set(studentRecord, SetOptions(merge: true));
    }
  }

  /// Generate a PDF version of the attendance table (transposed).
  Future<void> _printPdf() async {
    final doc = pw.Document();
    final pageFormat = PdfPageFormat.legal.landscape;
    final margin = 40.0;

    // Build table data as a two-column (Field, Value) table.
    List<List<String>> tableData = [];
    tableData.add(["Field", "Value"]);
    tableData.add(["Roll No", widget.rollNo]);
    tableData.add(["Name", widget.fullName]);

    // Use the Firebase mapping to determine optional subject keys.
    List<String> optionalKeys = _getOptionalKeys();

    List<String> regularSubjectColumns = [];
    List<String> optionalSubjectColumns = [];
    for (var subject in widget.selectedSubjects) {
      if (optionalKeys.contains(subject)) {
        optionalSubjectColumns.add("$subject (Theory)");
        if (!subject.toUpperCase().startsWith("ILOC") &&
            !subject.toUpperCase().startsWith("MAJOR PROJECT") &&
            !subject.toUpperCase().startsWith("MINI PROJECT")) {
          optionalSubjectColumns.add("$subject (Lab)");
        }
      } else {
        regularSubjectColumns.add("$subject (Theory)");
        if (!subject.toUpperCase().startsWith("ILOC") &&
            !subject.toUpperCase().startsWith("MAJOR PROJECT") &&
            !subject.toUpperCase().startsWith("MINI PROJECT")) {
          regularSubjectColumns.add("$subject (Lab)");
        }
      }
    }
    List<String> subjectColumns = [
      ...regularSubjectColumns,
      ...optionalSubjectColumns
    ];

    double sumPercentages = 0.0;
    int count = 0;
    for (String subject in subjectColumns) {
      var data = attendanceData[widget.rollNo]?[subject] ??
          {'present': 0, 'total': 0};
      int present = data['present']!;
      int total = data['total']!;
      double percentage = total > 0 ? (present / total * 100) : 0;
      sumPercentages += percentage;
      count++;
      tableData.add([
        subject,
        "Present: $present, Total: $total, Percentage: ${percentage
            .toStringAsFixed(1)}%"
      ]);
    }
    double overallPercentage = count > 0 ? (sumPercentages / count) : 0;
    tableData.add([
      "Overall Total Percentage",
      "${overallPercentage.toStringAsFixed(1)}%"
    ]);

    final availableWidth = pageFormat.width - margin * 2;
    final colWidth = availableWidth / 2;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        build: (context) =>
            pw.TableHelper.fromTextArray(
              data: tableData,
              columnWidths: {
                0: pw.FixedColumnWidth(colWidth),
                1: pw.FixedColumnWidth(colWidth),
              },
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green100),
              border: pw.TableBorder.all(color: PdfColors.grey),
              cellHeight: 25,
            ),
      ),
    );
    String fileName = "${widget.fullName}_${widget.dept}-${widget.ay}_Cumulative_Attendance_Record.pdf";
    await Printing.layoutPdf(name: fileName, onLayout: (format) => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? [
      Colors.teal[800]!,
      Colors.green[900]!
    ] : [
      Colors.greenAccent,
      Colors.teal
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedClass} - Sem ${widget.selectedSem}',
            style: const TextStyle(
                fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload, color: Colors.black),
            tooltip: "Upload Attendance Data",
            onPressed: () async {
              if (!mounted) return;
              ScaffoldMessengerState scaffold = ScaffoldMessenger.of(context);
              await _updateFirebaseRecords();
              scaffold.showSnackBar(
                const SnackBar(content: Text("Attendance data uploaded.",
                    style: TextStyle(fontFamily: 'Outfit'))),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.black),
            tooltip: "Print Attendance",
            onPressed: _printPdf,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black,))
          : _buildAttendanceBody(theme, isDark),
    );
  }

  Widget _buildAttendanceBody(ThemeData theme, bool isDark) {
    final overallData = _calculateOverallPercentage();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall Performance
          _buildOverallCard(overallData, theme, isDark),
          const SizedBox(height: 24),

          // Subjects Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('Subject-wise Performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                )),
          ),
          const SizedBox(height: 16),

          // Subjects List
          ..._buildSubjectCards(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildOverallCard(Map<String, dynamic> data, ThemeData theme,
      bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isDark ? Colors.teal[800] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Overall Attendance',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Outfit',
                  color: Colors.teal[900],
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              // Ensures the Column takes only necessary space
              children: [
                // Percentage Text
                Text(
                  '${data['percentage'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: _getProgressColor(data['percentage'], isDark),
                  ),
                ),

                SizedBox(height: 8),
                // Space between text and progress bar

                // Linear Progress Indicator
                LinearProgressIndicator(
                  value: (data['percentage'] / 100).clamp(0.0, 1.0),
                  // Ensures value is between 0 and 1
                  backgroundColor: Colors.green[100],
                  color: _getProgressColor(data['percentage'], isDark),
                  minHeight: 12,
                  // Adjust thickness of progress bar
                  borderRadius: BorderRadius.circular(
                      8), // Optional: Adds rounded edges
                ),

                SizedBox(height: 8),
                // Space between progress bar and class details
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubjectCards(ThemeData theme, bool isDark) {
    return attendanceData[widget.rollNo]!.entries.map((entry) {
      final subject = entry.key;
      final present = entry.value['present']!;
      final total = entry.value['total']!;
      final percentage = total > 0 ? (present / total * 100) : 0;

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey, width: 0.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(subject,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          color: Colors.teal[800],
                        )),
                  ),
                  Chip(
                    label: Text('${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: _getProgressColor(
                              percentage.toDouble(), isDark),
                        )),
                    backgroundColor: _getProgressColor(
                        percentage.toDouble(), isDark).withValues(alpha: 0.1),

                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (percentage / 100).toDouble(),
                // Ensure it's a double
                backgroundColor: Colors.grey[400],
                color: _getProgressColor(percentage.toDouble(), isDark),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Present', present, Icons.check_circle, Colors.green,
                      isDark),
                  _buildStatItem(
                      'Total', total, Icons.calendar_today, Colors.blue,
                      isDark),
                  _buildStatItem(
                      'Absent', total - present, Icons.cancel, Colors.red,
                      isDark),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _getProgressColor(double percentage, bool isDark) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color,
      bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value.toString(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            )),
        Text(label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: Colors.grey[600],
            )),
      ],
    );
  }

  Map<String, dynamic> _calculateOverallPercentage() {
    double sumPercentage = 0.0;
    int subjectCount = 0;

    attendanceData[widget.rollNo]!.forEach((subject, data) {
      int present = data['present']!;
      int total = data['total']!;
      // Calculate subject percentage (using 0 if total is 0)
      double subjectPercentage = total > 0 ? (present / total * 100) : 0;
      sumPercentage += subjectPercentage;
      subjectCount++; // count every subject, even if total is 0
    });

    double overallPercentage = subjectCount > 0 ? (sumPercentage / subjectCount) : 0.0;
    return {
      'percentage': overallPercentage,
    };
  }
}