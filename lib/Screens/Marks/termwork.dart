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
  // Maps to hold the current marks (which may be edited)
  Map<String, int> experimentMarks = {};
  Map<String, int> assignmentMarks = {};
  Map<String, int> crosswordMarks = {};
  // Maps to hold the originally fetched marks from Firebase.
  Map<String, int> originalExperimentMarks = {};
  Map<String, int> originalAssignmentMarks = {};
  Map<String, int> originalCrosswordMarks = {};

  // No IA marks integration.

  // This flag is set to true only after Firebase marks are fetched.
  // Until then, fields remain editable.
  bool marksUploaded = false;

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

  // Load the list of subjects exclusively from Firestore.
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

  // Initialize the maps that will hold the marks (set to 0 by default).
  void _initializeMaps(int exp, int ass, int cross) {
    setState(() {
      experimentsCount = exp;
      assignmentsCount = ass;
      crosswordCount = cross;
      experimentMarks = Map.fromIterables(
        List.generate(exp, (i) => "Experiment ${i + 1}"),
        List.filled(exp, 0),
      );
      assignmentMarks = Map.fromIterables(
        List.generate(ass, (i) => "Assignment ${i + 1}"),
        List.filled(ass, 0),
      );
      crosswordMarks = Map.fromIterables(
        List.generate(cross, (i) => "Crossword ${i + 1}"),
        List.filled(cross, 0),
      );
      // Also store original values as 0.
      originalExperimentMarks = Map.from(experimentMarks);
      originalAssignmentMarks = Map.from(assignmentMarks);
      originalCrosswordMarks = Map.from(crosswordMarks);
      marksUploaded = false;
    });
  }

  // Fetch the student's marks from Firestore (termwork_marks collection).
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
            experimentMarks = Map<String, int>.from(termworkData["experiments"] ?? {});
            assignmentMarks = Map<String, int>.from(termworkData["assignments"] ?? {});
            if (crosswordCount > 0 && termworkData.containsKey("crossword")) {
              crosswordMarks = Map<String, int>.from(termworkData["crossword"]);
            }
            // Store original fetched marks so the lock condition remains based on these values.
            originalExperimentMarks = Map.from(experimentMarks);
            originalAssignmentMarks = Map.from(assignmentMarks);
            originalCrosswordMarks = Map.from(crosswordMarks);
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
      final Map<String, dynamic> data = {
        'termwork': {
          'experiments': experimentMarks,
          'assignments': assignmentMarks,
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

      if(!mounted) return;
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

  Widget _buildEditableMarksSection(
      String title,
      Map<String, int> marks,
      Map<String, int> originalMarks,
      Function(String key, int value) onUpdate,
      ) {
    final sortedKeys = _getSortedKeys(marks);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: "Outfit",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Divider(thickness: 1.5),
            ...sortedKeys.map((key) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: "Outfit",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      style: const TextStyle(fontFamily: "Outfit"),
                      initialValue: marks[key].toString(),
                      keyboardType: TextInputType.number,
                      // If marks have been uploaded, lock field if the original firebase value is non-zero.
                      readOnly: marksUploaded ? (originalMarks[key] != 0) : false,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onChanged: (value) {
                        int parsedValue = int.tryParse(value) ?? 0;
                        onUpdate(key, parsedValue);
                      },
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

  // Build a dropdown to select the subject.
  Widget _buildSubjectDropdown() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Text(
              "Select Subject:",
              style: TextStyle(
                fontFamily: "Outfit",
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSubject,
                    isExpanded: true,
                    items: configuredSubjects
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontFamily: "Outfit")),
                    ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedSubject = v;
                      });
                      _loadConfiguration();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
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
        elevation: 3,
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'T E R M   W O R K',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubjectDropdown(),
              const SizedBox(height: 10,),
              if (selectedSubject != null) // Only show the note after subject selection
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Center( // Center the RichText
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Outfit',
                            fontSize: 14, // Slightly smaller font size
                          ),
                          children: <TextSpan>[
                            const TextSpan(
                              text: "Note: ",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const TextSpan(
                              text:
                              "Once marks are filled and saved, they are not editable. Contact your respective teacher for any corrections.\n",
                            ),
                            const TextSpan(
                              text: "For DLOC/ILOC subjects, if the subject is not listed, please contact the admin.",
                            )
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (selectedSubject != null) ...[
                Center(
                  child: Text(
                    "Subject: $selectedSubject",
                    style: const TextStyle(
                      fontFamily: "Outfit",
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (experimentsCount > 0)
                  _buildEditableMarksSection(
                    "Experiments",
                    experimentMarks,
                    originalExperimentMarks,
                        (key, value) {
                      setState(() {
                        experimentMarks = {...experimentMarks}..[key] = value;
                      });
                    },
                  ),
                if (assignmentsCount > 0)
                  _buildEditableMarksSection(
                    "Assignments",
                    assignmentMarks,
                    originalAssignmentMarks,
                        (key, value) {
                      setState(() {
                        assignmentMarks = {...assignmentMarks}..[key] = value;
                      });
                    },
                  ),
                if (crosswordCount > 0)
                  _buildEditableMarksSection(
                    "Crossword",
                    crosswordMarks,
                    originalCrosswordMarks,
                        (key, value) {
                      setState(() {
                        crosswordMarks = {...crosswordMarks}..[key] = value;
                      });
                    },
                  ),
                const SizedBox(height: 20),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
