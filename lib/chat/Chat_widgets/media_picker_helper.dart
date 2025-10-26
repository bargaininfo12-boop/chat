import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'multi_image_cropper_screen.dart';

class MediaPickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick multiple images and open friendly cropper flow
  static Future<List<File>> pickAndCropMultiple(BuildContext context) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) return [];

      final files = pickedFiles.map((e) => File(e.path)).toList();

      // Check if context is still mounted before navigation
      if (!context.mounted) return [];

      final List<File>? cropped = await Navigator.of(context).push<List<File>>(
        MaterialPageRoute(builder: (_) => MultiImageCropperScreen(images: files)),
      );
      return cropped ?? [];
    } catch (e) {
      debugPrint('⚠️ pickAndCropMultiple error: $e');
      return [];
    }
  }

  static Future<File?> pickVideo() async {
    try {
      final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('⚠️ pickVideo error: $e');
      return null;
    }
  }

  static Future<File?> captureImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('⚠️ captureImage error: $e');
      return null;
    }
  }
}
