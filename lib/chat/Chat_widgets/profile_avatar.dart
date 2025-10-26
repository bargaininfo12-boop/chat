import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bargain/app_theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final bool desaturate;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.isOnline = false,
    this.desaturate = false,
  });

  // --------- Chat List item avatar ----------
  static Widget chatListItem({
    required String? imageUrl,
    required String name,
    required String userId,
    VoidCallback? onTap,
    bool isOnline = false,
    bool desaturate = false,
    double size = 48,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _AvatarBubble(
        imageUrl: imageUrl,
        initials: _initials(name),
        size: size,
        isOnline: isOnline,
        desaturate: desaturate,
      ),
    );
  }

  // --------- Chat Screen AppBar avatar ----------
  static Widget chatScreenAppBar({
    required String? imageUrl,
    required String name,
    required String userId,
    required ThemeData theme,
    bool isOnline = false,
    double size = 36,
  }) {
    return _AvatarBubble(
      imageUrl: imageUrl,
      initials: _initials(name),
      size: size,
      isOnline: isOnline,
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
        parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _AvatarBubble(
      imageUrl: imageUrl,
      initials: _initials(name),
      size: size,
      isOnline: isOnline,
      desaturate: desaturate,
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final bool isOnline;
  final bool desaturate;

  const _AvatarBubble({
    required this.imageUrl,
    required this.initials,
    required this.size,
    required this.isOnline,
    this.desaturate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Stack(
      children: [
        // Main avatar circle
        CircleAvatar(
          radius: size / 2,
          backgroundColor: AppTheme.surfaceColor(theme),
          child: hasImage
              ? ClipOval(
            child: desaturate
                ? ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.grey,
                BlendMode.saturation,
              ),
              child: _cachedImage(theme),
            )
                : _cachedImage(theme),
          )
              : _initialsWidget(theme),
        ),

        // Online/Offline status dot
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.26,
            height: size * 0.26,
            decoration: BoxDecoration(
              color: isOnline
                  ? AppTheme.successColor(theme)
                  : AppTheme.textSecondary(theme).withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.surfaceColor(theme),
                width: size * 0.06,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cachedImage(ThemeData theme) {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => _initialsWidget(theme),
      errorWidget: (context, url, error) {
        debugPrint("⚠️ Profile image load failed: $error");
        return _fallbackAvatar(theme);
      },
    );
  }

  Widget _initialsWidget(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.surfaceColor(theme),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
          color: AppTheme.textPrimary(theme),
        ),
      ),
    );
  }

  Widget _fallbackAvatar(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.surfaceColor(theme),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: AppTheme.textSecondary(theme),
      ),
    );
  }
}
