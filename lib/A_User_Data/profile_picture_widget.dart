// File: lib/A_User_Data/profile_picture_widget.dart
// v2.0.0 — Added optional onImageTap callback and small robustness fixes

import 'dart:io';
import 'package:bargain/A_User_Data/user_model.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/Database/database_helper.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ProfilePictureWidget extends StatefulWidget {
  final User user;
  final double radius;
  final bool showEditIcon;
  final VoidCallback? onImageTap; // ✅ optional callback when avatar tapped

  const ProfilePictureWidget({
    super.key,
    required this.user,
    this.onImageTap,
    this.radius = 32,
    this.showEditIcon = false,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      final user = _firebaseAuthService.auth.currentUser;
      if (user != null) {
        final storageReference = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('${user.uid}.jpg');
        final snap = await storageReference.putFile(image);
        return await snap.ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProfilePicUrl(String userId, File imageFile) async {
    try {
      setState(() => _isLoading = true);

      final imageUrl = await _uploadImageToFirebase(imageFile);
      final localImagePath = await _saveImageLocally(imageFile, '$userId.jpg');

      if (imageUrl != null) {
        await _firebaseAuthService.firestore
            .collection('users')
            .doc(userId)
            .update({'photoURL': imageUrl, 'updatedAt': FieldValue.serverTimestamp()});
      }

      // Update local DB record (best-effort)
      final existing = await _databaseHelper.getUser(userId);
      if (existing != null) {
        final updated = existing.copyWith(photoURL: localImagePath, photoLocal: true);
        await _databaseHelper.updateUser(updated);
      } else {
        await _databaseHelper.insertUser(UserModel(uid: userId, photoURL: localImagePath, photoLocal: true));
      }

      if (!mounted) return;
      _showSnackBar('Profile picture updated successfully!');
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      if (!mounted) return;
      _showSnackBar('Failed to update profile picture', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeProfilePic() async {
    final user = _firebaseAuthService.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseStorage.instance
          .ref()
          .child('profile_pics/${user.uid}.jpg')
          .delete()
          .catchError((_) {}); // ignore if not exists

      await _firebaseAuthService.firestore
          .collection('users')
          .doc(user.uid)
          .update({'photoURL': FieldValue.delete()});

      await _deleteLocalImage('${user.uid}.jpg');

      final existing = await _databaseHelper.getUser(user.uid);
      if (existing != null) {
        final updated = existing.copyWith(photoURL: null, photoLocal: false);
        await _databaseHelper.updateUser(updated);
      }

      if (!mounted) return;
      _showSnackBar('Profile picture removed successfully!');
    } catch (e) {
      debugPrint('Error removing profile picture: $e');
      if (!mounted) return;
      _showSnackBar('Failed to remove profile picture', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        final user = _firebaseAuthService.auth.currentUser;
        if (user != null) {
          await _updateProfilePicUrl(user.uid, File(pickedFile.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      _showSnackBar('Failed to pick image', isError: true);
    }
  }

  Future<String> _saveImageLocally(File imageFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    await imageFile.copy(filePath);
    return filePath;
  }

  Future<void> _deleteLocalImage(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  Stream<UserModel?> _userStream() {
    return _firebaseAuthService.firestore
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final url = (data['photoURL'] as String?)?.trim();
        if (url != null && url.isNotEmpty) {
          // If URL looks like a local file path, mark photoLocal true
          final isLocal = url.startsWith('/') || url.startsWith('file:');
          return UserModel(uid: widget.user.uid, photoURL: url, photoLocal: isLocal);
        }
      }
      return null;
    });
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorColor(theme) : AppTheme.successColor(theme),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _showImageOptionDialog() async {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(theme),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.mediumShadow(theme),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: AppTheme.dividerColor(theme), borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 16),
                _optionTile(theme, icon: Icons.camera_alt, title: 'Take Photo', subtitle: 'Use your camera', onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                const SizedBox(height: 12),
                _optionTile(theme, icon: Icons.photo_library, title: 'Choose from Gallery', subtitle: 'Pick from gallery', onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
                const SizedBox(height: 12),
                StreamBuilder<DocumentSnapshot>(
                  stream: _firebaseAuthService.firestore.collection('users').doc(widget.user.uid).snapshots(),
                  builder: (_, snap) {
                    String? photoUrl;
                    if (snap.hasData && snap.data!.exists) {
                      photoUrl = (snap.data!.data() as Map<String, dynamic>?)?['photoURL'] as String?;
                    }
                    if (photoUrl != null && photoUrl.isNotEmpty) {
                      return _optionTile(theme, icon: Icons.delete_outline, title: 'Remove Photo', subtitle: 'Delete profile picture', isDestructive: true, onTap: () {
                        Navigator.pop(context);
                        _removeProfilePic();
                      });
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryAccent(theme), fontSize: 16))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionTile(ThemeData theme, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? AppTheme.errorColor(theme) : AppTheme.textColor(theme);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.dividerColor(theme).withOpacity(0.4))),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(theme)))])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(ThemeData theme, File? localFile, String? profilePicUrl) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppTheme.primaryAccent(theme).withOpacity(0.9), AppTheme.primaryAccent(theme).withOpacity(0.6)]),
        boxShadow: [BoxShadow(color: AppTheme.primaryAccent(theme).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppTheme.surfaceColor(theme),
        backgroundImage: localFile != null ? FileImage(localFile) : (profilePicUrl != null && profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) as ImageProvider : null),
        child: localFile == null && (profilePicUrl == null || profilePicUrl.isEmpty) ? Icon(Icons.person, size: widget.radius * 0.9, color: AppTheme.iconColor(theme).withOpacity(0.6)) : null,
      ),
    );
  }

  Widget _loadingAvatar(ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          width: widget.radius * 2 + 12,
          height: widget.radius * 2 + 12,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppTheme.primaryAccent(theme).withOpacity(0.2 + _animation.value * 0.2), AppTheme.primaryAccent(theme).withOpacity(0.05)])),
          child: CircleAvatar(radius: widget.radius, backgroundColor: AppTheme.surfaceColor(theme), child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppTheme.primaryAccent(theme)))),
        );
      },
    );
  }

  Widget _skeletonShimmer(ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.shimmerBaseColor(theme), AppTheme.shimmerHighlightColor(theme).withOpacity(0.5 + _animation.value * 0.5)])),
        );
      },
    );
  }

  Widget _editButton(ThemeData theme) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: InkWell(
        onTap: _showImageOptionDialog,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryAccent(theme), border: Border.all(color: AppTheme.surfaceColor(theme), width: 2), boxShadow: [BoxShadow(color: AppTheme.primaryAccent(theme).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Icon(Icons.edit, size: 18, color: AppTheme.textOnPrimary(theme)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: widget.onImageTap, // ✅ use the provided callback (may be null)
          child: StreamBuilder<UserModel?>(
            stream: _userStream(),
            builder: (_, snap) {
              if (_isLoading) return _loadingAvatar(theme);
              if (snap.connectionState == ConnectionState.waiting) return _skeletonShimmer(theme);

              String? profilePicUrl;
              File? localFile;

              if (snap.hasData) {
                final user = snap.data!;
                profilePicUrl = !user.photoLocal ? user.photoURL : null;
                localFile = user.photoLocal && user.photoURL != null ? File(user.photoURL!) : null;
              }

              if (profilePicUrl == null && localFile == null) {
                return _skeletonShimmer(theme);
              }

              return _avatar(theme, localFile, profilePicUrl);
            },
          ),
        ),
        if (widget.showEditIcon)
          _editButton(theme),
      ],
    );
  }
}
