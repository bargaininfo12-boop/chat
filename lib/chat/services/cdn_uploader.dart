// v0.8-cdn_uploader · 2025-10-25T15:55 IST
// lib/chat/Services/cdn_uploader.dart
//
// CdnUploader: request signed URL + upload file with progress and cancellation.
// - uses a single HttpClient per CdnUploader instance (closed in dispose())
// - exposes dispose() and a boolean isDisposed
// - uploadFile supports CancelToken and onProgress callback
//
// Usage remains same as before.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CdnUploadResponse {
  final String uploadUrl; // Signed URL to PUT the file to (usually pre-signed URL)
  final String? cdnUrl; // Public CDN URL where the file will be available (optional)
  final String? thumbUrl; // Thumbnail URL (optional)
  final Map<String, dynamic>? meta; // Any extra meta returned by the signer

  CdnUploadResponse({
    required this.uploadUrl,
    this.cdnUrl,
    this.thumbUrl,
    this.meta,
  });

  factory CdnUploadResponse.fromMap(Map<String, dynamic> m) {
    return CdnUploadResponse(
      uploadUrl: (m['uploadUrl'] ?? m['upload_url'] ?? m['url'] ?? '') as String,
      cdnUrl: (m['cdnUrl'] ?? m['cdn_url']) as String?,
      thumbUrl: (m['thumbUrl'] ?? m['thumb_url']) as String?,
      meta: (m['meta'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploadUrl': uploadUrl,
      'cdnUrl': cdnUrl,
      'thumbUrl': thumbUrl,
      'meta': meta,
    };
  }
}

class UploadResult {
  final bool success;
  final CdnUploadResponse? response;
  final int? statusCode;
  final String? message;

  UploadResult({
    required this.success,
    this.response,
    this.statusCode,
    this.message,
  });
}

/// Simple cancel token to stop ongoing uploads.
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// CdnUploader with lifecycle management
class CdnUploader {
  final Uri signingEndpoint;
  final Duration _httpTimeout;

  // Reused HttpClient so we can close it in dispose()
  HttpClient? _httpClient;
  bool _isDisposed = false;

  CdnUploader({
    required this.signingEndpoint,
    Duration httpTimeout = const Duration(seconds: 60),
  }) : _httpTimeout = httpTimeout {
    _httpClient = HttpClient();
  }

  bool get isDisposed => _isDisposed;

  /// Dispose resources used by uploader (close HttpClient)
  void dispose() {
    if (_isDisposed) return;
    try {
      _httpClient?.close(force: true);
    } catch (_) {}
    _httpClient = null;
    _isDisposed = true;
  }

  /// Request a signed upload URL from server.
  Future<CdnUploadResponse> getSignedUploadUrl({
    required String filename,
    required String mime,
    required int size,
    Map<String, dynamic>? metadata,
  }) async {
    if (_isDisposed) throw StateError('CdnUploader is disposed');

    final client = _httpClient ?? HttpClient();
    try {
      final req = await client.openUrl('POST', signingEndpoint).timeout(_httpTimeout);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      final body = jsonEncode({
        'filename': filename,
        'mime': mime,
        'size': size,
        'metadata': metadata ?? {},
      });
      req.add(utf8.encode(body));
      final resp = await req.close().timeout(_httpTimeout);

      final respBody = await resp.transform(utf8.decoder).join();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Signer returned ${resp.statusCode}: $respBody');
      }
      if (respBody.trim().isEmpty) {
        throw Exception('Empty signer response');
      }
      final parsed = jsonDecode(respBody) as Map<String, dynamic>;
      final signed = CdnUploadResponse.fromMap(parsed);
      if (signed.uploadUrl.isEmpty) {
        throw Exception('Signer response missing uploadUrl');
      }
      return signed;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload file by streaming via HTTP PUT to signed URL.
  Future<UploadResult> uploadFile({
    required File file,
    required String mime,
    required CdnUploadResponse signedInfo,
    CancelToken? cancelToken,
    void Function(double percent)? onProgress,
  }) async {
    if (_isDisposed) return UploadResult(success: false, message: 'Uploader disposed');

    final uri = Uri.parse(signedInfo.uploadUrl);
    final client = _httpClient ?? HttpClient();
    try {
      final len = await file.length();
      final req = await client.openUrl('PUT', uri).timeout(_httpTimeout);

      // set sensible headers; some providers ignore content-type
      req.headers.set(HttpHeaders.contentTypeHeader, mime);
      req.headers.set(HttpHeaders.contentLengthHeader, len.toString());

      int sent = 0;
      StreamSubscription<List<int>>? subscription;
      final stream = file.openRead();

      final completer = Completer<HttpClientResponse>();

      subscription = stream.listen((chunk) {
        if (cancelToken?.isCancelled ?? false) {
          try {
            subscription?.cancel();
          } catch (_) {}
          // abort request (not all platforms support abort well)
          try {
            req.abort();
          } catch (_) {}
          if (!completer.isCompleted) completer.completeError(Exception('Cancelled'));
          return;
        }
        try {
          req.add(chunk);
          sent += chunk.length;
          if (onProgress != null && len > 0) {
            final pct = (sent / len) * 100.0;
            final clamped = pct.isFinite ? pct.clamp(0.0, 100.0) : 0.0;
            onProgress(clamped);
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      }, onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }, onDone: () async {
        try {
          final response = await req.close().timeout(_httpTimeout);
          if (!completer.isCompleted) completer.complete(response);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      }, cancelOnError: true);

      // Monitor cancelToken in background and try abort if set
      if (cancelToken != null) {
        Future.microtask(() async {
          while (!cancelToken.isCancelled && !completer.isCompleted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (cancelToken.isCancelled) {
            try {
              await subscription?.cancel();
            } catch (_) {}
            try {
              req.abort();
            } catch (_) {}
          }
        });
      }

      final resp = await completer.future.timeout(_httpTimeout);
      final body = await resp.transform(utf8.decoder).join();

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (onProgress != null) onProgress(100.0);
        return UploadResult(success: true, response: signedInfo, statusCode: resp.statusCode);
      } else {
        return UploadResult(success: false, statusCode: resp.statusCode, message: body);
      }
    } on TimeoutException catch (te) {
      return UploadResult(success: false, message: 'Timeout: ${te.message}');
    } catch (e) {
      if (cancelToken?.isCancelled ?? false) {
        return UploadResult(success: false, message: 'Cancelled by user');
      }
      return UploadResult(success: false, message: e.toString());
    }
  }
}
