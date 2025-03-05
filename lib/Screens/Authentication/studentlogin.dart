import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:animate_do/animate_do.dart';
import 'package:studysync_student/Screens/Authentication/forgotpassword.dart';
import 'package:studysync_student/Screens/Authentication/studentregister.dart';
import 'package:studysync_student/Screens/StudentHome/studentinternal.dart';

class StudentLogin extends StatefulWidget {
  const StudentLogin({super.key});

  @override
  State<StudentLogin> createState() => _StudentLoginState();
}

class _StudentLoginState extends State<StudentLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Removed _yearController and _semController

  // New state variables for dropdowns
  String? _selectedYear;
  String? _selectedSemester;

  // Map for semester options based on year
  final Map<String, List<String>> semesterOptions = {
    "BE": ["7", "8"],
    "TE": ["5", "6"],
    "SE": ["3", "4"],
  };

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    checkIfLoggedIn();
  }

  void checkIfLoggedIn() async {
    bool isLoggedIn = await _isLoggedIn();
    if (isLoggedIn) {
      String? year = _prefs.getString("year");
      String? sem = _prefs.getString("sem");

      if (year != null && year.isNotEmpty && sem!.isNotEmpty) {
        // If user is already logged in, navigate to the student internal page
        if (!mounted) return;
        _navigateToStudentInternal(context, year, sem);
      }
    }
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void navigateToStudentRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentRegister()),
    );
  }

  void showMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    await _prefs.setBool('isLoggedIn', isLoggedIn);
  }

  Future<bool> _isLoggedIn() async {
    return _prefs.getBool('isLoggedIn') ?? false;
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
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView( // Wrap the entire body with a SingleChildScrollView
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              children: <Widget>[
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Text(
                    "Login to your Student account",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: <Widget>[
                  // Year Dropdown
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Year",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: _selectedYear,
                          style: TextStyle(fontFamily: "Outfit",color: Colors.black),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          hint: const Text("Select Year", style: TextStyle(fontFamily: "Outfit")),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedYear = newValue;
                              // Reset semester when year changes
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),

                  // Semester Dropdown (dependent on Year)
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Semester",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: _selectedSemester,
                          style: TextStyle(fontFamily: "Outfit",color: Colors.black),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          hint: const Text("Select Semester", style: TextStyle(fontFamily: "Outfit")),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSemester = newValue;
                            });
                          },
                          items: _selectedYear == null
                              ? []
                              : semesterOptions[_selectedYear]!.map((String sem) {
                            return DropdownMenuItem<String>(
                              value: sem,
                              child: Text(sem, style: const TextStyle(fontFamily: "Outfit")),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: makeInput(
                      label: "Email",
                      controller: _emailController,
                      hintText: "Enter Your Email",
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: PasswordField(
                      controller: _passwordController,
                      labelText: "Password",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
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
                      signInStudent();
                    },
                    color: Colors.greenAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      "Login",
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
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Transform.translate(
                offset: const Offset(0, -35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPassword(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Your Password?",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Transform.translate(
                offset: const Offset(0, -36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Don't Have an Account?",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextButton(
                        onPressed: () {
                          _navigateToStudentRegister(context);
                        },
                        child: const Text(
                          " SignUp",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget makeInput({required String label, required TextEditingController controller, required String hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          style: TextStyle(fontFamily: "Outfit"),
          controller: controller,
          obscureText: label == "Password" ? true : false,
          decoration: InputDecoration(
            hintText: hintText, // Display the hint text here
            hintStyle: TextStyle(fontFamily: "Outfit"),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void signInStudent() async {
    // Retrieve year and semester from dropdown selections
    final String? year = _selectedYear;
    final String? sem = _selectedSemester;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (year == null || sem == null || email.isEmpty || password.isEmpty) {
      showMessage('Please fill all fields and select Year & Semester');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      CollectionReference studentsRef = FirebaseFirestore.instance
          .collection("students")
          .doc(year)
          .collection(sem);
      QuerySnapshot querySnapshot =
      await studentsRef.where("email", isEqualTo: email).get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context); // Dismiss the progress indicator
        showMessage('Email not found');
        return;
      }

      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        bool isApproved = await checkApprovalStatus(email);
        if (isApproved) {
          await _saveLoginStatus(true);
          await _prefs.setString('year', year);
          await _prefs.setString('sem', sem);
          if (!mounted) return;
          Navigator.pop(context); // Dismiss the progress indicator
          _navigateToStudentInternal(context, year, sem);
        } else {
          if (!mounted) return;
          Navigator.pop(context); // Dismiss the progress indicator
          showMessage('Your student account is not approved yet.');
          await _firebaseAuth.signOut();
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss the progress indicator
      showMessage('Sign-in failed. Please check your credentials.');
    }
  }

  Future<bool> checkApprovalStatus(String email) async {
    final String year = _selectedYear!;
    final String sem = _selectedSemester!;
    CollectionReference studentsRef =
    FirebaseFirestore.instance.collection("students").doc(year).collection(sem);
    QuerySnapshot querySnapshot =
    await studentsRef.where("email", isEqualTo: email).get();

    try {
      if (querySnapshot.docs.isNotEmpty) {
        String approvalStatus = querySnapshot.docs.first["approvalStatus"];
        return approvalStatus == "approved";
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: 'Error occurred: $error',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    return false;
  }

  void _navigateToStudentInternal(BuildContext context, String year, String sem) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentInternal(year: year, sem: sem)),
    );
  }

  void _navigateToStudentRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentRegister()),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;

  const PasswordField({super.key, required this.controller, this.labelText = 'Password', this.hintText = 'Enter Your Password'});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.labelText,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: widget.hintText, // Display the hint text here
            hintStyle: TextStyle(fontFamily: "Outfit"),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
