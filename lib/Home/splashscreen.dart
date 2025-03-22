import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysync_student/Home/homepage.dart';
import 'package:studysync_student/Screens/StudentHome/studentinternal.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showSplash = true;
  String year = ""; // Define year here with a default value
  String sem = "";
  String dept = "";
  String ay = "";

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      year = prefs.getString('year') ?? ""; // Retrieve year, default to "BE"
      sem = prefs.getString('sem') ?? "";
      dept = prefs.getString('dept') ?? "";
      ay = prefs.getString('ay') ?? "";

      // User is already logged in, navigate to StudentInternal screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentInternal(year: year, sem: sem, dept: dept, ay: ay),
        ),
      );
    } else {
      // User is not logged in, show the splash screen
      setState(() {
        _showSplash = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Lottie.asset(
              "assets/background/Animation.json",
              width: 350,
              height: 350,
            ),
          )
        ],
      ),
      nextScreen: const HomePage(),
      splashIconSize: 400,
      backgroundColor: Colors.white,
    )
        : const HomePage();
  }
}
