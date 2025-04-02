import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class FullScreenImage extends StatefulWidget {
  final String url;
  const FullScreenImage({super.key, required this.url});

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  Future<void> _downloadImage(String imageUrl) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final String timestamp = formatter.format(DateTime.now());
    const savedDir = '/storage/emulated/0/Download/Attendance/Images';
    final fileName = 'attendance_$timestamp.jpg';

    final Directory directory = Directory(savedDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    double progress = 0.0;
    bool dialogClosed = false;
    StateSetter? dialogSetState; // To update the dialog

    // Show a progress dialog.

    if(!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: const Text("Downloading...", style: TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w500),),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text('${(progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final request = http.Request('GET', Uri.parse(imageUrl));
      final response = await request.send();
      final contentLength = response.contentLength ?? 0;

      final file = File('$savedDir/$fileName');
      final sink = file.openWrite();
      int downloaded = 0;

      // Listen to the response stream and update progress.
      await response.stream.listen(
            (chunk) {
          sink.add(chunk);
          downloaded += chunk.length;
          double newProgress = downloaded / contentLength;
          // Update progress in the dialog.
          if (dialogSetState != null) {
            dialogSetState!(() {
              progress = newProgress;
            });
          }
          // If progress reaches or exceeds 100%, close the dialog immediately.
          if (progress >= 1.0 && !dialogClosed) {
            dialogClosed = true;
            Navigator.of(context).pop();
          }
        },
        onDone: () async {
          await sink.close();
          if (!dialogClosed) {
            // If dialog is still open, close it.
            if(!mounted) return;
            Navigator.of(context).pop();
            dialogClosed = true;
          }
          Fluttertoast.showToast(
            msg: "Image saved successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.blueAccent,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        },
        onError: (e) async {
          await sink.close();
          if (!dialogClosed) {
            if(!mounted) return;
            Navigator.of(context).pop();
            dialogClosed = true;
          }
          Fluttertoast.showToast(
            msg: "Error: $e",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.redAccent,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        },
      ).asFuture(); // Ensure the stream is fully processed.
    } catch (e) {
      if (!dialogClosed) {
        if(!mounted) return;
        Navigator.of(context).pop();
      }
      Fluttertoast.showToast(
        msg: "Error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: widget.url,
                  child: CachedNetworkImage(
                    imageUrl: widget.url,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'downloadButton_${widget.url}', // Or any unique value
                backgroundColor: Colors.black54,
                mini: true,
                onPressed: () => _downloadImage(widget.url),
                child: const Icon(Icons.download_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
