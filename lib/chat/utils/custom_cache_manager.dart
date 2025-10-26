// custom_cache_manager.dart (fixed imports + alias)
// NOTE: flutter_cache_manager names conflict with your app Config class.
// We import flutter_cache_manager with alias `cache_manager` to avoid collision.

import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache_manager;
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ Unified Cache Manager
/// Handles:
/// 1️⃣ File/image caching via flutter_cache_manager
/// 2️⃣ JSON/text caching via SharedPreferences
class CustomCacheManager {
  // ---------------- FILE CACHE ----------------
  static const String _fileCacheKey = 'customFileCacheKey';

  /// File-based cache (images, videos, etc.)
  static final cache_manager.CacheManager fileCache = cache_manager.CacheManager(
    cache_manager.Config(
      _fileCacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: cache_manager.JsonCacheInfoRepository(databaseName: _fileCacheKey),
      fileService: cache_manager.HttpFileService(),
    ),
  );

  /// ✅ Optional unified getter (for global consistency)
  static cache_manager.CacheManager get instance => fileCache;

  // ---------------- JSON CACHE ----------------
  static const String _jsonPrefix = 'jsonCache_';
  static const String _versionPrefix = 'jsonVersion_';
  static const Duration _defaultExpiry = Duration(hours: 24);

  /// Save structured JSON data to SharedPreferences
  static Future<void> saveJsonCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(data);
      await prefs.setString('$_jsonPrefix$key', encoded);
      await prefs.setInt(
        '$_versionPrefix$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Use debug print or your logging util
      // print('⚠️ Error saving JSON cache for $key: $e');
    }
  }

  /// Load JSON cache if valid and not expired
  static Future<List<dynamic>?> loadJsonCache(
      String key, {
        Duration? expiry,
      }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versionKey = '$_versionPrefix$key';
      final dataKey = '$_jsonPrefix$key';
      final expiryDuration = expiry ?? _defaultExpiry;

      final version = prefs.getInt(versionKey);
      if (version == null) return null;

      final expired = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(version)) >
          expiryDuration;
      if (expired) {
        await prefs.remove(dataKey);
        await prefs.remove(versionKey);
        return null;
      }

      final jsonString = prefs.getString(dataKey);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString);
      if (decoded is List) return decoded;
      if (decoded is Map) return [decoded];
      return null;
    } catch (e) {
      // print('⚠️ Error loading JSON cache for $key: $e');
      return null;
    }
  }

  /// Remove a specific JSON cache entry
  static Future<void> clearJsonCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_jsonPrefix$key');
      await prefs.remove('$_versionPrefix$key');
    } catch (e) {
      // print('⚠️ Error clearing JSON cache for $key: $e');
    }
  }

  /// Clear all cache (file + JSON)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
            (k) => k.startsWith(_jsonPrefix) || k.startsWith(_versionPrefix),
      );
      for (final k in keys) {
        await prefs.remove(k);
      }
      await fileCache.emptyCache();
      // print('🧹 JSON + file cache cleared successfully.');
    } catch (e) {
      // print('⚠️ Error clearing all caches: $e');
    }
  }
}
