import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:studysync_student/Screens/AttendanceAnnouncement/facescan.dart';
import 'package:studysync_student/Screens/StudentHome/studentinternal.dart';

class GiveAttendance extends StatefulWidget {
  final String subjectName;
  final String type;
  final String batch;
  final String rollNo;
  final String year;
  final String sem;
  final String created;
  final String optionalSubject;
  final String fullName;

  const GiveAttendance({
    super.key,
    required this.subjectName,
    required this.type,
    required this.batch,
    required this.rollNo,
    required this.year,
    required this.sem,
    required this.created,
    required this.optionalSubject,
    required this.fullName,
  });

  @override
  State<GiveAttendance> createState() => _GiveAttendanceState();
}

class _GiveAttendanceState extends State<GiveAttendance> {
  bool _isUploading = false;

  Future<void> _captureImage() async {
    // Navigate to the face scanning screen.
    final File? imageFile = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceScanScreen()),
    );

    if (imageFile != null) {
      // Compress the captured image.
      img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage == null) return;

      img.Image resizedImage = img.copyResize(originalImage, width: 800);
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      File compressedImageFile = await imageFile.writeAsBytes(compressedBytes);

      _showDetailsPopup(compressedImageFile);
    }
  }

  Future<void> _showDetailsPopup(File compressedImageFile) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              "Attendance Details",
              style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Class: ${widget.year}", style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Colors.black)),
              Text(
                "Subject Name: ${widget.optionalSubject != 'N/A' && widget.optionalSubject.isNotEmpty ? widget.optionalSubject : widget.subjectName}",
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Colors.black),
              ),
              Text("Type: ${widget.type}", style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Colors.black)),
              Text("Batch: ${widget.batch}", style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Colors.black)),
              Text("Roll No: ${widget.rollNo}", style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: Colors.black)),
              const SizedBox(height: 15),
              Image.file(compressedImageFile),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close', style: TextStyle(fontFamily: "Outfit", fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit', style: TextStyle(fontFamily: "Outfit", fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).pop();
                _uploadAttendance(compressedImageFile);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadAttendance(File compressedImageFile) async {
    setState(() {
      _isUploading = true;
    });
    try {
      DocumentReference attendanceDocRef;
      if (widget.subjectName.startsWith('DLOC') || widget.subjectName.startsWith('ILOC')) {
        attendanceDocRef = FirebaseFirestore.instance
            .collection('attendance_record')
            .doc(widget.year)
            .collection(widget.sem)
            .doc(widget.subjectName)
            .collection(widget.optionalSubject)
            .doc(widget.type)
            .collection('lecture')
            .doc(widget.created)
            .collection('rollNumbers')
            .doc(widget.rollNo);
      } else {
        attendanceDocRef = FirebaseFirestore.instance
            .collection('attendance_record')
            .doc(widget.year)
            .collection(widget.sem)
            .doc(widget.subjectName)
            .collection(widget.type)
            .doc(widget.created)
            .collection('rollNumbers')
            .doc(widget.rollNo);
      }

      var existingDoc = await attendanceDocRef.get();
      if (existingDoc.exists) {
        setState(() {
          _isUploading = false;
        });
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance is already marked for this roll number.', style: TextStyle(fontFamily: "Outfit"))),
        );
        return;
      }

      String filePath;
      if (widget.subjectName.startsWith('DLOC') || widget.subjectName.startsWith('ILOC')) {
        if (widget.optionalSubject != 'N/A') {
          filePath = 'attendance_record/${widget.year}/${widget.sem}/${widget.subjectName}/${widget.optionalSubject}/${widget.type}/${widget.created}/${widget.rollNo}/attendance.jpg';
        } else {
          filePath = 'attendance_record/${widget.year}/${widget.sem}/${widget.subjectName}/${widget.type}/${widget.created}/${widget.rollNo}/attendance.jpg';
        }
      } else {
        filePath = 'attendance_record/${widget.year}/${widget.sem}/${widget.subjectName}/${widget.type}/${widget.created}/${widget.rollNo}/attendance.jpg';
      }

      await FirebaseStorage.instance.ref(filePath).putFile(compressedImageFile);
      String downloadUrl = await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      CollectionReference attendanceCollection;
      if (widget.subjectName.startsWith('DLOC') || widget.subjectName.startsWith('ILOC')) {
        attendanceCollection = FirebaseFirestore.instance
            .collection('attendance_record')
            .doc(widget.year)
            .collection(widget.sem)
            .doc(widget.subjectName)
            .collection(widget.optionalSubject)
            .doc(widget.type)
            .collection('lecture')
            .doc(widget.created)
            .collection('rollNumbers');
      } else {
        attendanceCollection = FirebaseFirestore.instance
            .collection('attendance_record')
            .doc(widget.year)
            .collection(widget.sem)
            .doc(widget.subjectName)
            .collection(widget.type)
            .doc(widget.created)
            .collection('rollNumbers');
      }

      await attendanceCollection.doc(widget.rollNo).set({
        'class': widget.year,
        'semester': widget.sem,
        'subject': widget.subjectName,
        'optional_sub': widget.optionalSubject,
        'type': widget.type,
        'batch': widget.batch,
        'rollNo': widget.rollNo,
        'imageUrl': downloadUrl,
        'approvalStatus': 'pending',
        'fullName': widget.fullName,
      });

      setState(() {
        _isUploading = false;
      });
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit attendance. Please check your internet connection.', style: TextStyle(fontFamily: "Outfit"))),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success!", style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
              SizedBox(width: 10),
              Expanded(child: Text("Attendance submitted successfully!", style: TextStyle(fontFamily: 'Outfit', fontSize: 16, color: Colors.black))),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ok', style: TextStyle(fontFamily: "Outfit", fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentInternal(year: widget.year, sem: widget.sem)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text('G I V E   A T T E N D A N C E', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.greenAccent, Colors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        backgroundColor: Colors.grey[100],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text("Face Recognition!!!", style: TextStyle(fontFamily: 'Outfit', fontSize: 30, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Center(
                      child: Text.rich(
                        const TextSpan(
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 16),
                          children: <TextSpan>[
                            TextSpan(text: "NOTE:-\n", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
                            TextSpan(text: "Tapping the button will start the face scanning algorithm to verify your identity. Once your face is matched, your photo will be captured automatically for attendance submission."),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        padding: const EdgeInsets.only(top: 3, left: 3),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.black)),
                        child: Material(
                          borderRadius: BorderRadius.circular(50),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: MaterialButton(
                              minWidth: double.infinity,
                              height: 60,
                              onPressed: _captureImage,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              child: const Text("Start", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        ],
      ),
    );
  }
}
