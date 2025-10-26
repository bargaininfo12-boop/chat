import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

/// ✅ A consistent, reusable AppBar for sections/pages
/// Used in: Settings, ChatList, Profile, MyAds, etc.
class SectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? trailing; // ✅ Added: optional trailing widget
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const SectionAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.trailing,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.5,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? AppTheme.appBarBackground(theme);
    final fgColor = foregroundColor ?? AppTheme.iconColor(theme);

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.dividerColor(theme),
                width: 0.4,
              ),
            ),
            boxShadow: elevation > 0
                ? [
              BoxShadow(
                color: AppTheme.shadowColor(theme).withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: SizedBox(
            height: preferredSize.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Back Button (if any) ---
                if (onBack != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: fgColor,
                    onPressed: onBack,
                  )
                else
                  const SizedBox(width: 16),

                // --- Title (Centered) ---
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary(theme),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                // --- Trailing Widget or Actions ---
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: trailing,
                  )
                else if (actions != null && actions!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
                else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
