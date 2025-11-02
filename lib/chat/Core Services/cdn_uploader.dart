import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class CdnUploader {
  /// Uploads a file to the CDN using signed parameters
  static Future<String?> uploadFile({
    required File file,
    required String mime,
    required Map<String, dynamic> signedInfo,
  }) async {
    try {
      final uri = Uri.parse('https://upload.imagekit.io/api/v1/files/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['fileName'] = signedInfo['fileName'] ?? file.path.split('/').last
        ..fields['publicKey'] = signedInfo['publicKey']
        ..fields['signature'] = signedInfo['signature']
        ..fields['expire'] = signedInfo['expire'].toString()
        ..fields['token'] = signedInfo['token']
        ..fields['useUniqueFileName'] = 'true'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(mime),
        ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        return json['url'];
      } else {
        debugPrint('❌ CDN upload failed: ${response.statusCode} → $body');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ CDN upload error: $e');
      return null;
    }
  }

  /// Detect MIME type from file
  static String detectMime(File file) {
    final mimeType = lookupMimeType(file.path);
    return mimeType ?? 'application/octet-stream';
  }
}
