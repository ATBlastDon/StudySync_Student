import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysync_student/Screens/Security/change_password.dart';
import 'package:studysync_student/Screens/Security/delete_account.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final String year; // For example: BE, TE, or SE
  final String rollNo;
  final String sem;
  final String ay;
  final String dept;

  const PrivacySettingsScreen({super.key,
    required this.year,
    required this.rollNo,
    required this.sem,
    required this.ay,
    required this.dept
  });

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isFingerprintEnabled = false; // Initially set to false

  @override
  void initState() {
    super.initState();
    _loadFingerprintPreference();
  }

  Future<void> _loadFingerprintPreference() async {
    // Load user's fingerprint preference from storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFingerprintEnabled = prefs.getBool('isFingerprintEnabled') ?? false;
    });
  }

  Future<void> _saveFingerprintPreference(bool value) async {
    // Save user's fingerprint preference to storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFingerprintEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'S E C U R I T Y',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
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
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10,),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: SwitchListTile(
              title: const Text(
                'Enable Fingerprint Unlocking',
                style: TextStyle(fontFamily: "Outfit", fontSize: 16),
              ),
              subtitle: const Text(
                'Secure your app with your Fingerprint',
                style: TextStyle(fontFamily: "Outfit", fontSize: 16),
              ),
              value: _isFingerprintEnabled,
              onChanged: (value) {
                _toggleFingerprintLock(value);
              },
              secondary: const Icon(Icons.fingerprint),
            ),
          ),
          const Divider(),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: ListTile(
              leading: const Icon(Icons.lock, color: Colors.black),
              title: const Text(
                'Change Password',
                style: TextStyle(fontFamily: "Outfit", fontSize: 16),
              ),
              subtitle: const Text(
                'Change your Account Password',
                style: TextStyle(fontFamily: "Outfit", fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePassword(),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_sharp, color: Colors.black),
              title: const Text(
                'Delete Account',
                style: TextStyle(fontFamily: "Outfit", fontSize: 16),
              ),
              subtitle: const Text(
                'Delete your Account Permanently',
                style: TextStyle(fontFamily: "Outfit", fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeleteAccount(
                      year: widget.year,
                      sem: widget.sem,
                      rollNo: widget.rollNo,
                      dept: widget.dept,
                      ay: widget.ay,

                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _toggleFingerprintLock(bool newValue) async {
    final LocalAuthentication localAuth = LocalAuthentication();
    bool canCheckBiometrics = await localAuth.canCheckBiometrics;

    if (canCheckBiometrics) {
      if (newValue) {
        // Enable fingerprint unlocking
        bool authenticated = await localAuth.authenticate(
          localizedReason: 'Scan your fingerprint to enable unlocking',
        );

        if (authenticated) {
          setState(() {
            _isFingerprintEnabled = true;
          });
          _saveFingerprintPreference(true);
        } else {
          // User authentication failed, revert the switch state
          setState(() {
            _isFingerprintEnabled = false;
          });
          _saveFingerprintPreference(false);
        }
      } else {
        // Disable fingerprint unlocking
        setState(() {
          _isFingerprintEnabled = false;
        });
        _saveFingerprintPreference(false);
      }
    } else {
      // Biometric authentication is not available on this device
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Biometric authentication not available'),
          content: const Text('Your device does not support biometric authentication.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
