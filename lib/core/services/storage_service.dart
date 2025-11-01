import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Upload a prescription image for a medication
  /// Returns the download URL if successful, null otherwise
  Future<String?> uploadPrescriptionImage({
    required File imageFile,
    required String medicationId,
  }) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      // Create a reference with a unique path
      final ref = _storage
          .ref()
          .child('users')
          .child(_userId)
          .child('prescriptions')
          .child('$medicationId.jpg');

      // Upload the file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'medicationId': medicationId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload prescription image: $e');
    }
  }

  /// Delete a prescription image
  Future<void> deletePrescriptionImage(String imageUrl) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      // Extract the path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // If deletion fails, log but don't throw (image might not exist)
      // This is non-critical for app functionality
      print('Failed to delete prescription image: $e');
    }
  }
}

