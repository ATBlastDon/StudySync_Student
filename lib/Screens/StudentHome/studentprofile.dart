import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysync_student/Screens/Authentication/studentlogin.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfile extends StatefulWidget {
  final String studentmail;
  final String studentyear;
  final String sem;

  const StudentProfile({
    super.key,
    required this.studentmail,
    required this.studentyear,
    required this.sem,
  });

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  bool isEditingRollNo = false;
  bool isEditingYear = false;
  bool isEditingSem = false;
  bool isEditingBatch = false;
  bool isEditingMentor = false;
  bool loadingTeachers = false;
  bool isUpdatingPhoto = false;


  TextEditingController rollNoController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  TextEditingController semController = TextEditingController();
  TextEditingController batchController = TextEditingController();
  TextEditingController mentorController = TextEditingController();

  List<String> batches = ['B1', 'B2', 'B3', 'B4'];
  List<String> classes = ['BE', 'TE', 'SE'];
  List<Map<String, String>> teachers = [];
  String? selectedBatch;
  String? selectedYear;
  Map<String, String>? selectedMentor;

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
    fetchTeachers();
  }

  Future<void> fetchTeachers() async {
    setState(() => loadingTeachers = true);
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('teachers').get();

      teachers = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return <String, String>{
          'id': doc.id,
          'fullName': '${data['fname'] ?? ''} ${data['mname'] ?? ''} ${data['sname'] ?? ''}'
              .trim()
              .replaceAll('  ', ' '),
        };
      }).toList();

      setState(() => loadingTeachers = false);
    } catch (e) {
      setState(() => loadingTeachers = false);
      Fluttertoast.showToast(msg: "Error fetching teachers: $e");
    }
  }

  Future<void> fetchStudentDetails() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentyear)
          .collection(widget.sem)
          .where('email', isEqualTo: widget.studentmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          studentData = userData;
          isLoading = false;
        });
        rollNoController.text = studentData!['rollNo'] ?? 'N/A';
        yearController.text = widget.studentyear;
        semController.text = widget.sem;
        batchController.text = studentData!['batch'] ?? 'N/A';
        mentorController.text = studentData!['mentor'] ?? 'N/A';
      } else {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'User Not Found in Database',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(
        msg: 'Error occurred: $error',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> showConfirmationDialog(Function updateFunction) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 12)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 56,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm Change?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Are you sure you want to change your details? If you do, your data will be lost, and the app will reassign your data from the login.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        label: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: Colors.amber.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext, rootNavigator: true).pop();
                          updateFunction();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> updateRollNo() async {
    if (rollNoController.text.isEmpty) return;

    final rollNoQuerySnapshot = await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentyear)
        .collection(widget.sem)
        .where('rollNo', isEqualTo: rollNoController.text)
        .get();

    if (rollNoQuerySnapshot.docs.isNotEmpty) {
      Fluttertoast.showToast(
        msg: 'Roll Number is already taken by another student.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    showConfirmationDialog(() async {
      try {
        DocumentReference newDocRef = FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentyear)
            .collection(widget.sem)
            .doc(rollNoController.text);

        await newDocRef.set(studentData!);

        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentyear)
            .collection(widget.sem)
            .doc(studentData!['rollNo'])
            .delete();

        setState(() {
          studentData!['rollNo'] = rollNoController.text;
          isEditingRollNo = false;
        });

        await newDocRef.update({
          'rollNo': rollNoController.text,
        });

        Fluttertoast.showToast(
          msg: 'Roll Number updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (error) {
        Fluttertoast.showToast(
          msg: 'Error updating Roll Number: $error',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  Future<void> updateBatch() async {
    if (batchController.text.isEmpty) return;

    showConfirmationDialog(() async {
      try {
        DocumentReference studentDocRef = FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentyear)
            .collection(widget.sem)
            .doc(rollNoController.text);

        await studentDocRef.update({
          'batch': batchController.text,
        });

        setState(() {
          isEditingBatch = false;
        });

        Fluttertoast.showToast(
          msg: 'Batch updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (error) {
        Fluttertoast.showToast(
          msg: 'Error updating batch: $error',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  Future<void> updateMentor() async {
    showConfirmationDialog(() async {
      try {
        DocumentReference studentDocRef = FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentyear)
            .collection(widget.sem)
            .doc(rollNoController.text);

        await studentDocRef.update({
          'mentor': selectedMentor!['fullName'],
        });

        setState(() {
          isEditingMentor = false;
        });

        Fluttertoast.showToast(
          msg: 'Mentor updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (error) {
        Fluttertoast.showToast(
          msg: 'Error updating Mentor: $error',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  Future<void> updateSem() async {
    if (semController.text.isEmpty) return;

    showConfirmationDialog(() async {
      try {
        DocumentReference newDocRef = FirebaseFirestore.instance
            .collection('students')
            .doc(studentData!['year'])
            .collection(semController.text)
            .doc(studentData!['rollNo']);

        await newDocRef.set(studentData!);

        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentyear)
            .collection(widget.sem)
            .doc(studentData!['rollNo'])
            .delete();

        setState(() {
          studentData!['semester'] = semController.text;
          isEditingSem = false;
        });

        await newDocRef.update({
          'semester': semController.text,
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        Fluttertoast.showToast(
          msg: 'Semester updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => StudentLogin()),
              (route) => false,
        );
      } catch (error) {
        Fluttertoast.showToast(
          msg: 'Error updating Semester: $error',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  Future<void> updateYear() async {
    if (yearController.text.isEmpty) return;

    showConfirmationDialog(() async {
      try {
        DocumentReference newDocRef = FirebaseFirestore.instance
            .collection('students')
            .doc(yearController.text)
            .collection(widget.sem)
            .doc(studentData!['rollNo']);

        await newDocRef.set(studentData!);

        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentyear)
            .collection(widget.sem)
            .doc(studentData!['rollNo'])
            .delete();

        setState(() {
          studentData!['year'] = yearController.text;
          studentData!['class'] = yearController.text;
          isEditingYear = false;
        });

        await newDocRef.update({
          'class': yearController.text,
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        Fluttertoast.showToast(
          msg: 'Year and Class updated successfully. Please log in again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => StudentLogin()),
              (route) => false,
        );
      } catch (error) {
        Fluttertoast.showToast(
          msg: 'Error updating Year: $error',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  // New method to change profile photo.
  Future<void> _changeProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        isUpdatingPhoto = true;
      });
      try {
        // Delete previous profile photo if exists.
        if (studentData!['profilePhotoUrl'] != null &&
            (studentData!['profilePhotoUrl'] as String).isNotEmpty) {
          firebase_storage.Reference oldRef =
          firebase_storage.FirebaseStorage.instance
              .refFromURL(studentData!['profilePhotoUrl']);
          await oldRef.delete();
        }
        // Prepare new file name and storage path.
        String fileName = '${studentData!['rollNo']}.jpg';
        String storagePath = 'Profile_Photos/Student/${widget.studentyear}/$fileName';
        firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref().child(storagePath);
        // Upload the file.
        await ref.putFile(File(image.path));
        String newUrl = await ref.getDownloadURL();
        // Update Firestore record.
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentyear)
            .collection(widget.sem)
            .doc(studentData!['rollNo'])
            .update({'profilePhotoUrl': newUrl});
        setState(() {
          studentData!['profilePhotoUrl'] = newUrl;
        });
        Fluttertoast.showToast(msg: 'Profile photo updated successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error updating profile photo: $e');
      } finally {
        setState(() {
          isUpdatingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'P R O F I L E',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade200, Colors.greenAccent.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : studentData == null
              ? const Center(child: Text("No student data available", style: TextStyle(fontFamily: "Outfit")))
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile photo with pencil icon overlay and circular progress.
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundImage: studentData!['profilePhotoUrl'] != null
                                  ? CachedNetworkImageProvider(studentData!['profilePhotoUrl'])
                                  : null,
                              child: studentData!['profilePhotoUrl'] == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.greenAccent)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FadeInUp(
                              duration: const Duration(milliseconds: 500),
                              child: GestureDetector(
                                onTap: _changeProfilePhoto,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(scale: animation, child: child);
                                    },
                                    child: isUpdatingPhoto
                                        ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                      ),
                                    )
                                        : const Icon(
                                      Icons.edit,
                                      key: ValueKey('icon'),
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: TextField(
                        readOnly: true,
                        style: TextStyle(fontFamily: 'Outfit'),
                        decoration: InputDecoration(
                          labelText: "Name",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                        controller: TextEditingController(
                          text:
                          "${studentData!['fname'] ?? ''} ${studentData!['mname'] ?? ''} ${studentData!['sname'] ?? ''}",
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: TextField(
                        readOnly: !isEditingRollNo,
                        style: TextStyle(fontFamily: 'Outfit'),
                        controller: rollNoController,
                        decoration: InputDecoration(
                          labelText: "Roll Number",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          suffixIcon: IconButton(
                            icon: Icon(isEditingRollNo ? Icons.save : Icons.edit, color: Colors.teal),
                            onPressed: () {
                              if (isEditingRollNo) {
                                updateRollNo();
                              } else {
                                setState(() {
                                  isEditingRollNo = true;
                                });
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: isEditingYear
                          ? Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedYear ?? yearController.text,
                              decoration: InputDecoration(
                                labelText: "Class",
                                labelStyle: TextStyle(fontFamily: "Outfit"),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: classes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(fontFamily: 'Outfit'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedYear = value;
                                  yearController.text = value!;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save, color: Colors.teal),
                            onPressed: () {
                              updateYear();
                              setState(() {
                                isEditingYear = false;
                              });
                            },
                          ),
                        ],
                      )
                          : TextField(
                        readOnly: true,
                        style: TextStyle(fontFamily: 'Outfit'),
                        controller: yearController,
                        decoration: InputDecoration(
                          labelText: "Class",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => setState(() => isEditingYear = true),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: TextField(
                        readOnly: !isEditingSem,
                        style: TextStyle(fontFamily: 'Outfit'),
                        controller: semController,
                        decoration: InputDecoration(
                          labelText: "Semester",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          suffixIcon: IconButton(
                            icon: Icon(isEditingSem ? Icons.save : Icons.edit, color: Colors.teal),
                            onPressed: () {
                              if (isEditingSem) {
                                updateSem();
                              } else {
                                setState(() {
                                  isEditingSem = true;
                                });
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: isEditingBatch
                          ? Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: batches.contains(selectedBatch ?? batchController.text)
                                  ? selectedBatch ?? batchController.text
                                  : null,
                              hint: const Text("Select Batch", style: TextStyle(fontFamily: "Outfit")),
                              decoration: InputDecoration(
                                labelText: "Batch",
                                labelStyle: TextStyle(fontFamily: "Outfit"),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  enabled: false,
                                  child: Text('Select Batch',
                                      style: TextStyle(fontFamily: "Outfit", color: Colors.grey)),
                                ),
                                ...batches.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: TextStyle(fontFamily: "Outfit")),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedBatch = value;
                                  if (value != null) {
                                    batchController.text = value;
                                  }
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save, color: Colors.teal),
                            onPressed: () {
                              if (selectedBatch != null) {
                                updateBatch();
                                setState(() {
                                  isEditingBatch = false;
                                });
                              }
                            },
                          ),
                        ],
                      )
                          : TextField(
                        readOnly: true,
                        style: TextStyle(fontFamily: 'Outfit'),
                        controller: batchController,
                        decoration: InputDecoration(
                          labelText: "Batch",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => setState(() => isEditingBatch = true),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: isEditingMentor
                          ? loadingTeachers
                          ? const CircularProgressIndicator()
                          : teachers.isEmpty
                          ? const Text("No teachers available", style: TextStyle(fontFamily: "Outfit"))
                          : Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Map<String, String>>(
                              value: selectedMentor,
                              hint: const Text("Select Mentor", style: TextStyle(fontFamily: "Outfit")),
                              decoration: InputDecoration(
                                labelText: "Mentor",
                                labelStyle: TextStyle(fontFamily: "Outfit"),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: teachers.map((teacher) {
                                return DropdownMenuItem<Map<String, String>>(
                                  value: teacher,
                                  child: Text(teacher['fullName']!, style: TextStyle(fontFamily: "Outfit")),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedMentor = value;
                                  mentorController.text = value?['fullName'] ?? '';
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save, color: Colors.teal),
                            onPressed: () {
                              if (selectedMentor != null) {
                                updateMentor();
                                setState(() => isEditingMentor = false);
                              }
                            },
                          ),
                        ],
                      )
                          : TextField(
                        readOnly: true,
                        style: TextStyle(fontFamily: 'Outfit'),
                        controller: mentorController,
                        decoration: InputDecoration(
                          labelText: "Mentor",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => setState(() => isEditingMentor = true),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: TextField(
                        readOnly: true,
                        style: TextStyle(fontFamily: 'Outfit'),
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                        controller: TextEditingController(text: studentData!['email']),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: TextField(
                        readOnly: true,
                        style: TextStyle(fontFamily: 'Outfit'),
                        decoration: InputDecoration(
                          labelText: "Phone No",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                        controller: TextEditingController(text: studentData!['phoneNo']),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: TextField(
                        readOnly: true,
                        style: TextStyle(fontFamily: 'Outfit'),
                        decoration: InputDecoration(
                          labelText: "Registration No.",
                          labelStyle: TextStyle(fontFamily: "Outfit"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                        controller: TextEditingController(text: studentData!['regNo']),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
