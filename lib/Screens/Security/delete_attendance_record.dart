import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DeleteAttendance {
  static Future<void> deleteAttendanceRecords(String rollNo) async {
    try {
      // Query all attendance documents in any subcollection named 'rollNumbers'
      // where the 'rollNo' field matches the provided roll number.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('rollNumbers')
          .where('rollNo', isEqualTo: rollNo)
          .get();

      // Delete associated images from Firebase Storage.
      List<Future> storageDeletionFutures = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('imageUrl')) {
          final String? imageUrl = data['imageUrl'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            // Delete the image from Firebase Storage.
            Future deletion = FirebaseStorage.instance
                .refFromURL(imageUrl)
                .delete()
                .catchError((error) {
              print("Error deleting image from storage for rollNo $rollNo: $error");
            });
            storageDeletionFutures.add(deletion);
          }
        }
      }
      await Future.wait(storageDeletionFutures);

      // Use a batch write for efficient deletion of Firestore documents.
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting attendance records for rollNo $rollNo: $e');
      rethrow;
    }
  }
}
