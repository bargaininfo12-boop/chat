// Enhanced Attachment Handler - Version 7.0
// Improved UI/UX with glassmorphism design and smooth animations
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bargain/app_theme/app_theme.dart'; // Your theme import

class AttachmentHandler {
  static OverlayEntry? _overlayEntry;
  static OverlayEntry? _backdropEntry;
  static bool _isVisible = false;
  static AnimationController? _animationController;

  static void showAttachmentPanel({
    required BuildContext context,
    required Function(File file, String fileType) onFilePicked,
  }) {
    if (_overlayEntry != null) return;

    final theme = Theme.of(context);

    // Create backdrop overlay first
    _backdropEntry = OverlayEntry(
      builder: (context) => _buildBackdrop(context),
    );

    // Create main panel overlay
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildAttachmentPanel(context, theme, onFilePicked),
    );

    // Insert overlays
    Overlay.of(context).insert(_backdropEntry!);
    Overlay.of(context).insert(_overlayEntry!);

    // Trigger animation
    Future.delayed(const Duration(milliseconds: 50), () {
      _isVisible = true;
      _overlayEntry?.markNeedsBuild();
      _backdropEntry?.markNeedsBuild();
    });
  }

  static void hideAttachmentPanel() {
    _isVisible = false;
    _overlayEntry?.markNeedsBuild();
    _backdropEntry?.markNeedsBuild();

    // Remove overlays after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _overlayEntry?.remove();
      _backdropEntry?.remove();
      _overlayEntry = null;
      _backdropEntry = null;
    });
  }

  static Widget _buildBackdrop(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: hideAttachmentPanel,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.3),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildAttachmentPanel(
      BuildContext context,
      ThemeData theme,
      Function(File file, String fileType) onFilePicked,
      ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: AppTheme.largeRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor(theme).withOpacity(0.9),
                    borderRadius: AppTheme.largeRadius,
                    border: AppTheme.glassBorder(theme),
                    boxShadow: AppTheme.elevatedShadow(theme),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary(theme).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Share Content',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary(theme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Choose how you want to share your content',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary(theme),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Attachment options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEnhancedAttachmentOption(
                            context: context,
                            theme: theme,
                            icon: Icons.photo_library_outlined,
                            filledIcon: Icons.photo_library,
                            label: 'Gallery',
                            subtitle: 'Photos & Videos',
                            color: AppTheme.primaryAccent(theme),
                            delay: 0,
                            onTap: () async {
                              hideAttachmentPanel();
                              await _showImageSourceDialog(context, onFilePicked);
                            },
                          ),

                          _buildEnhancedAttachmentOption(
                            context: context,
                            theme: theme,
                            icon: Icons.camera_alt_outlined,
                            filledIcon: Icons.camera_alt,
                            label: 'Camera',
                            subtitle: 'Take Photo',
                            color: AppTheme.secondaryAccent(theme),
                            delay: 100,
                            onTap: () async {
                              hideAttachmentPanel();
                              await _pickImageFromCamera(context, onFilePicked);
                            },
                          ),

                          _buildEnhancedAttachmentOption(
                            context: context,
                            theme: theme,
                            icon: Icons.videocam_outlined,
                            filledIcon: Icons.videocam,
                            label: 'Video',
                            subtitle: 'Record Video',
                            color: AppTheme.tertiaryAccent(theme),
                            delay: 200,
                            onTap: () async {
                              hideAttachmentPanel();
                              await _pickVideoFromCamera(context, onFilePicked);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildEnhancedAttachmentOption({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required IconData filledIcon,
    required String label,
    required String subtitle,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: _isVisible ? 1.0 : 0.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),

              // Label
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.textPrimary(theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary(theme),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced image source dialog
  static Future<void> _showImageSourceDialog(
      BuildContext context,
      Function(File file, String fileType) onFilePicked,
      ) async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(theme),
          borderRadius: AppTheme.largeRadius,
          border: AppTheme.glassBorder(theme),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Select Source',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary(theme),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryAccent(theme).withOpacity(0.15),
                child: Icon(
                  Icons.photo_library,
                  color: AppTheme.primaryAccent(theme),
                ),
              ),
              title: Text(
                'Photo Library',
                style: TextStyle(color: AppTheme.textPrimary(theme)),
              ),
              subtitle: Text(
                'Choose from your photos',
                style: TextStyle(color: AppTheme.textSecondary(theme)),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(context, onFilePicked);
              },
            ),

            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.secondaryAccent(theme).withOpacity(0.15),
                child: Icon(
                  Icons.videocam,
                  color: AppTheme.secondaryAccent(theme),
                ),
              ),
              title: Text(
                'Video Library',
                style: TextStyle(color: AppTheme.textPrimary(theme)),
              ),
              subtitle: Text(
                'Choose from your videos',
                style: TextStyle(color: AppTheme.textSecondary(theme)),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickVideoFromGallery(context, onFilePicked);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Media picker methods
  static Future<void> _pickImageFromGallery(
      BuildContext context,
      Function(File file, String fileType) onFilePicked,
      ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedImage != null) {
        onFilePicked(File(pickedImage.path), "image");
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to pick image from gallery');
    }
  }

  static Future<void> _pickVideoFromGallery(
      BuildContext context,
      Function(File file, String fileType) onFilePicked,
      ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedVideo = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (pickedVideo != null) {
        onFilePicked(File(pickedVideo.path), "video");
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to pick video from gallery');
    }
  }

  static Future<void> _pickImageFromCamera(
      BuildContext context,
      Function(File file, String fileType) onFilePicked,
      ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedImage != null) {
        onFilePicked(File(pickedImage.path), "image");
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to take photo');
    }
  }

  static Future<void> _pickVideoFromCamera(
      BuildContext context,
      Function(File file, String fileType) onFilePicked,
      ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedVideo = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (pickedVideo != null) {
        onFilePicked(File(pickedVideo.path), "video");
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to record video');
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor(Theme.of(context)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.mediumRadius,
          ),
        ),
      );
    }
  }
}

// Usage example in your chat screen:
/*
FloatingActionButton(
  onPressed: () {
    Enhanced    EnhancedAttachmentHandler.showAttachmentPanel(
      context: context,
      onFilePicked: (File file, String fileType) {
        // Handle the picked file
        print('Picked $fileType: ${file.path}');
      },
    );
  },
  child: Icon(Icons.attach_file),
)
*/
