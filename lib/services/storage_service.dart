import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://studytrack-b3c6a.firebasestorage.app',
  );

  Future<String?> uploadProfilePhoto(String userId, File photoFile) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');

      await ref.putFile(photoFile).timeout(const Duration(seconds: 30));

      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Fotograf yukleme hatasi: $e');
      throw e;
    }
  }
}