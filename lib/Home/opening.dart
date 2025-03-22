import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:studysync_student/Home/splashscreen.dart';
import 'package:studysync_student/Screens/StudentHome/studentinternal.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  bool _isFingerprintEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLoggedInAndFingerprint();
  }

  Future<void> _checkLoggedInAndFingerprint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) {
      // User is not logged in, go to SplashScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    } else {
      // User is logged in, check fingerprint status
      await _checkFingerprintStatus();
    }
  }

  Future<void> _checkFingerprintStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = prefs.getBool('isFingerprintEnabled') ?? false;

    if (_isFingerprintEnabled) {
      // Fingerprint is enabled, authenticate user
      await _authenticateUserWithFingerprint();
    } else {
      // Fingerprint is not enabled, go to StudentInternal directly
      _goToStudentInternal();
    }
  }

  Future<void> _authenticateUserWithFingerprint() async {
    final LocalAuthentication localAuth = LocalAuthentication();
    bool canCheckBiometrics = await localAuth.canCheckBiometrics;

    if (canCheckBiometrics) {
      bool authenticated = false;
      try {
        authenticated = await localAuth.authenticate(
          localizedReason: 'Scan your fingerprint to proceed',
        );
      } on PlatformException catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.message}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      if (authenticated) {
        _goToStudentInternal();
      } else {
        // Fingerprint authentication failed, close the app
        SystemNavigator.pop();
      }
    } else {
      // Biometric authentication is not available on this device
      Fluttertoast.showToast(
        msg: 'Biometric authentication not available',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // Close the app
      SystemNavigator.pop();
    }
  }

  void _goToStudentInternal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String year = prefs.getString("year") ?? '';
    String sem = prefs.getString("sem") ?? '';
    String dept = prefs.getString("dept") ?? '';
    String ay = prefs.getString("ay") ?? '';

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentInternal(year: year, sem: sem, dept: dept, ay: ay)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // You can show a loading indicator or any other UI here if needed
    return Container(); // Optionally, return a loading indicator or splash screen
  }
}
