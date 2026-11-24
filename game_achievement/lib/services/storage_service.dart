import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads to profile_pictures/{uid}/avatar_{timestamp}.jpg and returns the
  /// download URL. A new file name each time avoids stale cached images;
  /// the previous picture (if any) is deleted afterwards.
  Future<String> uploadProfilePicture({
    required String uid,
    required File file,
    String? previousUrl,
  }) async {
    final name = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('profile_pictures/$uid/$name');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    if (previousUrl != null && previousUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(previousUrl).delete();
      } catch (_) {
        // Old file already gone or not ours - safe to ignore.
      }
    }
    return url;
  }
}
