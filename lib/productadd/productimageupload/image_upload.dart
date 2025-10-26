import 'dart:io';
import 'package:bargain/chat/Chat_widgets/media_picker_helper.dart';
import 'package:bargain/productadd/add_product/data_holder.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/productadd/productimageupload/SuccessScreen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen>
    with WidgetsBindingObserver {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  bool _isLoading = false;
  String? _uid;
  String? _productId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uid = FirebaseAuth.instance.currentUser?.uid;

    // Create or reuse Firestore product document
    if (DataHolder.productId != null) {
      _productId = DataHolder.productId;
    } else {
      final newRef = (_uid != null && _uid!.isNotEmpty)
          ? _db.collection('users').doc(_uid).collection('products').doc()
          : _db.collection('products').doc();
      _productId = newRef.id;
      DataHolder.productId = _productId;
      DataHolder.uid = _uid;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔄 Recheck permissions when user returns from settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger silent recheck (no popup)
      Permission.photos.status.then((status) {
        if (status.isGranted && mounted) {
          setState(() {});
        }
      });
    }
  }

  // 🔐 Check gallery/photos permission (Android + iOS)
  Future<bool> _checkAndRequestPermission() async {
    PermissionStatus status;
    int sdkInt = 0;

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      sdkInt = info.version.sdkInt;
      if (sdkInt >= 33) {
        // Android 13+ uses PHOTOS permission
        status = await Permission.photos.status;
        if (status.isDenied) {
          status = await Permission.photos.request();
        }
      } else {
        // Older Androids use storage permission
        status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }
    } else {
      status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    }

    return status.isGranted || status.isLimited;
  }

  // 🔐 Check camera permission
  Future<bool> _checkAndRequestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) status = await Permission.camera.request();

    if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    }
    return status.isGranted;
  }

  // ⚙️ Show dialog to open app settings
  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'To upload photos or videos, please enable access:\n\n'
              '• Go to Settings → Apps → Bargain → Permissions\n'
              '• Turn ON “Photos and Videos” or “Storage” and “Camera”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  // 🖼️ Pick multiple images (crop + compression)
  Future<void> _pickAndCropImages() async {
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      _showSnackBar("Gallery permission is required");
      return;
    }

    if (!mounted) return;
    try {
      final files = await MediaPickerHelper.pickAndCropMultiple(context);
      if (files.isEmpty) return;
      setState(() => _selectedImages.addAll(files));
    } catch (e) {
      _showSnackBar("Failed to pick/crop images");
      debugPrint("Image pick/crop error: $e");
    }
  }

  // 🎥 Pick video from gallery
  Future<void> _pickVideo() async {
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      _showSnackBar("Gallery permission is required");
      return;
    }

    if (!mounted) return;
    try {
      final file = await MediaPickerHelper.pickVideo();
      if (file != null) setState(() => _selectedVideos.add(file));
    } catch (e) {
      _showSnackBar("Failed to pick video");
      debugPrint("Video pick error: $e");
    }
  }

  // ☁️ Upload images & videos to Firebase Storage
  Future<void> _uploadMedia() async {
    if (_uid == null || _uid!.isEmpty) {
      _showSnackBar("⚠️ Please login before uploading.");
      return;
    }

    setState(() => _isLoading = true);
    final safeContext = context;

    try {
      List<String> imageUrls = [];
      List<String> videoUrls = [];

      // Images
      if (_selectedImages.isEmpty) {
        imageUrls = DataHolder.imageUrls;
      } else {
        for (final image in _selectedImages) {
          final fileName = const Uuid().v4();
          final ref = _storage.ref().child('images/$fileName.jpg');
          await ref.putFile(image);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      // Videos
      if (_selectedVideos.isEmpty) {
        videoUrls = DataHolder.videoUrls;
      } else {
        for (final video in _selectedVideos) {
          final fileName = const Uuid().v4();
          final ref = _storage.ref().child('videos/$fileName.mp4');
          await ref.putFile(video);
          final url = await ref.getDownloadURL();
          videoUrls.add(url);
        }
      }

      DataHolder.imageUrls = imageUrls;
      DataHolder.videoUrls = videoUrls;

      if (!mounted) return;
      await _saveDataToFirestore(safeContext);
    } catch (e) {
      _showSnackBar("Upload failed. Please try again.");
      debugPrint("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🗄️ Save data to Firestore
  Future<void> _saveDataToFirestore(BuildContext safeContext) async {
    final uid = _uid ?? DataHolder.uid ?? '';
    final productId = _productId ?? DataHolder.productId ?? '';

    if (uid.isEmpty || productId.isEmpty) {
      _showSnackBar("⚠️ Missing UID or Product ID.");
      return;
    }

    try {
      final productData = DataHolder.toMap();

      if (DataHolder.description != null &&
          DataHolder.description!.trim().isNotEmpty) {
        productData['Description'] = DataHolder.description!.trim();
      }

      final docRef =
      _db.collection("users").doc(uid).collection("products").doc(productId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update(productData);
      } else {
        await docRef.set(productData);
      }

      if (!mounted) return;
      await DataHolder.clearAllData();

      if (safeContext.mounted) {
        Navigator.pushReplacement(
          safeContext,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      }
    } catch (e) {
      _showSnackBar("Failed to save product. Please try again.");
      debugPrint("Firestore save error: $e");
    }
  }

  // 🔔 SnackBar
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor(Theme.of(context)),
      ),
    );
  }

  // 🎠 Carousel preview
  Widget _buildCarousel(double screenWidth) {
    final theme = Theme.of(context);
    final items = <Widget>[];

    for (final file in _selectedImages) {
      items.add(Container(
        width: screenWidth,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, fit: BoxFit.cover),
        ),
      ));
    }

    for (final file in _selectedVideos) {
      items.add(Container(
        width: screenWidth,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.videocam, size: 60, color: Colors.white),
        ),
      ));
    }

    if (items.isEmpty) {
      items.add(Center(
        child: Text("No media selected", style: theme.textTheme.bodyMedium),
      ));
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 220,
        viewportFraction: 0.8,
        enlargeCenterPage: true,
      ),
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBackground(theme),
        title: Text(
          'Upload Media',
          style: theme.textTheme.titleLarge
              ?.copyWith(color: AppTheme.textPrimary(theme)),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor(theme),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCarousel(screenWidth),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickAndCropImages,
                    icon: const Icon(Icons.photo),
                    label: const Text("Add Photos"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text("Add Video"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _uploadMedia,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Upload All"),
            ),
          ],
        ),
      ),
    );
  }
}
