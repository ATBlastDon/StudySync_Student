import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:studysync_student/Screens/AttendanceAnnouncement/giveattendance.dart';

class Passwordscanner extends StatefulWidget {
  final String subjectName;
  final String type;
  final String batch;
  final String rollNo;
  final String year;
  final String sem;
  final String pass;
  final String created;
  final String optionalSubject;
  final String fullName;


  const Passwordscanner({
    super.key,
    required this.subjectName,
    required this.type,
    required this.batch,
    required this.rollNo,
    required this.year,
    required this.sem,
    required this.pass,
    required this.created,
    required this.optionalSubject,
    required this.fullName,

  });

  @override
  State<Passwordscanner> createState() => _PasswordscannerState();
}

class _PasswordscannerState extends State<Passwordscanner> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'S C A N   Q R',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 50),
              const Text(
                "Scan The QR Code",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              Text.rich(
                const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: "Note: ", // Make "Note:" bold
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Or keep it grey if you prefer
                      ),
                    ),
                    TextSpan(
                      text:
                      "If You Scanned Correct QR Code you will be forwarded to Next Submitting activity",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 70),
              Padding(
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
                        onPressed: () {
                          _checkPermissionAndStartScanner(context);
                        },
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          "Scan",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black, // Ensures contrast and readability
                          ),
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
    );
  }

  void _checkPermissionAndStartScanner(BuildContext context) async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      // Ask for camera permission if not granted
      status = await Permission.camera.request();
    }
    if (status.isGranted) {
      if (context.mounted) {
        _startQRCodeScanner(context);
      }
    } else {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
    }
  }

  void _startQRCodeScanner(BuildContext context) async {
    String scannedValue = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666", // The line color
      "Cancel",  // The text for the cancel button
      true,      // Whether to show the flash button
      ScanMode.QR, // Mode (can be QR or barcode)
    );

    if (scannedValue != "-1") {
      // Decrypt the scanned QR code data
      String decryptedPassword = _customDecrypt(scannedValue);

      // Check if the decrypted password matches the stored password
      if (decryptedPassword == widget.pass) {
        if (context.mounted){
          _showSuccessDialog(context);
        }
      } else {
        if(context.mounted){
          _showFailureDialog(context);
        }
      }
    }
  }

  // Decryption function using XOR
  String _customDecrypt(String encryptedData) {
    String decryptionKey = "AAAWEWEWWEERTYUI";
    List<int> encryptedChars = encryptedData.codeUnits;
    List<int> keyChars = decryptionKey.codeUnits;
    List<int> decryptedChars = List.filled(encryptedChars.length, 0);

    for (int i = 0; i < encryptedChars.length; i++) {
      decryptedChars[i] = encryptedChars[i] ^ keyChars[i % keyChars.length];
    }

    return String.fromCharCodes(decryptedChars);
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success", style: TextStyle(fontFamily: "Outfit")),
          content: const Text("Password is matched!", style: TextStyle(fontFamily: "Outfit")),
          actions: [
            TextButton(
              child: const Text("Next", style: TextStyle(fontFamily: "Outfit")),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GiveAttendance(
                      subjectName: widget.subjectName,
                      type: widget.type,
                      batch: widget.batch,
                      rollNo: widget.rollNo,
                      optionalSubject: widget.optionalSubject,
                      year: widget.year,
                      sem: widget.sem,
                      created: widget.created,
                      fullName: widget.fullName,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showFailureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Failed", style: TextStyle(fontFamily: "Outfit")),
          content: const Text("Password does not match.", style: TextStyle(fontFamily: "Outfit")),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(fontFamily: "Outfit")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Permission Denied", style: TextStyle(fontFamily: "Outfit")),
          content: const Text("Camera permission is required to scan QR codes. Please enable it in the system settings.", style: TextStyle(fontFamily: "Outfit")),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(fontFamily: "Outfit")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
