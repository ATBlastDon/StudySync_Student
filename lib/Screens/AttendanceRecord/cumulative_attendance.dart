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


  const CumulativeAttendance({super.key,
    required this.rollNo,
    required this.fullName,
    required this.year,
    required this.batch,
    required this.sem,
  });

  @override
  State<CumulativeAttendance> createState() => _CumulativeAttendanceState();
}

class _CumulativeAttendanceState extends State<CumulativeAttendance> {
  String? selectedClass;
  String? selectedSem;
  // Removed selectedType; now teacher selects only subjects.
  List<String> selectedSubjects = [];

  bool isLoading = false;
  List<Map<String, dynamic>> students = [];

  final Map<String, List<String>> semesters = {
    'BE': ['7', '8'],
    'TE': ['5', '6'],
    'SE': ['3', '4'],
  };

  // Subjects are still stored per class, sem and type (Theory & Lab)
  final Map<String, Map<String, Map<String, List<String>>>> subjects = {
    'SE': {
      '3': {
        'Theory': ['EM-3', 'DSGT', 'DS', 'DLCOA', 'CG', 'JAVA', 'Mini Project 1A'],
        'Lab': ['DS', 'DLCOA', 'CG', 'JAVA'],
      },
      '4': {
        'Theory': ['EM-4', 'DBMS', 'OS', 'AOA', 'Python', 'MP', 'Mini Project 1B'],
        'Lab': ['DBMS', 'OS', 'AOA', 'Python', 'MP'],
      },
    },
    'TE': {
      '5': {
        'Theory': ['DWHM', 'CN', 'WC', 'AI', 'Mini Project 2A'],
        'Lab': ['DWHM', 'CN', 'WC', 'AI'],
      },
      '6': {
        'Theory': ['DAV', 'ML', 'SEPM', 'CSS', 'Mini Project'],
        'Lab': ['DAV', 'ML', 'SEPM', 'CSS', 'CC'],
      },
    },
    'BE': {
      '7': {
        'Theory': ['DL', 'BDA', 'Major Project 1A'],
        'Lab': ['DL', 'BDA'],
      },
      '8': {
        'Theory': ['AAI', 'Major Project'],
        'Lab': ['AAI'],
      },
    }
  };

  // Mapping for optional subjects (dlocOptions) with an extra level for mode.
  final Map<String, Map<String, Map<String, Map<String, List<String>>>>>
  dlocOptions = {
    'TE': {
      '5': {
        'Theory': {
          'DLOC1': ['Stats', 'IOT']
        },
        'Lab': {
          'DLOC1': ['Stats', 'IOT']
        },
      },
      '6': {
        'Theory': {
          'DLOC2': ['DC', 'IVP']
        },
        'Lab': {
          'DLOC2': ['DC', 'IVP']
        },
      },
    },
    'BE': {
      '7': {
        'Theory': {
          'DLOC3': ['AI For Healthcare', 'NLP', 'NNFS'],
          'DLOC4': ['UX Design with VR', 'BC', 'GT'],
          'ILOC1': ['PLM', 'RE', 'MIS', 'DOE', 'OR', 'CSL', 'DMMM', 'EAM', 'DE'],
        },
        'Lab': {
          // For BE 7 labs, only DLOC subjects are available.
          'DLOC3': ['AI For Healthcare', 'NLP', 'NNFS'],
          'DLOC4': ['UX Design with VR', 'BC', 'GT'],
        },
      },
      '8': {
        'Theory': {
          'DLOC5': ['AI for FBA', 'RL', 'QC'],
          'DLOC6': ['RS', 'SMA', 'GDS'],
          'ILOC2': ['PM', 'FM', 'EDM', 'PEC', 'RM', 'IPRP', 'DBM', 'EM'],
        },
        'Lab': {
          // For BE 8 labs, only DLOC subjects are available.
          'DLOC5': ['AI for FBA', 'RL', 'QC'],
          'DLOC6': ['RS', 'SMA', 'GDS'],
        },
      },
    },
  };

  Future<List<Map<String, dynamic>>> fetchApprovedStudents(
      String selectedClass, String selectedSem) async {
    List<Map<String, dynamic>> students = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(selectedClass)
          .collection(selectedSem)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      for (var doc in querySnapshot.docs) {
        students.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching students: $e');
    }

    return students;
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
            batch: widget.batch,
          ),
        ),
      );
    }
  }

  /// Build checkboxes for subjects by combining the regular subjects (theory & lab)
  /// and the optional subject categories from both modes.
  List<Widget> _buildSubjectCheckboxes() {
    List<String> theorySubjects =
        subjects[widget.year]?[widget.sem]?['Theory'] ?? [];
    List<String> labSubjects =
        subjects[widget.year]?[widget.sem]?['Lab'] ?? [];
    List<String> regularSubjects = [...theorySubjects, ...labSubjects];

    // Get optional subjects from both theory and lab keys in dlocOptions.
    List<String> optionalSubjects = [];
    if (dlocOptions[widget.year] != null &&
        dlocOptions[widget.year]![widget.sem] != null) {
      Map<String, List<String>>? theoryMap =
      dlocOptions[widget.year]![widget.sem]?['Theory'];
      Map<String, List<String>>? labMap =
      dlocOptions[widget.year]![widget.sem]?['Lab'];
      if (theoryMap != null) {
        optionalSubjects.addAll(theoryMap.keys);
      }
      if (labMap != null) {
        optionalSubjects.addAll(labMap.keys);
      }
    }

    // Combine the lists and remove duplicates.
    List<String> allSubjects = [...regularSubjects, ...optionalSubjects];
    allSubjects = allSubjects.toSet().toList();
    allSubjects.sort();

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
          icon:
          const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
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
                child: Center( // Center the RichText
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Note:\n",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: "Select the following Subjects to fetch Student Attendance.",
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center, // Center the text within RichText
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Removed the dropdown for "Type"
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
                              'Fetch Students',
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
