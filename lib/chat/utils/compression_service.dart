// lib/chat/utils/compression_service.dart

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CompressionService {
  static final CompressionService instance = CompressionService._internal();
  CompressionService._internal();

  /// IMAGE compression → returns File
  Future<File> compressImage(
      File file, {
        int quality = 70,
        int minWidth = 1080,
        int minHeight = 1080,
      }) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
    p.join(dir.path, "img_${DateTime.now().millisecondsSinceEpoch}.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception("Image compression failed");
    }
    return File(result.path);
  }

  /// VIDEO compression → returns File
  Future<File> compressVideo(
      File file, {
        VideoQuality quality = VideoQuality.MediumQuality,
      }) async {
    final info = await VideoCompress.compressVideo(
      file.path,
      quality: quality,
      includeAudio: true,
      deleteOrigin: false,
    );

    if (info == null || info.file == null) {
      throw Exception("Video compression failed");
    }
    return File(info.file!.path);
  }

  /// AUDIO "compression" → ❌ No re-encode here
  /// ✅ Use `record` plugin to record directly as AAC/m4a with low bitrate.
  /// This method will just return the same file.
  Future<File> compressAudio(
      File file, {
        int bitrateKbps = 64,
      }) async {
    // NOTE:
    // Record plugin pe use karna:
    // await record.start(
    //   encoder: AudioEncoder.aacLc,
    //   bitRate: bitrateKbps * 1000,
    //   samplingRate: 16000,
    // );
    //
    // Yaha post-compression ki zarurat nahi hai.
    if (!await file.exists()) {
      throw Exception("Audio file not found");
    }
    return file;
  }
}
