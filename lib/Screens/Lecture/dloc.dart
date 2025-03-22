import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SelectionSubjects extends StatefulWidget {
  final String year; // e.g. "BE"
  final String sem; // e.g. "8"
  final String rollNo; // e.g. "59"
  final String batch;
  final String dept;
  final String ay;

  const SelectionSubjects({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.batch,
    required this.dept,
    required this.ay,
  });

  @override
  State<SelectionSubjects> createState() => _SelectionSubjectsState();
}

class _SelectionSubjectsState extends State<SelectionSubjects> {
  // Map to hold the student’s selected option for each DLOC/ILOC key.
  Map<String, String?> selectedSubjects = {};
  // Keep a copy of the previously saved subjects.
  Map<String, String?> previousSelectedSubjects = {};

  // Variable to track if a process (save/update) is in progress.
  bool _isProcessing = false;
  // State variable to track if the Firebase mapping is still loading.
  bool _isMappingLoading = true;

  /// Firebase mapping for optional subjects.
  /// This mapping is fetched from Firestore.
  Map<String, dynamic> subjectsMapping = {};

  @override
  void initState() {
    super.initState();
    _fetchSubjectsMapping();
    _loadExistingSubjects();
  }

  /// Fetch the optional subjects mapping from Firestore.
  Future<void> _fetchSubjectsMapping() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.dept)
          .get();
      if (snapshot.exists) {
        setState(() {
          subjectsMapping = snapshot.data() as Map<String, dynamic>;
          _isMappingLoading = false;
        });
      } else {
        setState(() {
          _isMappingLoading = false;
        });
        Fluttertoast.showToast(msg: "Subjects mapping not found");
      }
    } catch (e) {
      setState(() {
        _isMappingLoading = false;
      });
      Fluttertoast.showToast(msg: "Error fetching subjects mapping: $e");
    }
  }

  /// Load existing subject selections for the student.
  Future<void> _loadExistingSubjects() async {
    final String year = widget.year;
    final String sem = widget.sem;
    final String rollNo = widget.rollNo;
    final String dept = widget.dept;
    final String ay = widget.ay;

    final docRef = FirebaseFirestore.instance
        .collection("students")
        .doc(dept)
        .collection(ay)
        .doc(year)
        .collection(sem)
        .doc(rollNo)
        .collection("optional_subjects")
        .doc(sem);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists &&
        docSnapshot.data() != null &&
        docSnapshot.data()!.isNotEmpty) {
      setState(() {
        selectedSubjects = docSnapshot.data()!
            .map((key, value) => MapEntry(key, value.toString()));
        // Save a copy as the previous selections.
        previousSelectedSubjects = Map.from(selectedSubjects);
      });
    }
  }

  /// Helper: check that every optional subject key has a selected value.
  bool _allOptionsSelected(List<String> optionalKeys) {
    for (var key in optionalKeys) {
      if (selectedSubjects[key] == null) return false;
    }
    return true;
  }

  /// Save (or update) the selected subjects in the student's document.
  Future<void> _saveSelectedSubjects() async {
    final String year = widget.year;
    final String sem = widget.sem;
    final String rollNo = widget.rollNo;
    final String dept = widget.dept;
    final String ay = widget.ay;

    final docRef = FirebaseFirestore.instance
        .collection("students")
        .doc(dept)
        .collection(ay)
        .doc(year)
        .collection(sem)
        .doc(rollNo)
        .collection("optional_subjects")
        .doc(sem);

    try {
      await docRef.set(selectedSubjects, SetOptions(merge: true));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error saving subjects. Please try again.", style: TextStyle(fontFamily: "Outfit")),
        ),
      );
    }
  }

  /// Save the selections in the optional subjects collection.
  Future<void> _saveInOptionalSubjects() async {
    final String year = widget.year;
    final String sem = widget.sem;
    final String rollNo = widget.rollNo;
    final String dept = widget.dept;
    final String ay = widget.ay;

    for (final entry in selectedSubjects.entries) {
      final String optionalKey = entry.key;
      final String newSubject = entry.value!;
      final String? oldSubject = previousSelectedSubjects[optionalKey];

      // If there is an old selection that differs from the new one, remove the rollNo.
      if (oldSubject != null && oldSubject != newSubject) {
        final oldDocRef = FirebaseFirestore.instance
            .collection("optional_subjects")
            .doc(dept)
            .collection(ay)
            .doc(year)
            .collection(sem)
            .doc(optionalKey)
            .collection(oldSubject)
            .doc(rollNo);
        try {
          await oldDocRef.delete();
        } catch (error) {
          // Handle errors if needed.
        }
      }

      // Add (or update) the new selection.
      final newDocRef = FirebaseFirestore.instance
          .collection("optional_subjects")
          .doc(dept)
          .collection(ay)
          .doc(year)
          .collection(sem)
          .doc(optionalKey)
          .collection(newSubject)
          .doc(rollNo);

      await newDocRef.set({
        'batch': widget.batch,
      });
    }

    previousSelectedSubjects = Map.from(selectedSubjects);
  }

  @override
  Widget build(BuildContext context) {
    // While the mapping is loading, show a CircularProgressIndicator.
    if (_isMappingLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator(color: Colors.black,)),
      );
    }

    // Build a merged map of optional subject options for the given branch and sem.
    // Merge both "dloc" and "iloc" sections from the Firebase mapping.
    Map<String, List<String>> subjectsOptions = {};
    if (subjectsMapping.isNotEmpty &&
        subjectsMapping.containsKey(widget.year) &&
        (subjectsMapping[widget.year] as Map<String, dynamic>).containsKey(widget.sem)) {
      final semData = (subjectsMapping[widget.year] as Map<String, dynamic>)[widget.sem] as Map<String, dynamic>;
      if (semData.containsKey("dloc")) {
        final dlocMap = semData["dloc"] as Map<String, dynamic>;
        dlocMap.forEach((key, value) {
          subjectsOptions[key] = List<String>.from(value);
        });
      }
      if (semData.containsKey("iloc")) {
        final ilocMap = semData["iloc"] as Map<String, dynamic>;
        ilocMap.forEach((key, value) {
          subjectsOptions[key] = List<String>.from(value);
        });
      }
    }

    if (subjectsOptions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Optional Subjects",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "No choices for DLOC or ILOC subjects",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Center(
                    child: const Text(
                      "Optional Subjects",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    children: [
                      // Build a dropdown for each optional key (DLOC or ILOC).
                      ...subjectsOptions.entries.map((entry) {
                        final String optionalKey = entry.key;
                        final List<String> options = entry.value;
                        return FadeInUp(
                          duration: const Duration(milliseconds: 1000),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: DropdownButtonFormField<String>(
                              style: const TextStyle(fontFamily: "Outfit", color: Colors.black),
                              decoration: InputDecoration(
                                labelText: optionalKey,
                                labelStyle: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                              // Show previously saved selection if available.
                              value: selectedSubjects[optionalKey],
                              items: options.map((String option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option, style: const TextStyle(fontFamily: "Outfit")),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedSubjects[optionalKey] = newValue;
                                });
                              },
                            ),
                          ),
                        );
                      }),
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
                                  onPressed: () async {
                                    if (_allOptionsSelected(subjectsOptions.keys.toList())) {
                                      setState(() {
                                        _isProcessing = true;
                                      });
                                      await _saveSelectedSubjects();
                                      await _saveInOptionalSubjects();
                                      setState(() {
                                        _isProcessing = false;
                                      });
                                      if (!mounted) return;
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Subjects are Saved.", style: TextStyle(fontFamily: "Outfit")),
                                            ),
                                          );
                                        }
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please select an option for every Optional subject.", style: TextStyle(fontFamily: "Outfit")),
                                        ),
                                      );
                                    }
                                  },
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    height: 60,
                                    child: Text(
                                      selectedSubjects.isEmpty ? 'Save' : 'Update',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
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
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
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
                                  "• Select an option for each optional subject.\n"
                                      "• If a subject is not listed, please contact the admin.\n"
                                      "• After saving, the selections will be reflected in your attendance and marks records.",
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Overlay progress indicator when processing.
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}
