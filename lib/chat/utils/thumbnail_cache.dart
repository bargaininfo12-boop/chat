// File: lib/chat/utils/thumbnail_cache.dart
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailCache {
  ThumbnailCache._internal();
  static final ThumbnailCache instance = ThumbnailCache._internal();

  /// Where we cache files: <appDocDir>/media/thumbs/
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/media/thumbs');
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }

  /// Tune how many thumbnails to keep.
  int maxEntries = 40;

  final Map<String, Future<String?>> _inflight = {};
  int _active = 0;
  final int _maxParallel = 2;

  /// Returns cached path if exists, else generates and saves a thumbnail.
  /// Returns null if source is remote http(s) or on failure.
  Future<String?> getOrCreate({
    required String messageId,
    required String sourceUrlOrPath,
    int width = 720,
    int quality = 70,
    bool preferWebp = true,
  }) async {
    if (messageId.isEmpty) return null;
    final src = sourceUrlOrPath.trim();
    if (src.isEmpty) return null;

    final uri = Uri.tryParse(src);

    // Skip remote http(s) — we only thumbnail local media
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }

    final dir = await _dir();
    final ext = preferWebp ? 'webp' : 'jpg';
    final outPath = '${dir.path}/$messageId.$ext';
    final outFile = File(outPath);

    // Cache hit
    if (await outFile.exists()) {
      try { await outFile.setLastModified(DateTime.now()); } catch (_) {}
      return outFile.path;
    }

    // De-dupe concurrent work
    if (_inflight.containsKey(outPath)) return _inflight[outPath]!;

    final completer = Completer<String?>();
    _inflight[outPath] = completer.future;

    () async {
      try {
        // simple global parallel throttle
        while (_active >= _maxParallel) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        _active++;

        // Decide how to call the plugin:
        // - real file path → verify exists, then pass filesystem path
        // - content:// or other custom scheme → pass original string (plugin can handle on Android)
        String? generatorInputPath;
        bool passRawString = false;

        final isFilesystemPath =
            uri == null || uri.scheme.isEmpty || uri.scheme == 'file';

        if (isFilesystemPath) {
          final filePath = uri?.scheme == 'file' ? uri!.toFilePath() : src;
          final f = File(filePath);
          if (!await f.exists()) {
            completer.complete(null);
            return;
          }
          generatorInputPath = f.path;
        } else {
          // e.g., content://… → let plugin resolve it
          passRawString = true;
        }

        final String? tmp = await VideoThumbnail.thumbnailFile(
          video: passRawString ? src : generatorInputPath!,
          imageFormat: preferWebp ? ImageFormat.WEBP : ImageFormat.JPEG,
          maxWidth: width, // keep aspect ratio
          quality: quality.clamp(1, 100),
        );

        if (tmp == null) {
          completer.complete(null);
          return;
        }

        // Move/rename into our cache path (copy fallback)
        try {
          final tmpFile = File(tmp);
          if (await tmpFile.exists()) {
            await tmpFile.rename(outPath);
          }
        } catch (_) {
          try {
            final tmpFile = File(tmp);
            if (await tmpFile.exists()) {
              await tmpFile.copy(outPath);
              await tmpFile.delete();
            }
          } catch (_) {}
        }

        try { await outFile.setLastModified(DateTime.now()); } catch (_) {}
        unawaited(_cleanupLRU());
        completer.complete(await outFile.exists() ? outFile.path : null);
      } catch (_) {
        completer.complete(null);
      } finally {
        _active = (_active - 1).clamp(0, 1 << 30);
        _inflight.remove(outPath);
      }
    }();

    return completer.future;
  }

  /// Evict all thumbnails
  Future<void> clearAll() async {
    try {
      final d = await _dir();
      if (await d.exists()) {
        await for (final e in d.list(followLinks: false)) {
          if (e is File) {
            final name = e.path.split('/').last.toLowerCase();
            if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.webp')) {
              unawaited(_safeDelete(e));
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Remove a single entry by messageId
  Future<void> evict(String messageId) async {
    final d = await _dir();
    final candidates = [
      File('${d.path}/$messageId.webp'),
      File('${d.path}/$messageId.jpg'),
      File('${d.path}/$messageId.jpeg'),
    ];
    for (final f in candidates) {
      if (await f.exists()) {
        await _safeDelete(f);
      }
    }
  }

  /// Keep newest [maxEntries], delete older
  Future<void> _cleanupLRU() async {
    try {
      final d = await _dir();
      if (!await d.exists()) return;

      final files = <File>[];
      await for (final e in d.list(followLinks: false)) {
        if (e is File) {
          final name = e.path.split('/').last.toLowerCase();
          if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.webp')) {
            files.add(e);
          }
        }
      }
      if (files.length <= maxEntries) return;

      files.sort((a, b) {
        DateTime am, bm;
        try { am = a.lastModifiedSync(); } catch (_) { am = DateTime.fromMillisecondsSinceEpoch(0); }
        try { bm = b.lastModifiedSync(); } catch (_) { bm = DateTime.fromMillisecondsSinceEpoch(0); }
        return bm.compareTo(am); // newest first
      });

      for (int i = maxEntries; i < files.length; i++) {
        unawaited(_safeDelete(files[i]));
      }
    } catch (_) {}
  }

  Future<void> _safeDelete(File f) async {
    try { await f.delete(); } catch (_) {}
  }
}
