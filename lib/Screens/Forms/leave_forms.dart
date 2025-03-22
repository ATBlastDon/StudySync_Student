import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LeaveForms extends StatefulWidget {
  final String year;
  final String sem;
  final String rollNo;
  final String name;
  final String mentor;
  final String ay;
  final String dept;

  const LeaveForms({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.name,
    required this.mentor,
    required this.ay,
    required this.dept,

  });

  @override
  State<LeaveForms> createState() => _LeaveFormsState();
}

class _LeaveFormsState extends State<LeaveForms> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Date picker methods
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate.isAfter(_selectedStartDate)
          ? _selectedEndDate
          : _selectedStartDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _selectImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('leave_forms/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(image);
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return "";
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      String documentId =
          FirebaseFirestore.instance.collection('leave_forms').doc().id;
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }
      try {
        await FirebaseFirestore.instance
            .collection('leave_forms')
            .doc(widget.dept)
            .collection(widget.ay)
            .doc(widget.year)
            .collection(widget.sem)
            .doc('forms')
            .collection('details')
            .doc(documentId)
            .set({
          'fullName': widget.name,
          'rollNo': widget.rollNo,
          'year': widget.year,
          'semester': widget.sem,
          'mentor': widget.mentor,
          'reason': _reasonController.text,
          'startDate': DateFormat('dd/MM/yy').format(_selectedStartDate),
          'endDate': DateFormat('dd/MM/yy').format(_selectedEndDate),
          'submittedAt': DateTime.now(),
          'status': 'pending',
          'documentId': documentId,
          'imageUrl': imageUrl,
        });

        _reasonController.clear();
        setState(() {
          _selectedImage = null;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Leave request submitted successfully!'),
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error submitting leave request'),
        ));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showNoticeDialogue() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          title: Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'Tip',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    color: Colors.black, fontFamily: 'Outfit', fontSize: 16),
                children: <TextSpan>[
                  TextSpan(
                    text: "Reason for Leave: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "Provide a clear and concise reason for your leave application.\n\n",
                  ),
                  TextSpan(
                    text: "From/To Date: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "Select the start and end dates for your leave period. Ensure the 'To' date is after the 'From' date.\n\n",
                  ),
                  TextSpan(
                    text: "Upload Image (optional): ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "You can optionally upload a supporting document or medical certificate.\n\n",
                  ),
                  TextSpan(
                    text: "Submit: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "Click the 'Submit' button to send your leave application. You will see a confirmation message upon successful submission.",
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: 'Outfit',
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showFullImage() {
    if (_selectedImage != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }
  }


  Widget _buildHeaderSection() {
    return FadeInDown(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "${widget.rollNo} - ${widget.name}",
              style: const TextStyle(
                fontSize: 24,
                fontFamily: "Outfit",
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectors() {
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // "From Date" selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "From Date",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Outfit",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectStartDate,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFC8D7E4), width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Color(0xFF384E58)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yy').format(_selectedStartDate),
                            style: const TextStyle(fontFamily:"Outfit", fontSize: 14, color: Color(0xFF384E58)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // "To Date" selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "To Date",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Outfit",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: _selectEndDate,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFC8D7E4), width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Color(0xFF384E58)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yy').format(_selectedEndDate),
                            style: const TextStyle(fontFamily:"Outfit",fontSize: 14, color: Color(0xFF384E58)),
                          ),
                        ],
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

  Widget _buildReasonSection() {
    return FadeInLeft(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reason",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Outfit",
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: _reasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Enter your leave reason",
                hintStyle: const TextStyle(fontFamily: "Outfit"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a reason';
                }
                return null;
              },
            ),
            const SizedBox(height: 5),
            const Text(
              "Please provide a detailed explanation for your leave request.",
              style: TextStyle(fontSize: 12, fontFamily: "Outfit"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return FadeInRight(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: InkWell(
          onTap: _selectedImage == null ? _selectImage : _showFullImage,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.image_outlined, size: 44, color: Color(0xFF4B986C)),
                const SizedBox(height: 5),
                const Text(
                  "Upload Supporting Image",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Outfit",
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Tap to select a file",
                  style: TextStyle(fontSize: 12, fontFamily: "Outfit"),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _selectImage,
                    child: const Text("Change Image", style: TextStyle(fontFamily: "Outfit", color: Colors.black)),
                  ),                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FadeInUp(
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
                onPressed: _submit,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 60,
                  child: const Text(
                    'Submit',
                    style: TextStyle(
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
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'L E A V E   F O R M',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.grey[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: _showNoticeDialogue,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 10),
                  _buildDateSelectors(),
                  const SizedBox(height: 10),
                  _buildReasonSection(),
                  const SizedBox(height: 15),
                  _buildImagePickerSection(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
