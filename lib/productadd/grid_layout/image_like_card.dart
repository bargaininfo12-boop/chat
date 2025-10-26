import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

class ImageLikeCard extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onTap;
  final bool showCount;

  const ImageLikeCard({
    super.key,
    required this.isLiked,
    required this.likeCount,
    this.onTap,
    this.showCount = true,
  });

  /// Like count formatter (1K, 1.2M etc.)
  String _formatLikeCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      splashColor: AppTheme.rippleColor(theme),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ❤️ Like Icon
          Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 22,
            color: isLiked
                ? AppTheme.likeRed(theme) // 🔥 Theme-based red color
                : AppTheme.iconColor(theme).withOpacity(0.6),
          ),

          // 🧮 Like Count
          if (showCount) ...[
            const SizedBox(width: 4),
            Text(
              _formatLikeCount(likeCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary(theme),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
