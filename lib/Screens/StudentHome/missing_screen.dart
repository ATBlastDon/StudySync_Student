import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studysync_student/Screens/StudentHome/studentinternal.dart';
import 'package:studysync_student/Screens/StudentHome/studentprofile.dart';
import 'package:studysync_student/Screens/Lecture/dloc.dart';

class MissingRequirementsScreen extends StatefulWidget {
  final String year;
  final String sem;
  final String rollNo;
  final String batch;
  final String dept;
  final String ay;
  final String studentEmail;
  final VoidCallback? onRequirementsUpdated;
  final List<String> missingRequirements;

  const MissingRequirementsScreen({
    super.key,
    required this.missingRequirements,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.batch,
    required this.studentEmail,
    this.onRequirementsUpdated,
    required this.dept,
    required this.ay,
  });

  @override
  State<MissingRequirementsScreen> createState() =>
      _MissingRequirementsScreenState();
}

class _MissingRequirementsScreenState extends State<MissingRequirementsScreen> {
  final Color _pageColor = const Color(0xFFF5F5F5);
  final Color _accentColor = const Color(0xFF00C9A7);
  final Color _darkColor = const Color(0xFF0F4C75);
  final Color _successColor = const Color(0xFF4CAF50);

  /// This list is recalculated based on Firestore data.
  List<String> _remainingRequirements = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _remainingRequirements = List.from(widget.missingRequirements);
    // Initially refresh missing requirements.
    _refreshMissingRequirements();
    // Refresh missing requirements periodically every 5 seconds.
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) => _refreshMissingRequirements());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Fetch the student's document from Firestore and calculate which requirements are still missing.
  Future<void> _refreshMissingRequirements() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.dept)
          .collection(widget.ay)
          .doc(widget.year)
          .collection(widget.sem)
          .doc(widget.rollNo)
          .get();

      List<String> missingReq = [];
      if (doc.exists) {
        final data = doc.data()!;
        // Check batch robustly.
        if (data['batch'] == null ||
            data['batch'].toString().trim().isEmpty ||
            data['batch'] == "none") {
          missingReq.add('batch');
        }
        // Check mentor robustly.
        if (data['mentor'] == null ||
            data['mentor'].toString().trim().isEmpty ||
            data['mentor'] == "none") {
          missingReq.add('mentor');
        }
        // For non-SE years, check if optional subjects (dloc) are filled.
        if (widget.year != "SE") {
          bool hasDloc = await _checkOptionalSubjects(widget.dept, widget.ay, widget.year, widget.sem, widget.rollNo);
          if (!hasDloc) missingReq.add('dloc');
        }
      }
      setState(() {
        _remainingRequirements = missingReq;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error refreshing requirements: $e");
    }
  }

  /// Checks if the optional_subjects collection exists by querying for any document.
  Future<bool> _checkOptionalSubjects(String dept, String ay, String year, String sem, String rollNo) async {
    try {
      final collectionPath = 'students/$dept/$ay/$year/$sem/$rollNo/optional_subjects';
      final querySnapshot =
      await FirebaseFirestore.instance.collection(collectionPath).limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      Fluttertoast.showToast(msg: "$e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'Profile Completion',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 2.0,
            ),
          ),
        ),
        elevation: 10,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          _buildModernProgressHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: _remainingRequirements.isEmpty
                    ? _buildCompletionCelebration(key: const ValueKey("complete"))
                    : _buildModernTaskGrid(key: const ValueKey("grid")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProgressHeader() {
    final totalTasks = _remainingRequirements.length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlideInLeft(
            child: Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _darkColor,
                fontFamily: 'Outfit',
              ),
            ),
          ),
          const SizedBox(height: 15),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: CircularProgressIndicator(
                    value: (3 - totalTasks) / 3,
                    strokeWidth: 10,
                    backgroundColor: _pageColor,
                    color: Colors.black,
                    valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                  ),
                ),
                Text(
                  '${3 - totalTasks}/3',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkColor,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FadeIn(
            child: Text(
              totalTasks > 0
                  ? 'Just a few more steps to go!'
                  : 'All tasks completed! 🎉',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTaskGrid({Key? key}) {
    return GridView.count(
      key: key,
      crossAxisCount: 2,
      childAspectRatio: 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: List.generate(
        _remainingRequirements.length,
            (index) => _buildModernTaskCard(_remainingRequirements[index], index),
      ),
    );
  }

  /// When all missing tasks are complete, show the celebration UI.
  /// The Get Started button now simply pops this screen.
  Widget _buildCompletionCelebration({Key? key}) {
    return ZoomIn(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Profile Complete!',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24,
              color: _darkColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You’re all set to explore StudySync’s full features!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElasticIn(
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.black,
              ),
              label: const Text(
                'Get Started',
                style: TextStyle(
                    fontFamily: "Outfit", fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentInternal(
                      year: widget.year,
                      sem: widget.sem,
                      dept: widget.dept,
                      ay: widget.ay,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color get _progressColor {
    final totalTasks = _remainingRequirements.length;
    return totalTasks == 0 ? _successColor : _accentColor;
  }

  Color get _taskCardColor => Colors.white;

  Widget _buildModernTaskCard(String requirement, int index) {
    final requirementData = _getRequirementData(requirement);

    return SlideInUp(
      delay: Duration(milliseconds: 200 * index),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _taskCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _handleFixRequirement(requirement),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          requirementData.icon,
                          color: _darkColor,
                          size: 20,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    requirementData.title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    requirementData.description,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tap to complete →',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8,
                            color: _accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  RequirementData _getRequirementData(String requirement) {
    switch (requirement) {
      case 'batch':
        return RequirementData(
            Icons.group,
            'Batch Information',
            'Please set your academic batch to access class-specific features');
      case 'mentor':
        return RequirementData(
            Icons.school,
            'Mentor Assignment',
            'Select your faculty mentor for academic guidance');
      case 'dloc':
        return RequirementData(
            Icons.menu_book,
            'Optional Subjects',
            'Choose your department-level optional courses');
      default:
        return RequirementData(Icons.error, 'Unknown Requirement', '');
    }
  }

  Future<bool> _navigateToRequirementScreen(String requirement) async {
    switch (requirement) {
      case 'batch':
      case 'mentor':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentProfile(
              studentmail: widget.studentEmail,
              studentyear: widget.year,
              sem: widget.sem,
              dept: widget.dept,
              ay: widget.ay,
            ),
          ),
        );
        return true;
      case 'dloc':
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => SelectionSubjects(
              year: widget.year,
              sem: widget.sem,
              rollNo: widget.rollNo,
              batch: widget.batch,
              dept: widget.dept,
              ay: widget.ay,
            ),
          ),
        );
        return result ?? false;
      default:
        return false;
    }
  }

  void _handleFixRequirement(String requirement) async {
    final result = await _navigateToRequirementScreen(requirement);
    if (result == true && mounted) {
      widget.onRequirementsUpdated?.call();
    }
  }
}

class RequirementData {
  final IconData icon;
  final String title;
  final String description;

  RequirementData(this.icon, this.title, this.description);
}
