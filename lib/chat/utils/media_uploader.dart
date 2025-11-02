import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MediaUploader {
  static Future<String> uploadFile({
    required File file,
    required Map<String, dynamic> signedInfo,
  }) async {
    try {
      // Validate and extract upload URL
      final url = signedInfo['uploadUrl'] ?? signedInfo['url'];
      if (url == null || url is! String || url.isEmpty) {
        throw Exception('❌ uploadUrl is missing or invalid');
      }

      // Validate and extract CDN base URL
      final cdnBase = signedInfo['cdnBaseUrl'];
      if (cdnBase == null || cdnBase is! String || cdnBase.isEmpty) {
        throw Exception('❌ cdnBaseUrl is missing or invalid');
      }

      // Validate and extract fields
      final rawFields = signedInfo['fields'];
      if (rawFields == null || rawFields is! Map) {
        throw Exception('❌ fields object is missing or invalid');
      }

      final fields = Map<String, String>.from(rawFields);
      final key = fields['key'];
      if (key == null || key.isEmpty) {
        throw Exception('❌ fields["key"] is missing or empty');
      }

      debugPrint('📦 Uploading to: $url');
      debugPrint('📦 CDN base: $cdnBase');
      debugPrint('📦 Key: $key');

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final status = response.statusCode;

      if (status == 200 || status == 201 || status == 204) {
        final finalUrl = '$cdnBase/$key';
        debugPrint('✅ Upload success: $finalUrl');
        return finalUrl;
      } else {
        final body = await response.stream.bytesToString();
        debugPrint('❌ Upload failed: $status → $body');
        throw Exception('Upload failed: $status');
      }
    } catch (e) {
      debugPrint('! CDN upload error: $e');
      rethrow;
    }
  }
}
