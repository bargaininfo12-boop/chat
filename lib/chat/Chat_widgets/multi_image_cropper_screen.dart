import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// MultiImageCropperScreen:
/// Lets the user crop multiple selected images one by one,
/// automatically compresses them, and returns the final list.
class MultiImageCropperScreen extends StatefulWidget {
  final List<File> images;

  const MultiImageCropperScreen({super.key, required this.images});

  @override
  State<MultiImageCropperScreen> createState() =>
      _MultiImageCropperScreenState();
}

class _MultiImageCropperScreenState extends State<MultiImageCropperScreen> {
  final List<File> _croppedImages = [];
  int _currentIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the original files (will be replaced after cropping/compression)
    _croppedImages.addAll(widget.images);
  }

  /// Crop current image using image_cropper v3
  Future<void> _cropCurrentImage() async {
    final File currentFile = _croppedImages[_currentIndex];
    setState(() => _isProcessing = true);

    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: currentFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
            'Crop ${_currentIndex + 1}/${_croppedImages.length}',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Colors.deepPurpleAccent,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final File croppedAsFile = File(croppedFile.path);
        final File compressed = await _compressImage(croppedAsFile);
        setState(() => _croppedImages[_currentIndex] = compressed);
      }
    } catch (e, st) {
      debugPrint("❌ _cropCurrentImage error: $e\n$st");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Compress image safely (handles XFile return type)
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final String targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80, // adjust between 70–90 for quality/performance
      );

      // Convert XFile to File if compression succeeded
      if (result != null) {
        return File(result.path);
      } else {
        debugPrint("⚠️ _compressImage returned null, using original file");
        return file;
      }
    } catch (e) {
      debugPrint("⚠️ _compressImage error: $e");
      return file;
    }
  }

  void _nextOrFinish() {
    if (_currentIndex < _croppedImages.length - 1) {
      setState(() => _currentIndex++);
    } else {
      Navigator.of(context).pop(_croppedImages);
    }
  }

  void _skipAndReturn() {
    Navigator.of(context).pop(_croppedImages);
  }

  @override
  Widget build(BuildContext context) {
    final File current = _croppedImages[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Crop ${_currentIndex + 1}/${_croppedImages.length}'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _skipAndReturn,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Image.file(
                current,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _cropCurrentImage,
                  icon: const Icon(Icons.crop),
                  label: const Text('Crop'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _nextOrFinish,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_currentIndex == _croppedImages.length - 1
                      ? 'Finish'
                      : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
