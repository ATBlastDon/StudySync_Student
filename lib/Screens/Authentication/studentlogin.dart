import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:animate_do/animate_do.dart';
import 'package:studysync_student/Screens/Authentication/forgotpassword.dart';
import 'package:studysync_student/Screens/Authentication/studentregister.dart';
import 'package:studysync_student/Screens/Repeated_Functions/password_field.dart';
import 'package:studysync_student/Screens/StudentHome/studentinternal.dart';

class StudentLogin extends StatefulWidget {
  const StudentLogin({super.key});

  @override
  State<StudentLogin> createState() => _StudentLoginState();
}

class _StudentLoginState extends State<StudentLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // New state variables for dropdowns
  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedDepartment;
  String? _selectedAcademicYear;
  String? _selectedClg;


  // Map for semester options based on year
  final Map<String, List<String>> semesterOptions = {
    "BE": ["7", "8"],
    "TE": ["5", "6"],
    "SE": ["3", "4"],
  };

  // For College and Department Lists
  List<String> _departmentList = [];
  List<String> _collegeList = [];


  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    fetchCollegeNames();
  }


  /// Fetch college names from Firebase Firestore.
  Future<void> fetchCollegeNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('colleges').get();
    final names = snapshot.docs.map((doc) => doc['name'] as String).toList();

    setState(() {
      _collegeList = names;
    });
  }


  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // Now that _prefs is initialized, check if the user is already logged in.
    checkIfLoggedIn();
  }

  void checkIfLoggedIn() {
    bool isLoggedIn = _prefs.getBool("isLoggedIn") ?? false;
    if (isLoggedIn) {
      String? clg = _prefs.getString("clg");
      String? year = _prefs.getString("year");
      String? sem = _prefs.getString("sem");
      String? dept = _prefs.getString("dept");
      String? ay = _prefs.getString("ay");

      if (clg != null && dept != null && ay != null && year != null && year.isNotEmpty && sem!.isNotEmpty) {
        if (!mounted) return;
        _navigateToStudentInternal(context, year, sem, dept, ay, clg);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: <Widget>[

                      // College Dropdown
                      buildDropdown(
                        label: "College",
                        hint: "Select College",
                        value: _selectedClg,
                        items: _collegeList,
                        onChanged: (newValue) async {
                          setState(() {
                            _selectedClg = newValue;
                            _selectedDepartment = null;
                            _departmentList = [];
                          });
                          if (newValue != null) {
                            final snapshot = await FirebaseFirestore.instance
                                .collection('colleges')
                                .doc(newValue)
                                .collection('departments')
                                .get();
                            final departments = snapshot.docs.map((doc) => doc.id).toList();

                            setState(() {
                              _departmentList = departments;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 5),

                      // Department Dropdown
                      buildDropdown(
                        label: "Department",
                        hint: "Select Department",
                        value: _selectedDepartment,
                        items: _departmentList,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDepartment = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 5,),

                      // Academic Year Dropdown
                      buildDropdown(
                        label: "Academic Year",
                        hint: "Select Academic Year",
                        value: _selectedAcademicYear,
                        items: List.generate(11, (index) {
                          final int year = DateTime.now().year - 5 + index;
                          return "$year-${year + 1}";
                        }),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedAcademicYear = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 5,),

                      // Year Dropdown
                      buildDropdown(
                        label: "Year",
                        hint: "Select Year",
                        value: _selectedYear,
                        items: ["BE", "TE", "SE"],
                        onChanged: (newValue) {
                          setState(() {
                            _selectedYear = newValue;
                            _selectedSemester = null;
                          });
                        },
                      ),
                      const SizedBox(height: 5,),

                      // Semester Dropdown
                      buildDropdown(
                        label: "Semester",
                        hint: "Select Semester",
                        value: _selectedSemester,
                        items: _selectedYear == null ? [] : semesterOptions[_selectedYear]!,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedSemester = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 5,),

                      // Email TextField
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: makeInput(
                          label: "Email",
                          controller: _emailController,
                          hintText: "Enter Your Email",
                        ),
                      ),

                      // Password TextField
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: PasswordField(
                          controller: _passwordController,
                          labelText: "Password", hintText: 'Enter Your Password',
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
      },
    );
  }


  /// Dropdown Design
  Widget buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(fontFamily: "Outfit", color: Colors.black),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            hint: Text(hint, style: const TextStyle(fontFamily: "Outfit")),
            onChanged: onChanged,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: SizedBox(
                  width: 250,
                  child: Text(
                    item,
                    style: const TextStyle(fontFamily: "Outfit"),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  /// Input Design
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
            hintText: hintText,
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
        const SizedBox(height: 10),
      ],
    );
  }


  /// Sign in Student Logic
  void signInStudent() async {
    final String? year = _selectedYear;
    final String? sem = _selectedSemester;
    final String? dept = _selectedDepartment;
    final String? ay = _selectedAcademicYear;
    final String? clg = _selectedClg;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (clg == null || ay == null || dept == null || year == null || sem == null || email.isEmpty || password.isEmpty) {
      showMessage('Please fill all fields and select Year & Semester');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black,),
        );
      },
    );

    try {
      CollectionReference studentsRef = FirebaseFirestore.instance
          .collection('colleges')
          .doc(clg)
          .collection('departments')
          .doc(dept)
          .collection("students")
          .doc(ay)
          .collection(year)
          .doc(sem)
          .collection('details');
      QuerySnapshot querySnapshot =
      await studentsRef.where("email", isEqualTo: email).get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        showMessage('Login Failed - Invalid email or password. Or Your Department, Year, Sem, Academic Year is not correct.');
        return;
      }

      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        bool isApproved = await checkApprovalStatus(email);
        if (isApproved) {
          await _saveLoginStatus(true);
          await _prefs.setString('clg', clg);
          await _prefs.setString('year', year);
          await _prefs.setString('sem', sem);
          await _prefs.setString('dept', dept);
          await _prefs.setString('ay', ay);
          if (!mounted) return;
          Navigator.pop(context);
          _navigateToStudentInternal(context, year, sem, dept, ay, clg);
        } else {
          if (!mounted) return;
          Navigator.pop(context);
          showMessage('Your student account is not approved yet.');
          await _firebaseAuth.signOut();
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showMessage('Sign-in failed. Please check your credentials.');
    }
  }

  Future<bool> checkApprovalStatus(String email) async {
    final String year = _selectedYear!;
    final String sem = _selectedSemester!;
    final String dept = _selectedDepartment!;
    final String ay = _selectedAcademicYear!;
    final String clg = _selectedClg!;
    CollectionReference studentsRef =
    FirebaseFirestore.instance
        .collection('colleges')
        .doc(clg)
        .collection('departments')
        .doc(dept)
        .collection("students")
        .doc(ay)
        .collection(year)
        .doc(sem)
        .collection('details');
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

  void _navigateToStudentInternal(BuildContext context, String year, String sem, String dept, String ay, String clg) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentInternal(year: year, sem: sem, dept: dept, ay: ay, clg:clg)),
    );
  }

  void _navigateToStudentRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentRegister()),
    );
  }
}
