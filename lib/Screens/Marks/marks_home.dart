import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:studysync_student/Screens/Marks/ia_marks.dart';
import 'package:studysync_student/Screens/Marks/termwork.dart';

class MarksHome extends StatefulWidget {
  final String year;
  final String sem;
  final String rollNo;
  final String batch;
  final String fullName;
  final String ay;
  final String clg;
  final String dept;

  const MarksHome({
    super.key,
    required this.year,
    required this.sem,
    required this.rollNo,
    required this.batch,
    required this.fullName,
    required this.ay,
    required this.dept,
    required this.clg,
  });

  @override
  State<MarksHome> createState() => _MarksHomeState();
}

class _MarksHomeState extends State<MarksHome> {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  " Options",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  "Please Read note given below and choose your option",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Center( // Center the RichText
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                      ),
                      children: <TextSpan>[
                        const TextSpan(
                          text: "Note:\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text: "• ",
                        ),
                        const TextSpan(
                          text: "Term Work: ", // Bold text
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text:
                          "In this section, you can enter and manage the marks obtained for each experiment. This allows you to keep track of your practical performance and ensures accurate record-keeping of your experiment evaluations.\n\n",
                        ),
                        const TextSpan(
                          text: "• ",
                        ),
                        const TextSpan(
                          text: "Internal Assessment (IA) Marks: ", // Bold text
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text:
                          "In this section, you can enter your marks for IA-1 and IA-2. Additionally, you can calculate the average of these two assessments.",
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildButton(
                context,
                "Termwork",
                [Colors.greenAccent, Colors.teal],
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentTermWork(
                      year: widget.year,
                      sem: widget.sem,
                      rollNo: widget.rollNo,
                      batch: widget.batch,
                      fullName: widget.fullName,
                      dept: widget.dept,
                      ay: widget.ay,
                      clg: widget.clg,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildButton(
                context,
                "IA Marks",
                [Colors.lightBlueAccent, Colors.blue],
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IaMarks(
                      year: widget.year,
                      sem: widget.sem,
                      rollNo: widget.rollNo,
                      batch: widget.batch,
                      fullName: widget.fullName,
                      dept: widget.dept,
                      ay: widget.ay,
                      clg: widget.clg
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

  Widget _buildButton(
      BuildContext context,
      String text,
      List<Color> gradientColors,
      VoidCallback onPressed) {
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
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: onPressed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}