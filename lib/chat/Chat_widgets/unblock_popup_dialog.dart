import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

/// ✅ Unblock Popup Dialog Widget (Theme-aware)
class UnblockPopupDialog extends StatelessWidget {
  final String userName;
  final VoidCallback onUnblock;
  final VoidCallback onCancel;

  const UnblockPopupDialog({
    super.key,
    required this.userName,
    required this.onUnblock,
    required this.onCancel,
  });

  /// ✅ Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String userName,
    required VoidCallback onUnblock,
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return UnblockPopupDialog(
          userName: userName,
          onUnblock: onUnblock,
          onCancel: onCancel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final warning = AppTheme.warningColor(theme);
    final primary = AppTheme.primaryAccent(theme);
    final textColor = AppTheme.textPrimary(theme);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 10,
      backgroundColor: AppTheme.surfaceColor(theme),

      title: Row(
        children: [
          Icon(Icons.block_flipped, color: warning, size: 28),
          const SizedBox(width: 12),
          Text(
            'User Blocked',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have blocked $userName.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary(theme),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Do you want to unblock them to send messages?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary(theme).withOpacity(0.9),
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel();
          },
          child: Text(
            'Cancel',
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUnblock();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            'Unblock',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
