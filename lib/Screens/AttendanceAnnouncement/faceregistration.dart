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
  String? _faceEmbeddingOpenStr;
  String? _faceEmbeddingClosedStr;
  bool _alreadyRegistered = false;

  // Thresholds for eye open classification.
  final double openThreshold = 0.7;
  final double closedThreshold = 0.3;

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
    if (prefs.containsKey('face_embedding_open') &&
        prefs.containsKey('face_embedding_closed')) {
      setState(() {
        _faceEmbeddingOpenStr = prefs.getString('face_embedding_open');
        _faceEmbeddingClosedStr = prefs.getString('face_embedding_closed');
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
          const SnackBar(
            content: Text(
              "Camera permission is required.",
              style: TextStyle(fontFamily: "Outfit"),
            ),
          ),
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
        SnackBar(
          content: Text("Error initializing camera: $e", style: TextStyle(fontFamily: "Outfit")),
        ),
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

  /// Capture a face image and return its embedding.
  ///
  /// The [expectOpen] parameter specifies whether to validate that the face has open eyes (true)
  /// or closed eyes (false) using classification probabilities.
  Future<List<double>?> _captureFace({required bool expectOpen}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
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
        enableLandmarks: true,
        enableClassification: true, // Enable classification for eye probabilities.
      );
      final faceDetector = FaceDetector(options: options);
      final faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      if (faces.isEmpty) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No face detected. Please try again.", style: TextStyle(fontFamily: "Outfit")),
          ),
        );
        return null;
      }

      Face face = faces.first;

      // Check for eye status.
      if (face.leftEyeOpenProbability == null || face.rightEyeOpenProbability == null) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to determine eye status. Please try again.", style: TextStyle(fontFamily: "Outfit")),
          ),
        );
        return null;
      }
      double leftProb = face.leftEyeOpenProbability!;
      double rightProb = face.rightEyeOpenProbability!;

      if (expectOpen) {
        if (leftProb < openThreshold || rightProb < openThreshold) {
          // If expected open but eyes are not sufficiently open.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please keep your eyes open.", style: TextStyle(fontFamily: "Outfit")),
              ),
            );
          }
          return null;
        }
      } else {
        if (leftProb > closedThreshold || rightProb > closedThreshold) {
          // If expected closed but eyes are still open.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please close your eyes.", style: TextStyle(fontFamily: "Outfit")),
              ),
            );
          }
          return null;
        }
      }

      // Decode image using the image package.
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        return null;
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
      return embedding;
    } catch (e) {
      if (mounted) {
        debugPrint("Error during face capture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error during face capture.", style: TextStyle(fontFamily: "Outfit")),
          ),
        );
      }
      return null;
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

  /// Main registration process.
  /// First, capture open-eyes embedding (checking that eyes are indeed open),
  /// then prompt for closed-eyes capture (ensuring eyes are closed).
  Future<void> _captureAndRegisterFace() async {
    // Step 1: Capture open-eyes face embedding.
    List<double>? openEmbedding = await _captureFace(expectOpen: true);
    if (openEmbedding == null) return;

    // Inform user that step 1 is complete and prompt for step 2.
    if (!mounted) return;
    bool? continueStep2 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Step 1 Completed',
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
                    'Your face has been scanned successfully with open eyes. Now, please close your eyes and tap Continue.',
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
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: Colors.blue.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
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
    if (continueStep2 != true) return;

    // Wait 2 seconds for the user to close their eyes.
    await Future.delayed(const Duration(seconds: 2));

    // Step 2: Capture closed-eyes face embedding.
    List<double>? closedEmbedding = await _captureFace(expectOpen: false);
    if (closedEmbedding == null) return;

    // Save both embeddings locally.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String openEmbeddingStr = openEmbedding.join(',');
    String closedEmbeddingStr = closedEmbedding.join(',');
    await prefs.setString('face_embedding_open', openEmbeddingStr);
    await prefs.setString('face_embedding_closed', closedEmbeddingStr);

    setState(() {
      _faceEmbeddingOpenStr = openEmbeddingStr;
      _faceEmbeddingClosedStr = closedEmbeddingStr;
      _alreadyRegistered = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Face registered successfully!", style: TextStyle(fontFamily: "Outfit")),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 56,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Face Data?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: const Text(
                    'Are you sure you want to delete the registered face data? This action cannot be undone.',
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        label: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.delete_forever,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: Colors.red.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext, rootNavigator: true).pop();
                          _deleteFaceEmbeddings();
                        },
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
  }

  Future<void> _deleteFaceEmbeddings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('face_embedding_open');
    await prefs.remove('face_embedding_closed');
    setState(() {
      _faceEmbeddingOpenStr = null;
      _faceEmbeddingClosedStr = null;
      _alreadyRegistered = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Face embeddings deleted.", style: TextStyle(fontFamily: "Outfit"))),
    );
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
                color: Colors.black.withValues(alpha: 0.1),
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
                  "Face Registered! 🫡",
                  style: TextStyle(
                    fontFamily: "Outfit",
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isCameraInitialized
                    ? Transform.scale(
                  scaleX: -1.0, // Mirror for front camera.
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
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
              if (_faceEmbeddingOpenStr != null && _faceEmbeddingClosedStr != null)
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
                        fontFamily: "Outfit",
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
