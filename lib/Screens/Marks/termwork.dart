import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentTermWork extends StatefulWidget {
  final String year;
  final String sem;
  final String rollNo;
  final String fullName;
  final String batch;

  const StudentTermWork({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.fullName,
    required this.batch,
  });

  @override
  State<StudentTermWork> createState() => _StudentTermWorkState();
}

class _StudentTermWorkState extends State<StudentTermWork> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> configuredSubjects = [];
  String? selectedSubject;
  int experimentsCount = 0;
  int assignmentsCount = 0;
  int crosswordCount = 0;

  // For Experiments (single field per experiment)
  Map<String, int> experimentMarks = {};
  Map<String, int> originalExperimentMarks = {};

  // For Assignments: two fields per assignment – Total and Obtained
  Map<String, int> assignmentTotalMarks = {};
  Map<String, int> assignmentObtainedMarks = {};
  Map<String, int> originalAssignmentTotalMarks = {};
  Map<String, int> originalAssignmentObtainedMarks = {};

  // For Crossword (unchanged)
  Map<String, int> crosswordMarks = {};
  Map<String, int> originalCrosswordMarks = {};

  // No IA marks integration.
  bool marksUploaded = false; // becomes true after Firebase marks are fetched.
  bool isLoading = true;
  String? errorMessage;

  // Options for DLOC/ILOC subjects (if needed)
  final Map<String, Map<String, Map<String, List<String>>>> dlocOptions = {
    'TE': {
      '5': {'DLOC1': ['Stats', 'IOT']},
      '6': {'DLOC2': ['DC', 'IVP']},
    },
    'BE': {
      '7': {
        'DLOC3': ['AI For Healthcare', 'NLP', 'NNFS'],
        'DLOC4': ['UX Design with VR', 'BC', 'GT'],
        'ILOC1': ['PLM', 'RE', 'MIS', 'DOE', 'OR', 'CSL', 'DMMM', 'EAM', 'DE'],
      },
      '8': {
        'DLOC5': ['AI for FBA', 'RL', 'QC'],
        'DLOC6': ['RS', 'SMA', 'GDS'],
        'ILOC2': ['PM', 'FM', 'EDM', 'PEC', 'RM', 'IPRP', 'DBM', 'EM'],
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSubjectList();
  }

  // Load subjects exclusively from Firestore.
  Future<void> _loadSubjectList() async {
    setState(() => isLoading = true);
    try {
      final QuerySnapshot qs = await _firestore
          .collection('marks')
          .doc("termwork_config")
          .collection(widget.year)
          .doc(widget.sem)
          .collection('subjects')
          .get();

      final List<String> firestoreSubjects =
      qs.docs.map((doc) => doc.id).toList();

      setState(() {
        configuredSubjects = firestoreSubjects..sort();
        if (configuredSubjects.isNotEmpty) {
          selectedSubject = configuredSubjects.first;
        }
      });
      await _loadConfiguration();
    } catch (e) {
      setState(() => errorMessage = "Failed to load subjects: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Load subject configuration and then fetch the student's marks.
  Future<void> _loadConfiguration() async {
    if (selectedSubject == null) return;
    setState(() => isLoading = true);
    try {
      final DocumentSnapshot configSnapshot = await _firestore
          .collection('marks')
          .doc("termwork_config")
          .collection(widget.year)
          .doc(widget.sem)
          .collection('subjects')
          .doc(selectedSubject)
          .get();

      if (configSnapshot.exists) {
        final config = configSnapshot.data() as Map<String, dynamic>;
        _initializeMaps(
          config["experimentsCount"] ?? 0,
          config["assignmentsCount"] ?? 0,
          config["crosswordCount"] ?? 0,
        );
        await _fetchStudentMarks();
      } else if (_isDlocSubject()) {
        _initializeMaps(0, 0, 0); // Defaults for DLOC/ILOC subjects.
        await _fetchStudentMarks();
      } else {
        setState(() => errorMessage = "Configuration missing for $selectedSubject");
      }
    } catch (e) {
      setState(() => errorMessage = "Error loading config: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _isDlocSubject() {
    return dlocOptions[widget.year]?[widget.sem]?.containsKey(selectedSubject) ?? false;
  }

  // Initialize the maps that will hold the marks.
  void _initializeMaps(int exp, int ass, int cross) {
    setState(() {
      experimentsCount = exp;
      assignmentsCount = ass;
      crosswordCount = cross;

      // Initialize experiments (single field per experiment)
      experimentMarks = Map.fromIterables(
        List.generate(exp, (i) => "Experiment ${i + 1}"),
        List.filled(exp, 0),
      );
      originalExperimentMarks = Map.from(experimentMarks);

      // Initialize assignments (two fields per assignment)
      assignmentTotalMarks = Map.fromIterables(
        List.generate(ass, (i) => "Assignment ${i + 1}"),
        List.filled(ass, 0),
      );
      assignmentObtainedMarks = Map.fromIterables(
        List.generate(ass, (i) => "Assignment ${i + 1}"),
        List.filled(ass, 0),
      );
      originalAssignmentTotalMarks = Map.from(assignmentTotalMarks);
      originalAssignmentObtainedMarks = Map.from(assignmentObtainedMarks);

      // Initialize crossword marks
      crosswordMarks = Map.fromIterables(
        List.generate(cross, (i) => "Crossword ${i + 1}"),
        List.filled(cross, 0),
      );
      originalCrosswordMarks = Map.from(crosswordMarks);

      marksUploaded = false;
    });
  }

  // Fetch the student's marks from Firestore.
  Future<void> _fetchStudentMarks() async {
    if (selectedSubject == null) return;
    setState(() => isLoading = true);
    try {
      final DocumentSnapshot marksSnapshot = await _firestore
          .collection("marks")
          .doc("termwork_marks")
          .collection(widget.year)
          .doc(widget.sem)
          .collection(selectedSubject!)
          .doc(widget.rollNo)
          .get();
      if (marksSnapshot.exists) {
        marksUploaded = true; // Marks have been uploaded.
        final data = marksSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey("termwork")) {
          final termworkData = data["termwork"] as Map<String, dynamic>;
          setState(() {
            // For experiments: enforce max value = 10 in the UI below.
            experimentMarks = Map<String, int>.from(termworkData["experiments"] ?? {});
            originalExperimentMarks = Map.from(experimentMarks);

            // For assignments: expect a nested map for each assignment.
            if (termworkData.containsKey("assignments")) {
              Map<String, dynamic> assignmentsData =
              termworkData["assignments"] as Map<String, dynamic>;
              assignmentsData.forEach((assignment, value) {
                if (value is Map<String, dynamic>) {
                  assignmentTotalMarks[assignment] = value["total"] ?? 0;
                  assignmentObtainedMarks[assignment] = value["obtained"] ?? 0;
                }
              });
              originalAssignmentTotalMarks = Map.from(assignmentTotalMarks);
              originalAssignmentObtainedMarks = Map.from(assignmentObtainedMarks);
            }
            // For crossword
            if (crosswordCount > 0 && termworkData.containsKey("crossword")) {
              crosswordMarks = Map<String, int>.from(termworkData["crossword"]);
              originalCrosswordMarks = Map.from(crosswordMarks);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching student marks: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Save marks to Firestore.
  Future<void> _saveMarks() async {
    if (selectedSubject == null) return;
    setState(() => isLoading = true);
    try {
      // Prepare assignments data as a nested map.
      Map<String, dynamic> assignmentsData = {};
      assignmentTotalMarks.forEach((assignment, total) {
        assignmentsData[assignment] = {
          "total": total,
          "obtained": assignmentObtainedMarks[assignment] ?? 0,
        };
      });

      final Map<String, dynamic> data = {
        'termwork': {
          'experiments': experimentMarks,
          'assignments': assignmentsData,
          if (crosswordCount > 0) 'crossword': crosswordMarks,
        },
      };

      await _firestore
          .collection('marks')
          .doc('termwork_marks')
          .collection(widget.year)
          .doc(widget.sem)
          .collection(selectedSubject!)
          .doc(widget.rollNo)
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks saved successfully!', style: TextStyle(fontFamily: "Outfit")),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving marks: $e', style: TextStyle(fontFamily: "Outfit"))),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Helper method to sort keys based on the numeric value at the end of the string.
  List<String> _getSortedKeys(Map<String, int> marks) {
    List<String> keys = marks.keys.toList();
    keys.sort((a, b) {
      final aNum = int.tryParse(a.split(" ").last) ?? 0;
      final bNum = int.tryParse(b.split(" ").last) ?? 0;
      return aNum.compareTo(bNum);
    });
    return keys;
  }

  // Widget for sections with one field per item (Experiments, Crossword)
  Widget _buildEditableMarksSection(
      String title,
      Map<String, int> marks,
      Map<String, int> originalMarks,
      Function(String key, int value) onUpdate,
      ) {
    final sortedKeys = _getSortedKeys(marks);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.greenAccent, Colors.teal],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: "Outfit",
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedKeys.map((key) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Outfit",
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: marksUploaded && originalMarks[key] != 0
                            ? Colors.grey[100]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        style: const TextStyle(
                          fontFamily: "Outfit",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        initialValue: marks[key].toString(),
                        keyboardType: TextInputType.number,
                        readOnly: marksUploaded ? (originalMarks[key] != 0) : false,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: InputBorder.none,
                          // For experiments, we allow only values up to 10.
                          suffixIcon: marksUploaded && originalMarks[key] != 0
                              ? const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.lock_outline,
                                size: 18, color: Colors.grey),
                          )
                              : null,
                        ),
                        onChanged: (value) {
                          int parsedValue = int.tryParse(value) ?? 0;
                          // Enforce maximum value of 10 for Experiments.
                          if (title == "Experiments" && parsedValue > 10) {
                            parsedValue = 0;
                          }
                          onUpdate(key, parsedValue);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // New widget for Assignments: displays two boxes (Total and Obtained) per assignment.
  Widget _buildEditableAssignmentSection(
      String title,
      Map<String, int> totalMarks,
      Map<String, int> obtainedMarks,
      Map<String, int> originalTotalMarks,
      Map<String, int> originalObtainedMarks,
      Function(String key, int value, bool isTotal) onUpdate,
      ) {
    final sortedKeys = _getSortedKeys(totalMarks);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment section title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.greenAccent, Colors.teal],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: "Outfit",
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // For each assignment (e.g. Assignment 1, Assignment 2, etc.)
            ...sortedKeys.map((key) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment title
                  Text(
                    key,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Outfit",
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Row with two boxes: one for Total and one for Obtained
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header for Total marks
                            Text(
                              "Total",
                              style: TextStyle(
                                fontFamily: "Outfit",
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: marksUploaded && originalTotalMarks[key] != 0
                                    ? Colors.grey[100]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                style: const TextStyle(
                                  fontFamily: "Outfit",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                initialValue: totalMarks[key].toString(),
                                keyboardType: TextInputType.number,
                                readOnly: marksUploaded ? (originalTotalMarks[key] != 0) : false,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  border: InputBorder.none,
                                  hintText: "Total",
                                  suffixIcon: marksUploaded && originalTotalMarks[key] != 0
                                      ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
                                      : null,
                                ),
                                onChanged: (value) {
                                  int parsedValue = int.tryParse(value) ?? 0;
                                  onUpdate(key, parsedValue, true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header for Obtained marks
                            Text(
                              "Obtained",
                              style: TextStyle(
                                fontFamily: "Outfit",
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: marksUploaded && originalObtainedMarks[key] != 0
                                    ? Colors.grey[100]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                style: const TextStyle(
                                  fontFamily: "Outfit",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                initialValue: obtainedMarks[key].toString(),
                                keyboardType: TextInputType.number,
                                readOnly: marksUploaded ? (originalObtainedMarks[key] != 0) : false,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  border: InputBorder.none,
                                  hintText: "Obtained",
                                  suffixIcon: marksUploaded && originalObtainedMarks[key] != 0
                                      ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
                                      : null,
                                ),
                                onChanged: (value) {
                                  int parsedValue = int.tryParse(value) ?? 0;
                                  onUpdate(key, parsedValue, false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SELECT SUBJECT",
            style: TextStyle(
              fontFamily: "Outfit",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: selectedSubject,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: Colors.grey),
                items: configuredSubjects
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      style: const TextStyle(
                          fontFamily: "Outfit",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87)),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedSubject = v);
                  _loadConfiguration();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(fontFamily: "Outfit", color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'T E R M  W O R K',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSubjectDropdown(),
              // Enhanced Note Section
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Important Notes:\n",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                  height: 1.4,
                                ),
                              ),
                              TextSpan(
                                text: "• Once saved, marks cannot be edited\n"
                                    "• DLOC/ILOC subjects require admin contact\n"
                                    "• All fields are mandatory",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (selectedSubject != null) ...[
                // Subject Title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    selectedSubject!,
                    style: const TextStyle(
                      fontFamily: "Outfit",
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Experiments Section (with max value of 10 enforced)
                if (experimentsCount > 0)
                  _buildEditableMarksSection(
                    "Experiments",
                    experimentMarks,
                    originalExperimentMarks,
                        (key, value) {
                      setState(() {
                        experimentMarks[key] = value;
                      });
                    },
                  ),
                // Assignments Section: now with two fields per assignment.
                if (assignmentsCount > 0)
                  _buildEditableAssignmentSection(
                    "Assignments",
                    assignmentTotalMarks,
                    assignmentObtainedMarks,
                    originalAssignmentTotalMarks,
                    originalAssignmentObtainedMarks,
                        (key, value, isTotal) {
                      setState(() {
                        if (isTotal) {
                          assignmentTotalMarks[key] = value;
                        } else {
                          assignmentObtainedMarks[key] = value;
                        }
                      });
                    },
                  ),
                // Crossword Section remains unchanged.
                if (crosswordCount > 0)
                  _buildEditableMarksSection(
                    "Crossword",
                    crosswordMarks,
                    originalCrosswordMarks,
                        (key, value) {
                      setState(() {
                        crosswordMarks[key] = value;
                      });
                    },
                  ),
                // Save Button
                Center(
                  child: FadeInUp(
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
                              onPressed: isLoading ? null : _saveMarks,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                  'Save Marks',
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
                ),
                const SizedBox(height: 30,)
              ],
            ],
          ),
        ),
      ),
    );
  }
}
