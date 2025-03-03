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

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait.
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
      _cameraController = CameraController(
          frontCamera, ResolutionPreset.medium,
          enableAudio: false);
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
    // Restore orientation preferences if needed.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }


  Future<void> _captureAndScanFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image from the camera.
      XFile capturedImage = await _cameraController!.takePicture();
      File imageFile = File(capturedImage.path);

      // Prepare image for face detection.
      final inputImage = InputImage.fromFile(imageFile);
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableLandmarks: true,
      );
      final faceDetector = FaceDetector(options: options);
      final faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      if (faces.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No face detected. Please try again.")),
        );
        return;
      }

      Face face = faces.first;

      // Decode image using the image package.
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Align the face using eye landmarks.
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      if (leftEye != null && rightEye != null) {
        int deltaX = rightEye.position.x.toInt() - leftEye.position.x.toInt();
        int deltaY = rightEye.position.y.toInt() - leftEye.position.y.toInt();
        double angle = atan2(deltaY.toDouble(), deltaX.toDouble()) * (180 / pi);
        originalImage = img.copyRotate(originalImage, angle: -angle);
      }

      // Crop the face using the detected bounding box.
      int x = face.boundingBox.left.toInt();
      int y = face.boundingBox.top.toInt();
      int w = face.boundingBox.width.toInt();
      int h = face.boundingBox.height.toInt();
      x = x < 0 ? 0 : x;
      y = y < 0 ? 0 : y;
      if (x + w > originalImage.width) w = originalImage.width - x;
      if (y + h > originalImage.height) h = originalImage.height - y;
      img.Image faceCrop = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);

      // Extract embedding from the face crop.
      List<double> currentEmbedding = await _runModelOnImage(faceCrop);

      // Retrieve stored face embedding.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedEmbeddingStr = prefs.getString('face_embedding');
      if (storedEmbeddingStr == null) {
        setState(() {
          _isProcessing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No registered face found.")),
        );
        return;
      }
      List<double> storedEmbedding =
      storedEmbeddingStr.split(',').map((e) => double.parse(e)).toList();

      // Compare embeddings using cosine similarity.
      double similarity = _calculateCosineSimilarity(currentEmbedding, storedEmbedding);
      const double threshold = 0.6; // Adjust threshold as needed.
      if (similarity < threshold) {
        setState(() {
          _isProcessing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face does not match. Please try again.")),
        );
        return;
      }

      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      Navigator.of(context).pop(imageFile);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint("Error during face scanning: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error during face scanning. Please try again.")),
      );
    }
  }

  /// Preprocesses the face image and returns the embedding.
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
                      // Mirror preview if needed.
                      child: Transform.scale(
                        scaleX: -1.0,
                        // Use FittedBox to fill the container in portrait mode.
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize!.height,
                            height: _cameraController!.value.previewSize!.width,
                            child: CameraPreview(_cameraController!),
                          ),
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
                        ? const CircularProgressIndicator()
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
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
