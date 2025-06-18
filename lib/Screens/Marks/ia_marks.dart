import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class IaMarks extends StatefulWidget {
  final String year;
  final String sem;
  final String rollNo;
  final String batch;
  final String fullName;
  final String ay;
  final String dept;
  final String clg;


  const IaMarks({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.batch,
    required this.fullName,
    required this.ay,
    required this.dept,
    required this.clg,
  });

  @override
  State<IaMarks> createState() => _IaMarksState();
}

class _IaMarksState extends State<IaMarks> {
  // Map of optional subject selections (if any)
  Map<String, String> selectedSubjects = {};

  // Map to store IA marks per subject. Each subject contains IA-1 and IA-2.
  Map<String, Map<String, int?>> marksData = {};

  // A map to hold the average for each subject.
  Map<String, double?> averageMarks = {};

  bool isLoading = true;
  String? errorMessage;

  /// Firebase mapping for predefined subjects.
  /// This mapping is fetched from Firestore.
  Map<String, dynamic> subjectsMapping = {};

  @override
  void initState() {
    super.initState();
    // First, fetch the mapping then load the remaining data.
    _fetchSubjectsMapping().then((_) {
      _loadData();
    });
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
      setState(() {
        errorMessage = "Failed to load subjects mapping.";
      });
      Fluttertoast.showToast(msg: "Error fetching subjects mapping: $e");
    }
  }

  /// Loads optional subjects and marks data.
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await _loadSelectedSubjects();
      await _loadMarksData();
      _calculateAverage();
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data. Try again.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Loads the student’s optional subject selections.
  Future<void> _loadSelectedSubjects() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection("students")
          .doc(widget.ay)
          .collection(widget.year)
          .doc(widget.sem)
          .collection('details')
          .doc(widget.rollNo)
          .collection("optional_subjects")
          .doc(widget.sem);

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          selectedSubjects = docSnapshot.data()!
              .map((key, value) => MapEntry(key, value.toString()));
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load subjects. Try again.";
      });
    }
  }

  /// Loads IA marks data for all subjects.
  Future<void> _loadMarksData() async {
    try {
      List<String> allSubjects = getAllSubjects();
      for (String subject in allSubjects) {
        DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
            .collection('colleges')
            .doc(widget.clg)
            .collection('departments')
            .doc(widget.dept)
            .collection("marks")
            .doc('ia_marks')
            .collection(widget.ay)
            .doc(widget.year)
            .collection(widget.sem)
            .doc(subject)
            .collection('students')
            .doc(widget.rollNo)
            .get();

        if (docSnapshot.exists) {
          Map<String, dynamic> data =
          docSnapshot.data() as Map<String, dynamic>;
          setState(() {
            marksData[subject] = {
              "IA-1": data["IA-1"] as int?,
              "IA-2": data["IA-2"] as int?,
            };
          });
        } else {
          setState(() {
            marksData[subject] = {"IA-1": null, "IA-2": null};
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load marks.";
      });
    }
  }

  /// Calculates the average marks for each subject.
  void _calculateAverage() {
    setState(() {
      averageMarks.clear();
      marksData.forEach((subject, iaMarks) {
        int? ia1 = iaMarks["IA-1"];
        int? ia2 = iaMarks["IA-2"];
        if (ia1 != null && ia2 != null) {
          averageMarks[subject] = ((ia1 + ia2) / 2).roundToDouble();
        } else {
          averageMarks[subject] = null;
        }
      });
    });
  }

  /// Saves marks and calculated average for a subject to Firestore.
  void _saveAverageToFirestore(String subject) async {
    try {
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(widget.clg)
          .collection('departments')
          .doc(widget.dept)
          .collection("marks")
          .doc('ia_marks')
          .collection(widget.ay)
          .doc(widget.year)
          .collection(widget.sem)
          .doc(subject)
          .collection('students')
          .doc(widget.rollNo)
          .set({
        "IA-1": marksData[subject]?["IA-1"] ?? 0,
        "IA-2": marksData[subject]?["IA-2"] ?? 0,
        "Average": averageMarks[subject] ?? 0.0,
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to save marks and average",
                style: TextStyle(fontFamily: "Outfit"))),
      );
    }
  }

  /// Returns a list of all subjects combining the Firebase mapping for Theory and Lab with any optional subjects.
  List<String> getAllSubjects() {
    Set<String> allSubjects = {}; // Using a Set to remove duplicates

    // Fetch predefined Theory and Lab subjects from Firebase mapping.
    if (subjectsMapping.isNotEmpty &&
        subjectsMapping.containsKey(widget.year) &&
        (subjectsMapping[widget.year] as Map<String, dynamic>).containsKey(widget.sem)) {
      final semData =
      (subjectsMapping[widget.year] as Map<String, dynamic>)[widget.sem] as Map<String, dynamic>;
      if (semData.containsKey('theory')) {
        allSubjects.addAll(List<String>.from(semData['theory']));
      }
      if (semData.containsKey('lab')) {
        allSubjects.addAll(List<String>.from(semData['lab']));
      }
    }

    // Remove unwanted categories: any subject containing "Major Project" (case-insensitive),
    // or exactly "DLOC5", "DLOC6", or any subject starting with "ILOC".
    allSubjects.removeWhere((subject) =>
    subject.toLowerCase().contains("major project") ||
        subject.toUpperCase().startsWith("DLOC") ||
        subject.toUpperCase().startsWith("ILOC")
    );

    // Add the selected optional subjects (which hold the actual subject names).
    allSubjects.addAll(selectedSubjects.values);

    return allSubjects.toList();
  }

  /// Displays a dialog for updating IA marks.
  void _showMarksDialog(String subject, String iaType) {
    TextEditingController marksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Marks for $subject ($iaType)",
              style: const TextStyle(fontFamily: "Outfit")),
          content: TextField(
            controller: marksController,
            style: TextStyle(fontFamily: "Outfit"),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter Marks (0-20)",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                int newMarks = int.tryParse(marksController.text) ?? 0;
                if (newMarks >= 0 && newMarks <= 20) {
                  setState(() {
                    marksData[subject] ??= {"IA-1": null, "IA-2": null};
                    marksData[subject]![iaType] = newMarks;
                    _calculateAverage();
                    _saveAverageToFirestore(subject);
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Marks must be between 0 and 20",
                            style: TextStyle(fontFamily: "Outfit"))),
                  );
                }
              },
              child: const Text("Save", style: TextStyle(fontFamily: "Outfit")),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // While loading, show a circular progress indicator.
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: const Text(
              'I A   M A R K S',
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
        body: const Center(child: CircularProgressIndicator(color: Colors.black,)),
      );
    }

    List<String> allSubjects = getAllSubjects();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'I A   M A R K S',
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
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the Row's content
              children: [
                const Icon(Icons.menu_book, size: 24, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  "Enter your IA Marks",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.greenAccent.shade100),
                        columnSpacing: 40,
                        headingRowHeight: 50,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 40,
                        columns: const [
                          DataColumn(
                            label: Text("Subject",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Outfit')),
                          ),
                          DataColumn(
                            label: Text("IA-1",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Outfit')),
                          ),
                          DataColumn(
                            label: Text("IA-2",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Outfit')),
                          ),
                          DataColumn(
                            label: Text("Average",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Outfit')),
                          ),
                        ],
                        rows: allSubjects.map((subject) {
                          final ia1 = marksData[subject]?["IA-1"];
                          final ia2 = marksData[subject]?["IA-2"];
                          return DataRow(
                            cells: [
                              DataCell(Text(subject,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: "Outfit"))),
                              DataCell(
                                Text(ia1?.toString() ?? "-"),
                                onTap: () {
                                  if (ia1 == null || ia1 == 0) {
                                    _showMarksDialog(subject, "IA-1");
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "IA-1 marks can only be entered once. Contact your teacher to modify.",
                                          style: TextStyle(fontFamily: "Outfit"),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              DataCell(
                                Text(ia2?.toString() ?? "-",
                                    style: TextStyle(fontFamily: "Outfit")),
                                onTap: () {
                                  if (ia2 == null || ia2 == 0) {
                                    _showMarksDialog(subject, "IA-2");
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "IA-2 marks can only be entered once. Contact your teacher to modify.",
                                          style: TextStyle(fontFamily: "Outfit"),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              DataCell(
                                Text(
                                    averageMarks[subject]?.toStringAsFixed(2) ?? "-",
                                    style: TextStyle(fontFamily: "Outfit")),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Note :- IA-2 marks can only be entered once. Contact your teacher to modify.",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
