import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Uploads a file to Firebase Storage at the given [path] and shows a progress dialog.
/// Returns the download URL once upload is complete.
Future<String> uploadFileWithProgress({
  required BuildContext context,
  required File file,
  required String path,
}) async {
  // Create a reference and start the upload.
  Reference ref = FirebaseStorage.instance.ref().child(path);
  UploadTask uploadTask = ref.putFile(file);

  // Create a ValueNotifier to track the progress.
  ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);

  // Listen to the upload progress events.
  uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
    if (snapshot.totalBytes > 0) {
      progressNotifier.value = snapshot.bytesTransferred / snapshot.totalBytes;
    }
  });

  // Show a progress dialog that updates based on progressNotifier.
  final dialogFuture = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        content: SizedBox(
          height: 100,
          child: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, value, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Uploading... ${(value * 100).toStringAsFixed(0)}%", style: TextStyle(fontFamily: "Outfit")),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: value),
                ],
              );
            },
          ),
        ),
      );
    },
  );

  // Wait for the upload to complete.
  TaskSnapshot snapshot = await uploadTask;
  // Once complete, dismiss the progress dialog.
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
  await dialogFuture;

  // Retrieve and return the download URL.
  String downloadUrl = await snapshot.ref.getDownloadURL();
  return downloadUrl;
}
