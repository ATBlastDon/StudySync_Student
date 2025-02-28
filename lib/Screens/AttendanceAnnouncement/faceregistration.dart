import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _faceEmbeddingStr;
  bool _alreadyRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRegistration();
    // Lock orientation to portrait.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((_) => _initializeCamera());
  }

  Future<void> _checkExistingRegistration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('face_embedding')) {
      setState(() {
        _faceEmbeddingStr = prefs.getString('face_embedding');
        _alreadyRegistered = true;
      });
    }
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
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Lock the capture orientation to portrait.
      await _cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initializing camera: $e")),
      );
    }
  }

  @override
  void dispose() {
    // Restore orientation preferences when leaving this screen.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _cameraController?.dispose();
    super.dispose();
  }

  /// Calculate the number of quarter turns needed for the preview
  int _getQuarterTurns() {
    // Use the sensorOrientation provided by the camera's description.
    // Many front cameras report 270° (which is equivalent to 3 quarter turns)
    // Adjust this logic based on your testing.
    if (_cameraController != null) {
      final sensorOrientation = _cameraController!.description.sensorOrientation;
      // For a sensorOrientation of 90 degrees, rotate 1 quarter turn.
      // For 270 degrees, rotate 3 quarter turns.
      if (sensorOrientation == 90) {
        return 1;
      } else if (sensorOrientation == 270) {
        return 3;
      }
    }
    return 0;
  }

  Future<void> _captureAndRegisterFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Capture image from camera.
      XFile capturedImage = await _cameraController!.takePicture();
      File imageFile = File(capturedImage.path);

      // Prepare the image for face detection.
      final inputImage = InputImage.fromFile(imageFile);
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableLandmarks: true, // Enable landmarks for alignment.
      );
      final faceDetector = FaceDetector(options: options);
      final faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      if (faces.isEmpty) {
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

      // Extract face embedding using the TFLite model.
      List<double> embedding = await _runModelOnImage(faceCrop);

      // Save the embedding locally.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String embeddingStr = embedding.join(',');
      await prefs.setString('face_embedding', embeddingStr);

      setState(() {
        _faceEmbeddingStr = embeddingStr;
        _alreadyRegistered = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Face registered successfully!")),
      );
    } catch (e) {
      debugPrint("Error during face registration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error during face registration.")),
      );
    }
  }

  /// Preprocesses the face image, normalizing pixel values between -1 and 1.
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Delete Face Data",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Are you sure you want to delete the registered face data? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElasticIn(
                duration: const Duration(milliseconds: 500),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteFaceEmbedding();
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteFaceEmbedding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('face_embedding');
    setState(() {
      _faceEmbeddingStr = null;
      _alreadyRegistered = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Face embedding deleted.")),
    );
  }

  void _copyEmbeddingToClipboard() {
    if (_faceEmbeddingStr == null) return;
    Clipboard.setData(ClipboardData(text: _faceEmbeddingStr!)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Embedding copied to clipboard!"),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: Text(
            _alreadyRegistered ? 'F A C E   A V A I L A B L E' : 'R E G I S T R A T I O N',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          if (_alreadyRegistered)
            ElasticIn(
              duration: const Duration(milliseconds: 800),
              child: IconButton(
                icon: const Icon(Icons.delete_rounded),
                onPressed: _showDeleteDialog,
              ),
            ),
        ],
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
          child: _alreadyRegistered
              ? _buildProfileSection()
              : _buildRegistrationSection(),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: FadeInUpBig(
        duration: const Duration(milliseconds: 800),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeIn(
                duration: const Duration(milliseconds: 800),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              SlideInLeft(
                duration: const Duration(milliseconds: 800),
                child: const Text(
                  "Face Registered!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _faceEmbeddingStr ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SlideInRight(
                        duration: const Duration(milliseconds: 800),
                        child: IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: _copyEmbeddingToClipboard,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return Column(
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
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isCameraInitialized
                    ? Transform.scale( // Add Transform.scale here
                  scaleX: -1.0, // Mirror horizontally
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: RotatedBox(
                      quarterTurns: _getQuarterTurns(),
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                )
                    : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
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
              if (_faceEmbeddingStr != null)
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      "Face scan completed!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FadeInUp(
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
                          onPressed: _captureAndRegisterFace,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.face_retouching_natural_rounded,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Register Face',
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
    );
  }
}
