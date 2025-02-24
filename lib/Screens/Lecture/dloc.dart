import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectionSubjects extends StatefulWidget {
  final String year; // e.g. "BE"
  final String sem; // e.g. "8"
  final String rollNo; // e.g. "59"
  final String batch;

  const SelectionSubjects({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.batch,
  });

  @override
  State<SelectionSubjects> createState() => _SelectionSubjectsState();
}

class _SelectionSubjectsState extends State<SelectionSubjects> {
  // Map to hold the student’s selected option for each DLOC key.
  Map<String, String?> selectedSubjects = {};
  // Keep a copy of the previously saved subjects.
  Map<String, String?> previousSelectedSubjects = {};

  // Mapping for DLOC subjects/options.
  final Map<String, Map<String, Map<String, List<String>>>> dlocOptions = {
    'TE': {
      '5': {
        'DLOC1': ['Stats', 'IOT']
      },
      '6': {
        'DLOC2': ['DC', 'IVP']
      }
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
      }
    }
  };


  @override
  void initState() {
    super.initState();
    _loadExistingSubjects();
  }

  Future<void> _loadExistingSubjects() async {
    final String year = widget.year;
    final String sem = widget.sem;
    final String rollNo = widget.rollNo;
    final docRef = FirebaseFirestore.instance
        .collection("students")
        .doc(year)
        .collection(sem)
        .doc(rollNo)
        .collection("optional_subjects")
        .doc(sem);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists &&
        docSnapshot.data() != null &&
        docSnapshot.data()!.isNotEmpty) {
      // Convert document data to Map<String, String?>.
      setState(() {
        selectedSubjects = docSnapshot.data()!
            .map((key, value) => MapEntry(key, value.toString()));
        // Save a copy as the previous selections
        previousSelectedSubjects = Map.from(selectedSubjects);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve options for the current branch and semester.
    Map<String, List<String>>? subjectsOptions =
    dlocOptions[widget.year]?[widget.sem];

    if (subjectsOptions == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  "No Choice for DLOC or ILOC subjects",
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
          icon:
          const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
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
                  // Build a dropdown for each DLOC key (e.g. "DLOC1", "DLOC2")
                  ...subjectsOptions.entries.map((entry) {
                    final String dlocKey = entry.key;
                    final List<String> options = entry.value;
                    return FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: dlocKey,
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
                          // If a subject was already selected, it appears here.
                          value: selectedSubjects[dlocKey],
                          items: options.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option, style: TextStyle(fontFamily: "Outfit")),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSubjects[dlocKey] = newValue;
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
                              onPressed: () {
                                if (_allOptionsSelected(subjectsOptions.keys.toList())) {
                                  _saveSelectedSubjects();
                                  _saveInOptionalSubjects();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select an option for every Optional subject.",
                                        style: TextStyle(fontFamily: "Outfit"),
                                      ),
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
                  const SizedBox(height: 30), // Add some spacing above the note
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
    );
  }

  // Helper: make sure every DLOC subject has a selected value.
  bool _allOptionsSelected(List<String> dlocKeys) {
    for (var key in dlocKeys) {
      if (selectedSubjects[key] == null) return false;
    }
    return true;
  }

  // Save (or update) the selected subjects in the student's document.
  void _saveSelectedSubjects() async {
    final String year = widget.year;
    final String sem = widget.sem;
    final String rollNo = widget.rollNo;

    final docRef = FirebaseFirestore.instance
        .collection("students")
        .doc(year)
        .collection(sem)
        .doc(rollNo)
        .collection("optional_subjects")
        .doc(sem);

    try {
      // Merge so that if the document exists, it gets updated.
      await docRef.set(selectedSubjects, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wait for a While...", style: TextStyle(fontFamily: "Outfit"))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error saving subjects. Please try again.", style: TextStyle(fontFamily: "Outfit"))),
      );
    }
  }

  void _saveInOptionalSubjects() async {
    final String year = widget.year;
    final String sem = widget.sem;
    final String rollNo = widget.rollNo;

    for (final entry in selectedSubjects.entries) {
      final String dlocKey = entry.key;
      final String newSubject = entry.value!;
      final String? oldSubject = previousSelectedSubjects[dlocKey];

      // If there is an old selection that is different than the new one, remove the rollNo
      if (oldSubject != null && oldSubject != newSubject) {
        final oldDocRef = FirebaseFirestore.instance
            .collection("optional_subjects")
            .doc(year)
            .collection(sem)
            .doc(dlocKey)
            .collection(oldSubject)
            .doc(rollNo);
        try {
          await oldDocRef.delete();
        } catch (error) {
          // Handle errors if needed (e.g. the document might not exist)
        }
      }

      // Add (or update) the new selection.
      final newDocRef = FirebaseFirestore.instance
          .collection("optional_subjects")
          .doc(year)
          .collection(sem)
          .doc(dlocKey)
          .collection(newSubject)
          .doc(rollNo);

      await newDocRef.set({
        'batch': widget.batch, // Store the batch as a field in the document.
      });
    }


    // Update the previousSelectedSubjects for any future changes.
    previousSelectedSubjects = Map.from(selectedSubjects);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subjects saved successfully.", style: TextStyle(fontFamily: "Outfit"),)),
    );
  }
}
