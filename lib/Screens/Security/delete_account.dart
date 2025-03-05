import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysync_student/Home/homepage.dart';
import 'package:studysync_student/Screens/Security/delete_attendance_record.dart';

class DeleteAccount extends StatefulWidget {
  final String year;
  final String sem;
  final String rollNo;

  const DeleteAccount({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
  });

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });
    try {
      // 1. Delete profile photo from Firebase Storage.
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('Profile_Photos/Student/${widget.year}/${widget.rollNo}.jpg');
      await storageRef.delete().catchError((error) {
        // Log error, but continue if the file is missing.
        debugPrint('Error deleting profile photo: $error');
      });

      // 2. Delete the nested optional subjects document.
      // This assumes the structure is:
      // students/{year}/{sem}/{rollNo}/optional_subjects/{sem}
      final optionalSubjectsDocRef = FirebaseFirestore.instance
          .collection('students')
          .doc(widget.year)
          .collection(widget.sem)
          .doc(widget.rollNo)
          .collection('optional_subjects')
          .doc(widget.sem);
      await optionalSubjectsDocRef.delete().catchError((error) {
        debugPrint('Error deleting optional subjects: $error');
      });

      // 3. Delete the student document from Firestore.
      final studentDocRef = FirebaseFirestore.instance
          .collection('students')
          .doc(widget.year)
          .collection(widget.sem)
          .doc(widget.rollNo);
      await studentDocRef.delete();

      await DeleteAttendance.deleteAttendanceRecords(widget.rollNo);


      // 4. Delete the user account from Firebase Auth.
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // In many cases, reauthentication may be required before deletion.
        await user.delete();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account deleted successfully!",style: TextStyle(fontFamily: "Outfit"),),
          backgroundColor: Colors.green,
        ),
      );

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to StudentHome screen.
      if(!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "An error occurred.",style: TextStyle(fontFamily: "Outfit")),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(),style: TextStyle(fontFamily: "Outfit")),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      _isDeleting = false;
    });
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FadeInUp(
          duration: const Duration(milliseconds: 800),
          child: Dialog(
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
                  BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2), blurRadius: 12)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Icon(
                      Icons.warning_rounded,
                      size: 56,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: const Text(
                      'Confirm Account Deletion?',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Are you sure you want to delete your account? This action is irreversible. Your profile photo, account data, and all associated details will be permanently removed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.cancel_outlined,
                              size: 20,
                              color: Colors.black,
                            ),
                            label: Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
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
                              Navigator.of(dialogContext, rootNavigator: true)
                                  .pop();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 20,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                              shadowColor: Colors.red.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(dialogContext, rootNavigator: true)
                                  .pop();
                              _deleteAccount();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional: Add a subtle gradient background to the entire screen.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3F3), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent, // Set app bar background to transparent
            elevation: 0,
            flexibleSpace: Container( // Add a container for the gradient
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF3F3), Color(0xFFFFFFFF)], // Your gradient colors
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            leading: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: _isDeleting
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.black,
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(20),
            child: FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.red.shade100,
                      child: Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.red.shade700,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text(
                      'Warning!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text(
                      'Deleting your account is irreversible. All your data, including your profile photo and account information, will be permanently removed.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Additional Information Card
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Data to be deleted:',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Profile photo\n• Personal information\n• Academic Attendance records\n• Optional subject data',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
                                colors: [Colors.redAccent, Colors.red],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: MaterialButton(
                              minWidth: double.infinity,
                              height: 60,
                              onPressed: _confirmDelete,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.delete_forever,
                                    size: 24,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}