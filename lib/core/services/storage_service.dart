import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path/path.dart' as p;

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
      final extension = _determineFileExtension(imageFile.path);
      final contentType = _contentTypeFromExtension(extension);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp$extension';

      // Create a reference with a unique path per medication
      final ref = _storage
          .ref()
          .child('users')
          .child(_userId)
          .child('prescriptions')
          .child(medicationId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'medicationId': medicationId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      await uploadTask;

      try {
        return await _getDownloadUrlWithRetry(ref);
      } on FirebaseException catch (e) {
        throw Exception('Failed to upload prescription image: ${e.message}');
      }
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

  String _determineFileExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext.isEmpty) {
      return '.jpg';
    }
    return ext;
  }

  String _contentTypeFromExtension(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<String> _getDownloadUrlWithRetry(Reference ref) async {
    const maxAttempts = 3;
    var attempt = 0;
    while (true) {
      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found' && attempt < maxAttempts - 1) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        rethrow;
      }
    }
  }
}
