import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Profil fotoğrafı yükleme fonksiyonu
  Future<String?> uploadProfilePhoto(String userId, File photoFile) async {
    try {
      // Dosya yolu: profile_photos/KULLANICI_ID.jpg
      // Böylece kişi yeni foto yüklerse eskisi otomatik silinir (üzerine yazar)
      final ref = _storage.ref().child('profile_photos/$userId.jpg');

      // Yükleme işlemi
      await ref.putFile(photoFile);

      // Yüklenen resmin linkini (URL) al
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Fotograf yukleme hatasi: $e');
      return null;
    }
  }
}