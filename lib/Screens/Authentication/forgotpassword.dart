import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();

  // State variables for dropdown selections.
  String? _selectedDepartment;
  String? _selectedAcademicYear;
  String? _selectedYear;
  String? _selectedSemester;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final CollectionReference _studentRef =
  FirebaseFirestore.instance.collection("students");

  // Map to hold semester options based on selected year.
  final Map<String, List<String>> semesterOptions = {
    "BE": ["7", "8"],
    "TE": ["5", "6"],
    "SE": ["3", "4"],
  };

  @override
  Widget build(BuildContext context) {
    // Determine the semester list based on the selected year.
    List<String> semesters =
    _selectedYear != null ? semesterOptions[_selectedYear!] ?? [] : [];

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  "Forgot Password",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Please enter your email to reset your password.",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Department Dropdown
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  style: const TextStyle(fontFamily: "Outfit", color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDepartment = newValue;
                    });
                  },
                  items: [
                    "CSE(AIML)",
                    "MCA",
                    "Mechanical",
                    "Chemical",
                    "IT",
                    "EXTC",
                    "Electrical"
                  ].map((String department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(department, style: const TextStyle(fontFamily: "Outfit")),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Academic Year Dropdown
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: DropdownButtonFormField<String>(
                  value: _selectedAcademicYear,
                  style: const TextStyle(fontFamily: "Outfit", color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAcademicYear = newValue;
                    });
                  },
                  items: (() {
                    final int currentYear = DateTime.now().year;
                    final int startYear = currentYear - 5;
                    const int totalYears = 11; // 5 before, current, 5 ahead
                    return List.generate(totalYears, (index) {
                      int year = startYear + index;
                      String academicYear = "$year-${year + 1}";
                      return DropdownMenuItem<String>(
                        value: academicYear,
                        child: Text(academicYear, style: const TextStyle(fontFamily: "Outfit")),
                      );
                    });
                  }()),
                ),
              ),
              const SizedBox(height: 20),
              // Year Dropdown (e.g. BE, TE, SE)
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: DropdownButtonFormField<String>(
                  value: _selectedYear,
                  style: const TextStyle(fontFamily: "Outfit", color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedYear = newValue;
                      // Reset semester when year changes.
                      _selectedSemester = null;
                    });
                  },
                  items: ["BE", "TE", "SE"].map((String year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year, style: const TextStyle(fontFamily: "Outfit")),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Semester Dropdown based on Year selection
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: DropdownButtonFormField<String>(
                  value: _selectedSemester,
                  style: const TextStyle(fontFamily: "Outfit", color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSemester = newValue;
                    });
                  },
                  items: semesters.isNotEmpty
                      ? semesters.map((String sem) {
                    return DropdownMenuItem<String>(
                      value: sem,
                      child: Text(sem, style: const TextStyle(fontFamily: "Outfit")),
                    );
                  }).toList()
                      : null,
                  hint: const Text("Select Year first", style: TextStyle(fontFamily: "Outfit")),
                ),
              ),
              const SizedBox(height: 20),
              // Email Text Field
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: TextFormField(
                  controller: _emailController,
                  style: TextStyle(fontFamily: "Outfit"),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
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
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: const Border(
                        bottom: BorderSide(color: Colors.black),
                        top: BorderSide(color: Colors.black),
                        left: BorderSide(color: Colors.black),
                        right: BorderSide(color: Colors.black),
                      ),
                    ),
                    child: MaterialButton(
                      minWidth: double.infinity,
                      height: 60,
                      onPressed: () {
                        _sendPasswordResetEmailForStudent();
                      },
                      color: Colors.greenAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        "Reset Your Password",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  void _sendPasswordResetEmailForStudent() {
    String email = _emailController.text.trim();
    String dept = _selectedDepartment ?? "";
    String ay = _selectedAcademicYear ?? "";
    String year = _selectedYear ?? "";
    String sem = _selectedSemester ?? "";

    if (email.isEmpty || dept.isEmpty || ay.isEmpty || year.isEmpty || sem.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter all fields",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    // Assuming your Firestore structure is:
    // students -> Department -> Academic Year -> Year -> Semester -> (student documents)
    _studentRef
        .doc(dept)
        .collection(ay)
        .doc(year)
        .collection(sem)
        .where("email", isEqualTo: email)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        _firebaseAuth.sendPasswordResetEmail(email: email).then((value) {
          Fluttertoast.showToast(
            msg: "Password reset email sent. Please check your inbox.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          if (!mounted) return;
          Navigator.pop(context);
        }).catchError((error) {
          Fluttertoast.showToast(
            msg: "Password reset email could not be sent. Please try again.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        });
      } else {
        Fluttertoast.showToast(
          msg: "Invalid email. Please enter a student email.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "Error: $error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    });
  }
}
