import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BasicScanner extends StatefulWidget {
  const BasicScanner({super.key});

  @override
  State<BasicScanner> createState() => _BasicScannerState();
}

class _BasicScannerState extends State<BasicScanner> {
  String? scannedUrl;

  // Function to start scanning
  Future<void> startQRScan() async {
    String scanResult;
    try {
      scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // Custom color for the scan line
        'Cancel',
        true,
        ScanMode.QR,
      );
    } catch (e) {
      scanResult = 'Failed to scan QR Code.';
    }

    // Check if the scan result is a valid URL
    if (!mounted) return;
    setState(() {
      if (scanResult != '-1') {
        scannedUrl = scanResult;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startQRScan(); // Start scanning on load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'W E B V I E W',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        backgroundColor: Colors.greenAccent,
      ),

      body: scannedUrl == null
          ? const Center(child: CircularProgressIndicator())
          : WebView(
        initialUrl: scannedUrl,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
