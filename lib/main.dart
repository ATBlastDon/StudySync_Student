import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:studysync_student/AboutUs/aboutteam.dart';
import 'package:studysync_student/Home/opening.dart';
import 'package:studysync_student/Screens/Authentication/studentlogin.dart';
import 'package:studysync_student/Screens/Authentication/studentregister.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated Firebase options
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set debugShowCheckedModeBanner to false
      initialRoute: '/',
      routes: {
        '/': (context) => const OpeningScreen(),
        '/login': (context) => const StudentLogin(),
        '/register': (context) => const StudentRegister(),
        '/about': (context) => const AboutTeam(),
      },
    );
  }
}
