import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class AudioCacheService {
  // Generate SHA-256 hash key from story text (PRD Section 6.4)
  String generateCacheKey(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Fetch cached file handle
  Future<File> getCachedFile(String key) async {
    final cacheDir = await getTemporaryDirectory();
    return File('${cacheDir.path}/tts_$key.mp3');
  }

  // Check if the file is cached and has not expired (7-day TTL - Section 6.4)
  Future<bool> isCached(String key) async {
    try {
      final file = await getCachedFile(key);
      if (!await file.exists()) return false;

      // Expiry validation check
      final lastModified = await file.lastModified();
      final difference = DateTime.now().difference(lastModified);
      if (difference.inDays >= 7) {
        await file.delete(); // Delete expired file
        return false;
      }
      return true;
    } catch (e) {
      return false; // Fail silently
    }
  }

  // Save downloaded audio stream bytes to path_provider cache
  Future<File> saveToCache(String key, List<int> bytes) async {
    final file = await getCachedFile(key);
    return await file.writeAsBytes(bytes);
  }

  // Clear cached tts files manually or on app update (Section 6.4)
  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final dir = Directory(cacheDir.path);
      final List<FileSystemEntity> entities = await dir.list().toList();
      for (final entity in entities) {
        if (entity is File && entity.path.contains('/tts_')) {
          await entity.delete();
        }
      }
    } catch (e) {
      // Fail silently
    }
  }
}



