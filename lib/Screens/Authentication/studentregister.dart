import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studysync_student/Screens/Authentication/studentlogin.dart';
import 'package:studysync_student/Screens/NoticeBoard/noticeboard.dart';
import 'package:studysync_student/Screens/Repeated_Functions/password_field.dart';

class StudentRegister extends StatefulWidget {
  const StudentRegister({super.key});

  @override
  State<StudentRegister> createState() => _StudentRegisterState();
}


class _StudentRegisterState extends State<StudentRegister> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _mnameController = TextEditingController();
  final TextEditingController _snameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _phoneNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedClg;
  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedDepartment;
  String? _selectedAcademicYear;
  File? _selectedImage;

  // Map for semester options based on year
  final Map<String, List<String>> semesterOptions = {
    "BE": ["7", "8"],
    "TE": ["5", "6"],
    "SE": ["3", "4"],
  };

  // Lists for College and Department
  List<String> _departmentList = [];
  List<String> _collegeList = [];


  @override
  void initState() {
    super.initState();
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


  /// TextStyle with 'Outfit' font family
  final TextStyle _outfitTextStyle = const TextStyle(
    fontFamily: 'Outfit',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: KeyboardVisibilityBuilder(
          builder: (context, isKeyboardVisible) {
            return SingleChildScrollView(
              child: Stack(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          AppBar().preferredSize.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: const Text(
                                  "Sign up",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: const Text(
                                  "Create an Student account, \nIt's free 😉",
                                  style: TextStyle(
                                    fontFamily: "Outfit",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              const SizedBox(height: 25),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: makeInput(
                                  label: "First Name",
                                  controller: _fnameController,
                                  hintText: "Rajesh",
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: makeInput(
                                  label: "Middle Name",
                                  controller: _mnameController,
                                  hintText: "Suresh",
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: makeInput(
                                  label: "Surname",
                                  controller: _snameController,
                                  hintText: "Pawar",
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: makeInput(
                                  label: "Email",
                                  controller: _emailController,
                                  hintText: "abc123@gmail.com",
                                ),
                              ),
                              // Year Dropdown
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("College", style: _outfitTextStyle),
                                    const SizedBox(height: 5),
                                    DropdownButtonFormField<String>(
                                      value: _selectedClg,
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
                                      hint: const Text("Select College", style: TextStyle(fontFamily: "Outfit")),
                                      onChanged: (String? newValue) async {
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
                                      items: _collegeList.map((String college) {
                                        return DropdownMenuItem<String>(
                                          value: college,
                                          child: SizedBox(
                                            width: 250, // fixed width to avoid overflow
                                            child: Text(
                                              college,
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
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Department", style: _outfitTextStyle),
                                    const SizedBox(height: 5),
                                    DropdownButtonFormField<String>(
                                      value: _selectedDepartment,
                                      style: const TextStyle(fontFamily: "Outfit", color: Colors.black, overflow: TextOverflow.ellipsis),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                      ),
                                      hint: const Text("Select Department", style: TextStyle(fontFamily: "Outfit")),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedDepartment = newValue;
                                        });
                                      },
                                      items: _departmentList.map((String department) {
                                        return DropdownMenuItem<String>(
                                          value: department,
                                          child: Text(
                                            department,
                                            style: const TextStyle(fontFamily: "Outfit", overflow: TextOverflow.ellipsis),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Academic Year",
                                      style: _outfitTextStyle,
                                    ),
                                    const SizedBox(height: 5),
                                    DropdownButtonFormField<String>(
                                      value: _selectedAcademicYear,
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
                                      hint: const Text("Select Academic Year", style: TextStyle(fontFamily: "Outfit")),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedAcademicYear = newValue;
                                        });
                                      },
                                      items: (() {
                                        // Get the current year.
                                        final int currentYear = DateTime.now().year;
                                        // Generate a list from 5 years before to 5 years after.
                                        final int startYear = currentYear - 5;
                                        final int totalYears = 11; // 5 before, current, 5 ahead
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
                                  ],
                                ),
                              ),

                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Year",
                                      style: _outfitTextStyle,
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
                                      hint: Text("BE / TE / SE", style: TextStyle(fontFamily: "Outfit")),
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
                                          child: Text(year, style: TextStyle(fontFamily: "Outfit")),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              // Semester Dropdown (dependent on Year)
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Semester", style: _outfitTextStyle),
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
                                      hint: Text("3/4/5/6/7/8", style: TextStyle(fontFamily: "Outfit")),
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
                                          child: Text(sem, style: TextStyle(fontFamily: "Outfit")),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: makeInput(
                                  label: "Roll No",
                                  controller: _rollNoController,
                                  hintText: "Enter your class Roll Number - 23",
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: makeInput(
                                  label: "Registration No",
                                  controller: _regNoController,
                                  hintText: "A-21-0030",
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: makeInput(
                                  label: "Mobile No",
                                  controller: _phoneNoController,
                                  hintText: "1234567890",
                                ),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: PasswordField(controller: _passwordController, hintText: 'Enter Your Password',),
                              ),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: PasswordField(
                                  controller: _confirmPasswordController,
                                  labelText: "Confirm Password", hintText: 'Confirm Your Password',
                                ),
                              ),
                              const SizedBox(height: 30),
                              FadeInUp(
                                duration: const Duration(milliseconds: 1000),
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
                                      _register(context);
                                    },
                                    color: Colors.greenAccent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Text(
                                      "Sign up",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          FadeInUp(
                            duration: const Duration(milliseconds: 1000),
                            child: Transform.translate(
                              offset: const Offset(0, -30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      "Already Have An Account?",
                                      style: _outfitTextStyle,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const StudentLogin()),
                                        );
                                      },
                                      child: const Text(
                                        " Login",
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
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 40,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.camera),
                                    title: const Text('Take a photo',style: TextStyle(fontFamily: "Outfit"),),
                                    onTap: () async {
                                      await _getImageFromCamera();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Choose from gallery',style: TextStyle(fontFamily: "Outfit")),
                                    onTap: () async {
                                      await _getImageFromGallery();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.greenAccent,
                          radius: 35,
                          child: _selectedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: 70,
                              height: 70,
                            ),
                          )
                              : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Widget makeInput(
      {required String label,
        bool obscureText = false,
        required TextEditingController controller, required String hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: _outfitTextStyle,
        ),
        const SizedBox(height: 5),
        TextField(
          style: TextStyle(fontFamily: "Outfit"),
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText, // Display the hint text here
            hintStyle: TextStyle(fontFamily: "Outfit"),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _register(BuildContext context) async {
    // Validate input fields
    if (!_validateFields()) {
      return;
    }

    // Show loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.black,),
                SizedBox(height: 20.0),
                Text("Registering...",style: TextStyle(fontFamily: "Outfit"),),
              ],
            ),
          ),
        );
      },
    );

    try {
      String fname = _fnameController.text.trim();
      String mname = _mnameController.text.trim();
      String sname = _snameController.text.trim();
      String email = _emailController.text.trim();
      String year = _selectedYear!;
      String sem = _selectedSemester!;
      String clg = _selectedClg!;
      String dept = _selectedDepartment!;
      String ay = _selectedAcademicYear!;
      String rollNo = _rollNoController.text.trim();
      String regNo = _regNoController.text.trim();
      String phoneNo = _phoneNoController.text.trim();
      String password = _passwordController.text.trim();

      // Check if email exists
      QuerySnapshot emailSnapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .doc(_selectedClg)
          .collection('departments')
          .doc(_selectedDepartment)
          .collection("students")
          .doc(ay)
          .collection(year)
          .doc(sem)
          .collection('details')
          .where("email", isEqualTo: email)
          .get();
      if (emailSnapshot.docs.isNotEmpty) {
        if(context.mounted){
          Navigator.of(context).pop(); // Dismiss loading dialog
          showMessage(context, "Email is already taken");
          return;
        }
      }

      QuerySnapshot regSnapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .doc(_selectedClg)
          .collection('departments')
          .doc(_selectedDepartment)
          .collection("students")
          .doc(ay)
          .collection(year)
          .doc(sem)
          .collection('details')
          .where("regNo", isEqualTo: regNo)
          .get();
      if (regSnapshot.docs.isNotEmpty) {
        if(context.mounted){
          Navigator.of(context).pop(); // Dismiss loading dialog
          showMessage(context, "Registration number is already taken");
          return;
        }
      }

      // Check if roll number exists
      DocumentSnapshot rollNoSnapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .doc(_selectedClg)
          .collection('departments')
          .doc(_selectedDepartment)
          .collection("students")
          .doc(ay)
          .collection(year)
          .doc(sem)
          .collection('details')
          .doc(rollNo) // Check the specific roll number
          .get();

      if (rollNoSnapshot.exists) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
          showMessage(context, "$year class has already registered this roll number");
          return;
        }
      }


      // Proceed with registration
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Upload profile photo
        await _uploadProfilePhoto(
            _selectedImage!, rollNo, fname, mname, sname, email,dept, ay, year, sem, regNo, phoneNo, clg);
        if(context.mounted){
          Navigator.of(context).pop(); // Dismiss loading dialog
        }

        // Show success message with correct icon
        if(context.mounted){
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Registration Successful",style: TextStyle(fontFamily: "Outfit"),),
                content:
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudentLogin()),
                      );
                    },
                    child: const Text("OK",style: TextStyle(fontFamily: "Outfit", color: Colors.black),),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if(context.mounted){
        Navigator.of(context).pop(); // Dismiss loading dialog
        showMessage(context, "Registration Failed: $e");
      }
    }
  }

  bool _validateFields() {
    String fname = _fnameController.text.trim();
    String mname = _mnameController.text.trim();
    String sname = _snameController.text.trim();
    String email = _emailController.text.trim();
    String year = _selectedYear!;
    String sem = _selectedSemester!;
    String clg = _selectedClg!;
    String dept = _selectedDepartment!;
    String ay = _selectedAcademicYear!;
    String rollNo = _rollNoController.text.trim();
    String regNo = _regNoController.text.trim();
    String phoneNo = _phoneNoController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (fname.isEmpty ||
        mname.isEmpty ||
        sname.isEmpty ||
        email.isEmpty ||
        clg.isEmpty ||
        dept.isEmpty ||
        ay.isEmpty ||
        year.isEmpty ||
        sem.isEmpty ||
        rollNo.isEmpty ||
        regNo.isEmpty ||
        phoneNo.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(context, "Please fill all fields");
      return false;
    }

    if (password != confirmPassword) {
      showMessage(context, "Passwords don't match");
      return false;
    }

    if (_selectedImage == null) {
      showMessage(context, "Please select a profile photo");
      return false;
    }

    return true;
  }

  Future<void> _uploadProfilePhoto(File profilePhotoUri, String rollNo,
      String fname, mname, sname, String email,String dept, String ay, String year, String sem, String regNo, String phoneNo, String clg) async {

    try {
      // Read image as bytes
      final imageBytes = await profilePhotoUri.readAsBytes();

      // Decode image to manipulate
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Invalid image file.");
      }

      // Resize or compress the image
      final compressedImage = img.copyResize(image, width: 300); // Resize to 300px width
      final compressedBytes = Uint8List.fromList(img.encodeJpg(compressedImage, quality: 85)); // Compress with 85% quality

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref()
          .child("$clg/$dept/student/$ay/$year/$sem")
          .child("$rollNo.jpg");
      final uploadTask = storageRef.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      await uploadTask;

      // Get the download URL
      final downloadURL = await storageRef.getDownloadURL();

      // Save profile details to Firestore
      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(clg)
          .collection('departments')
          .doc(dept)
          .collection("students")
          .doc(ay)
          .collection(year)
          .doc(sem)
          .collection('details')
          .doc(rollNo)
          .set({
        "fname": fname,
        "mname": mname,
        "sname": sname,
        "email": email,
        "regNo": regNo,
        "rollNo": rollNo,
        "dept": dept,
        "ay": ay,
        "clg": clg,
        "year": year,
        "semester": sem,
        "phoneNo": phoneNo,
        "profilePhotoUrl": downloadURL,
        "approvalStatus": "pending",
        "batch":"none",
        "mentor":"none",
      });

      await _notificationAdd(dept, ay, year, sem, rollNo);

      logger.i("Profile photo uploaded successfully for roll number: $rollNo");
    } catch (e, stackTrace) {
      logger.e("Failed to upload profile photo for roll number: $rollNo", error: e, stackTrace: stackTrace);
      rethrow;
    }
  }


  Future<void> _getImageFromCamera() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Message",style: TextStyle(fontFamily: "Outfit")),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK",style: TextStyle(fontFamily: "Outfit", color: Colors.black),),
            ),
          ],
        );
      },
    );
  }

  Future<void> _notificationAdd(String dept, String ay, String year, String sem, String rollNo) async {
    String notificationId = FirebaseFirestore.instance.collection('notifications').doc().id;
    String fullName = "${_fnameController.text.trim()} ${_mnameController.text.trim()} ${_snameController.text.trim()}";
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc("ApproveStudent")
        .collection("requests")
        .doc(notificationId)
        .set({
      'title': 'Notification of Student Approval Request',
      'name': fullName,
      'sentAt': DateTime.now(),
      'dept': dept,
      'ay': ay,
      'year': year,
      'sem': sem,
      'rollNo': rollNo,
      'status': 'pending',
      'notificationId': notificationId,
    });
  }



}