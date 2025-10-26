import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraHandler extends StatefulWidget {
  const CameraHandler({super.key});

  /// Opens the camera UI with options for capturing a photo or recording a video.
  /// Returns a Map containing the captured file and its type.
  /// Example: { 'file': File, 'type': 'image' } or { 'file': File, 'type': 'video' }
  static Future<Map<String, dynamic>?> openCamera(BuildContext context) async {
    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CameraHandler()),
    );
  }

  @override
  State<CameraHandler> createState() => CameraHandlerState();
}

class CameraHandlerState extends State<CameraHandler> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isCameraInitialized = false;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initializes the camera by fetching available cameras and setting up the controller.
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      // Prefer the back camera if available; otherwise, use the first camera.
      final CameraDescription selectedCamera = cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras!.first,
      );
      _controller = CameraController(selectedCamera, ResolutionPreset.high);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Captures a photo and returns the file with type 'image'.
  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile xFile = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop({'file': File(xFile.path), 'type': 'image'});
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    }
  }

  /// Toggles video recording
  Future<void> _toggleVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      if (_isRecording) {
        final XFile xFile = await _controller!.stopVideoRecording();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
        });
        Navigator.of(context).pop({'file': File(xFile.path), 'type': 'video'});
      } else {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint("Error during video recording: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Camera"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview fills the screen.
          CameraPreview(_controller!),
          // Positioned controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Photo capture
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: "photo",
                      backgroundColor: Colors.white,
                      onPressed: _capturePhoto,
                      child: const Icon(Icons.camera_alt, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text("Photo", style: TextStyle(color: Colors.white)),
                  ],
                ),
                // Video recording
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: "video",
                      backgroundColor: _isRecording ? Colors.red : Colors.white,
                      onPressed: _toggleVideoRecording,
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.videocam,
                        color: _isRecording ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Video", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
