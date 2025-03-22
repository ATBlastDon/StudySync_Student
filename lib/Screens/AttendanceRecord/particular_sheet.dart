import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ParticularSheet extends StatefulWidget {
  final String year;
  final String sem;
  final String sub;
  final String type;
  final String fullName;
  final String optionalSubject;
  final String ay;
  final String dept;
  final String batch;
  final DateTime fromDate;
  final DateTime toDate;
  final List<Map<String, dynamic>> attendanceData;
  final String rollNo; // New attribute for the single student's roll number

  const ParticularSheet({
    super.key,
    required this.year,
    required this.sem,
    required this.sub,
    required this.type,
    required this.optionalSubject,
    required this.batch,
    required this.fromDate,
    required this.toDate,
    required this.attendanceData,
    required this.rollNo,
    required this.fullName,
    required this.ay,
    required this.dept,
  });

  @override
  State<ParticularSheet> createState() => _ParticularSheetState();
}

class _ParticularSheetState extends State<ParticularSheet> {
  // Instead of a list of students, we use a single studentData map.
  bool loadingStudent = true;
  List<Map<String, dynamic>> sortedLectures = [];

  // List holding attendance (true/false) for the single student.
  List<bool> studentAttendance = [];
  bool loadingMatrix = true;

  @override
  void initState() {
    super.initState();
    fetchStudent();
  }

  Future<void> fetchStudent() async {
    try {
      bool hasOptional = widget.optionalSubject.isNotEmpty &&
          widget.optionalSubject.toLowerCase() != "none" &&
          (widget.sub.startsWith("DLOC") || widget.sub.startsWith("ILOC"));

      DocumentSnapshot? docSnapshot;

      if (hasOptional) {
        // Try fetching the student from the optional_subjects collection.
        if (widget.type.toLowerCase() == 'lab') {
          // For Lab, filter by batch.
          docSnapshot = await FirebaseFirestore.instance
              .collection('optional_subjects')
              .doc(widget.dept)
              .collection(widget.ay)
              .doc(widget.year)
              .collection(widget.sem)
              .doc(widget.sub)
              .collection(widget.optionalSubject)
              .doc(widget.rollNo)
              .get();

          // If found, ensure the batch matches.
          if (docSnapshot.exists) {
            Map<String, dynamic> optionalData =
            docSnapshot.data() as Map<String, dynamic>;
            if (optionalData['batch'] != widget.batch) {
              // Batch mismatch: treat as not found.
              docSnapshot = null;
            }
          }
        } else {
          // For Theory, no batch filtering is needed.
          docSnapshot = await FirebaseFirestore.instance
              .collection('optional_subjects')
              .doc(widget.dept)
              .collection(widget.ay)
              .doc(widget.year)
              .collection(widget.sem)
              .doc(widget.sub)
              .collection(widget.optionalSubject)
              .doc(widget.rollNo)
              .get();
        }
        // If the student isn’t found in optional_subjects, fallback to main students.
        if (!docSnapshot!.exists) {
          docSnapshot = await FirebaseFirestore.instance
              .collection('students')
              .doc(widget.dept)
              .collection(widget.ay)
              .doc(widget.year)
              .collection(widget.sem)
              .doc(widget.rollNo)
              .get();
        }
      } else {
        // No optional subject; fetch from main 'students' collection.
        docSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.dept)
            .collection(widget.ay)
            .doc(widget.year)
            .collection(widget.sem)
            .doc(widget.rollNo)
            .get();
      }

      if (docSnapshot.exists) {
        setState(() {
          loadingStudent = false;
        });
        await computeAttendanceMatrix();
      } else {
        setState(() {
          loadingStudent = false;
        });
        Fluttertoast.showToast(
          msg: "Student not found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Error: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        loadingStudent = false;
      });
    }
  }

  Future<void> computeAttendanceMatrix() async {
    // Sort lectures by date
    sortedLectures = List.from(widget.attendanceData);
    sortedLectures.sort((a, b) {
      DateTime dateA = (a['created_at'] as Timestamp).toDate();
      DateTime dateB = (b['created_at'] as Timestamp).toDate();
      return dateA.compareTo(dateB);
    });


    // Compute attendance for the single student
    studentAttendance = await Future.wait(
      sortedLectures.map(
            (lecture) => isStudentPresent(widget.rollNo, widget.sub, lecture),
      ),
    );

    setState(() {
      loadingMatrix = false;
    });
  }

  Future<bool> isStudentPresent(String studentRollNo, String subject,
      Map<String, dynamic> lecture) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DateTime lectureDate = (lecture['created_at'] as Timestamp).toDate();
    DocumentReference docRef;


    if (subject.startsWith("DLOC")) {
      // For DLOC subjects
      docRef = firestore
          .collection('attendance_record')
          .doc(widget.dept)
          .collection(widget.ay)
          .doc(widget.year)
          .collection(widget.sem)
          .doc(widget.sub)
          .collection(widget.optionalSubject) // For example, SME
          .doc(widget.type)
          .collection('lecture')
          .doc(DateFormat('yyyy-MM-dd HH:mm:ss').format(lectureDate))
          .collection('rollNumbers')
          .doc(studentRollNo);
    } else if (subject.startsWith("ILOC")) {
      // For ILOC subjects
      docRef = firestore
          .collection('attendance_record')
          .doc(widget.dept)
          .collection(widget.ay)
          .doc(widget.year)
          .collection(widget.sem)
          .doc(widget.sub)
          .collection(widget.optionalSubject)
          .doc(widget.type)
          .collection('lecture')
          .doc(DateFormat('yyyy-MM-dd HH:mm:ss').format(lectureDate))
          .collection('rollNumbers')
          .doc(studentRollNo);
    } else {
      // For regular subjects
      docRef = firestore
          .collection('attendance_record')
          .doc(widget.dept)
          .collection(widget.ay)
          .doc(widget.year)
          .collection(widget.sem)
          .doc(widget.sub)
          .collection(widget.type)
          .doc(DateFormat('yyyy-MM-dd HH:mm:ss').format(lectureDate))
          .collection('rollNumbers')
          .doc(studentRollNo);
    }

    final DocumentSnapshot docSnapshot = await docRef.get();
    return docSnapshot.exists;
  }

  // // Generates a PDF document (landscape) for printing.
  Future<void> _printAttendanceSheet() async {
    final pdf = pw.Document();

    // Define the header background color.
    final headerBgColor = PdfColors.green100;

    // Build transposed table rows (2 columns: Field and Value)
    final List<pw.TableRow> tableRows = [];

    // Header row for clarity with custom background color.
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerBgColor),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "Field",
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "Value",
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );

    // Roll No row
    tableRows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text("Roll No", style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(widget.rollNo, style: pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );

    // Student Name row
    tableRows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text("Student", style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(widget.fullName, style: pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );

    // Add one row per lecture with the lecture date as field and attendance as value.
    int presentCount = 0;
    for (int i = 0; i < sortedLectures.length; i++) {
      DateTime date = (sortedLectures[i]['created_at'] as Timestamp).toDate();
      bool present = studentAttendance[i];
      if (present) presentCount++;

      tableRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(DateFormat('dd/MM').format(date),
                  style: pw.TextStyle(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(present ? "P" : "A",
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: present ? PdfColors.green : PdfColors.red)),
            ),
          ],
        ),
      );
    }

    // Total percentage row
    double percentage = sortedLectures.isNotEmpty
        ? (presentCount / sortedLectures.length) * 100
        : 0.0;
    tableRows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text("Total %",
                style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text("${percentage.toStringAsFixed(2)}%",
                style: pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );

    // Create the PDF page in landscape mode.
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("A T T E N D A N C E",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text(
                "Class: ${widget.year} \nSubject: ${widget.sub} ${widget.optionalSubject != 'N/A' ? ' - ${widget.optionalSubject}':''} ${widget.type == 'Lab' ? ' | Batch: ${widget.batch}' : ''}",                style: pw.TextStyle(
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                children: tableRows,
              ),
            ],
          );
        },
      ),
    );

    // Send the PDF document to the printer.
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Attendance_Sheet',
    );
  }



  List<DataRow> _buildTransposedRows() {
    List<DataRow> rows = [];

    rows.add(DataRow(cells: [
      DataCell(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: const Text("Roll No", style: TextStyle(fontFamily: 'Outfit')),
        ),
      )),
      DataCell(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text(widget.rollNo, style: const TextStyle(fontFamily: 'Outfit')),
        ),
      )),
    ]));

    rows.add(DataRow(cells: [
      DataCell(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: const Text("Name", style: TextStyle(fontFamily: 'Outfit')),
        ),
      )),
      DataCell(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text(widget.fullName, style: const TextStyle(fontFamily: 'Outfit')),
        ),
      )),
    ]));

    int presentCount = 0;
    for (int i = 0; i < sortedLectures.length; i++) {
      DateTime date = (sortedLectures[i]['created_at'] as Timestamp).toDate();
      bool present = studentAttendance[i];
      if (present) presentCount++;

      rows.add(DataRow(cells: [
        DataCell(Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            child: Text(DateFormat('dd/MM').format(date),
                style: const TextStyle(fontFamily: 'Outfit')),
          ),
        )),
        DataCell(Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            child: Text(present ? "P" : "A", style: TextStyle(
              color: present ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            )),
          ),
        )),
      ]));
    }

    double percentage = sortedLectures.isNotEmpty
        ? (presentCount / sortedLectures.length) * 100
        : 0.0;

    rows.add(DataRow(cells: [
      DataCell(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: const Text("Total %", style: TextStyle(fontFamily: 'Outfit')),
        ),
      )),
      DataCell(Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text("${percentage.toStringAsFixed(2)}%",
              style: const TextStyle(fontFamily: 'Outfit')),
        ),
      )),
    ]));

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attendanceData.length > 10) {
      return Scaffold(
        appBar: AppBar(
          title:
          const Text("Attendance Sheet", style: TextStyle(fontFamily: "Outfit")),
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
        body: Center(
          child: Text(
            "Too many days selected to generate a printable sheet.",
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
          ),
        ),
      );
    }

    if (loadingStudent || loadingMatrix) {
      return Scaffold(
        appBar: AppBar(
          title:
          const Text("Attendance Sheet", style: TextStyle(fontFamily: "Outfit")),
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Attendance Sheet", style: TextStyle(fontFamily: "Outfit")),
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
            icon: const Icon(Icons.print, color: Colors.black,),
            tooltip: 'Print Attendance Sheet',
            onPressed: _printAttendanceSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Class: ${widget.year} \nSubject: ${widget.sub} ${widget.optionalSubject != 'N/A' ? ' - ${widget.optionalSubject}':''} ${widget.type == 'Lab' ? ' | Batch: ${widget.batch}' : ''}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: "Outfit",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Spacing between text and table
            Center( // Center the table
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.greenAccent.shade100),
                        columns: const [
                          DataColumn(
                            label: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                              child: Text("Field", style: TextStyle(fontFamily: 'Outfit')),
                            ),
                          ),
                          DataColumn(
                            label: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 70.0),
                              child: Text("Value", style: TextStyle(fontFamily: 'Outfit')),
                            ),
                          ),
                        ],
                        rows: _buildTransposedRows(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}