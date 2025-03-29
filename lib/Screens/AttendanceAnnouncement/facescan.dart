import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Thresholds for eye status (adjust as needed).
  final double openThreshold = 0.7;
  final double closedThreshold = 0.3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((_) => _initializeCamera());
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      bool granted = await _requestCameraPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission is required.")),
        );
        return;
      }
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController =
          CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error initializing camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initializing camera: $e")),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  /// Capture a face image and return its embedding and image file.
  /// [expectOpen] determines whether to verify that eyes are open (true) or closed (false).
  Future<Map<String, dynamic>?> _captureFaceAndImage({required bool expectOpen}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      XFile capturedImage = await _cameraController!.takePicture();
      File imageFile = File(capturedImage.path);
      final inputImage = InputImage.fromFile(imageFile);
      // Enable classification for eye open probabilities.
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableLandmarks: true,
        enableClassification: true,
      );
      final faceDetector = FaceDetector(options: options);
      final faces = await faceDetector.processImage(inputImage);
      faceDetector.close();
      if (faces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No face detected. Please try again.")),
          );
        }
        return null;
      }
      Face face = faces.first;
      // Verify eye status.
      if (face.leftEyeOpenProbability == null || face.rightEyeOpenProbability == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unable to determine eye status. Please try again.")),
          );
        }
        return null;
      }
      double leftProb = face.leftEyeOpenProbability!;
      double rightProb = face.rightEyeOpenProbability!;
      if (expectOpen) {
        // For open eyes, both probabilities must be above the open threshold.
        if (leftProb < openThreshold || rightProb < openThreshold) {
          return null;
        }
      } else {
        // For closed eyes, both probabilities must be below the closed threshold.
        if (leftProb > closedThreshold || rightProb > closedThreshold) {
          return null;
        }
      }
      // Decode image.
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;
      // Align face using eye landmarks.
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      if (leftEye != null && rightEye != null) {
        int deltaX = rightEye.position.x.toInt() - leftEye.position.x.toInt();
        int deltaY = rightEye.position.y.toInt() - leftEye.position.y.toInt();
        double angle = atan2(deltaY.toDouble(), deltaX.toDouble()) * (180 / pi);
        originalImage = img.copyRotate(originalImage, angle: -angle);
      }
      // Crop the face using the bounding box.
      int x = face.boundingBox.left.toInt();
      int y = face.boundingBox.top.toInt();
      int w = face.boundingBox.width.toInt();
      int h = face.boundingBox.height.toInt();
      x = x < 0 ? 0 : x;
      y = y < 0 ? 0 : y;
      if (x + w > originalImage.width) w = originalImage.width - x;
      if (y + h > originalImage.height) h = originalImage.height - y;
      img.Image faceCrop = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
      // Run TFLite model to extract embedding.
      List<double> embedding = await _runModelOnImage(faceCrop);
      return {
        'embedding': embedding,
        'file': imageFile,
      };
    } catch (e) {
      if (mounted) {
        debugPrint("Error during face capture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error during face capture.")),
        );
      }
      return null;
    }
  }

  Future<List<double>> _runModelOnImage(img.Image faceImage) async {
    img.Image resizedImage = img.copyResize(faceImage, width: 112, height: 112);
    var input = List.generate(
      1,
          (_) => List.generate(
        112,
            (_) => List.generate(112, (_) => List.filled(3, 0.0), growable: false),
        growable: false,
      ),
      growable: false,
    );
    for (int i = 0; i < 112; i++) {
      for (int j = 0; j < 112; j++) {
        final pixel = resizedImage.getPixel(j, i);
        double r = (pixel.r.toDouble() - 127.5) / 128.0;
        double g = (pixel.g.toDouble() - 127.5) / 128.0;
        double b = (pixel.b.toDouble() - 127.5) / 128.0;
        input[0][i][j] = [r, g, b];
      }
    }
    var output = List.generate(1, (_) => List.filled(128, 0.0));
    Interpreter interpreter = await Interpreter.fromAsset('assets/facenet.tflite');
    interpreter.run(input, output);
    interpreter.close();
    return output[0];
  }

  double _calculateCosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    normA = sqrt(normA);
    normB = sqrt(normB);
    return dotProduct / (normA * normB);
  }

  Future<void> _captureAndScanFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() {
      _isProcessing = true;
    });

    // Step 1: Capture open-eyes scan.
    Map<String, dynamic>? openFaceData =
    await _captureFaceAndImage(expectOpen: true);
    if (openFaceData == null) {
      setState(() {
        _isProcessing = false;
      });
      // Show failure dialog for open eyes scan.
      if(!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false, // Prevents closing by tapping outside
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 12)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan Failure',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Face does not match. Please try again with open eyes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shadowColor: Colors.red.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    List<double> scannedOpenEmbedding = openFaceData['embedding'];

    // Retrieve stored open eyes embedding.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedOpenStr = prefs.getString('face_embedding_open');
    if (storedOpenStr == null) {
      setState(() {
        _isProcessing = false;
      });
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No registered open eyes face found.")),
      );
      return;
    }
    List<double> storedOpenEmbedding =
    storedOpenStr.split(',').map((e) => double.parse(e)).toList();

    // Compare open embeddings.
    double openSimilarity = _calculateCosineSimilarity(scannedOpenEmbedding, storedOpenEmbedding);
    const double threshold = 0.6;
    if (openSimilarity < threshold) {
      setState(() {
        _isProcessing = false;
      });
      if(!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Scan Failure"),
            content: const Text("Open eyes face does not match. Please try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Ok"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Step 2: Instruct user to close eyes.
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please close your eyes and hold steady...")),
    );
    await Future.delayed(const Duration(seconds: 1));

    // Capture closed-eyes scan.
    Map<String, dynamic>? closedFaceData =
    await _captureFaceAndImage(expectOpen: false);
    if (closedFaceData == null) {
      setState(() {
        _isProcessing = false;
      });
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Closed eyes face does not match. Scan failed.")),
      );
      return;
    }
    List<double> scannedClosedEmbedding = closedFaceData['embedding'];

    // Retrieve stored closed eyes embedding.
    String? storedClosedStr = prefs.getString('face_embedding_closed');
    if (storedClosedStr == null) {
      setState(() {
        _isProcessing = false;
      });
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No registered closed eyes face found.")),
      );
      return;
    }
    List<double> storedClosedEmbedding =
    storedClosedStr.split(',').map((e) => double.parse(e)).toList();

    // Compare closed embeddings.
    double closedSimilarity =
    _calculateCosineSimilarity(scannedClosedEmbedding, storedClosedEmbedding);
    if (closedSimilarity < threshold) {
      setState(() {
        _isProcessing = false;
      });
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Closed eyes face does not match. Scan failed.")),
      );
      return;
    }

    // Both open and closed eyes embeddings matched.
    setState(() {
      _isProcessing = false;
    });
    // Instead of popping the screen, call your attendance function.
    File openEyesImage = openFaceData['file'];
    if(!mounted) return;
    Navigator.of(context).pop(openEyesImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: const Text(
            'F A C E   S C A N',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
              Colors.white,
              Colors.green.shade100,
            ],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isCameraInitialized
              ? Column(
            children: [
              Expanded(
                child: FadeIn(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Transform.scale(
                        scaleX: -1.0,
                        child: AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _isProcessing
                        ? const CircularProgressIndicator(color: Colors.black,)
                        : FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(50),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.greenAccent, Colors.teal],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: MaterialButton(
                                minWidth: double.infinity,
                                height: 60,
                                onPressed: _captureAndScanFace,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: EdgeInsets.zero,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.face_retouching_natural_rounded,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Scan Face',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          )
              : const Center(child: CircularProgressIndicator(color: Colors.black,)),
        ),
      ),
    );
  }
}
