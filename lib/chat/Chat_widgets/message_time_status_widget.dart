// v1.1-message_time_status_widget · 2025-10-26T17:30 IST
// lib/chat/widgets/message_time_status_widget.dart
//
// Updated: Better status icons, animations, improved styling
// Status values:
//  -1 = Failed
//   0 = Pending/Uploading
//   1 = Sent
//   2 = Delivered
//   3 = Read

import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

class MessageTimeStatusWidget extends StatelessWidget {
  final String time;
  final int status;
  final bool isMe;
  final Color? textColor;
  final Color? iconColor;
  final int? uploadProgress; // 0-100 for uploads
  final bool showTimestamp; // option to hide time in compact mode

  const MessageTimeStatusWidget({
    super.key,
    required this.time,
    required this.status,
    required this.isMe,
    this.textColor,
    this.iconColor,
    this.uploadProgress,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finalTextColor = textColor ?? AppTheme.customTimeTextColor(theme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Time
        if (showTimestamp)
          Text(
            time,
            style: TextStyle(
              color: finalTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

        // Status Icon (sirf isMe के लिए)
        if (isMe) ...[
          if (showTimestamp) const SizedBox(width: 4) else SizedBox.shrink(),
          _buildStatusIcon(theme),
        ],
      ],
    );
  }

  /// Build status icon with proper styling
  Widget _buildStatusIcon(ThemeData theme) {
    // Loading state - show progress indicator
    if (status == 0 && uploadProgress != null && uploadProgress! < 100) {
      return SizedBox(
        width: 16,
        height: 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: uploadProgress! / 100,
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(
                iconColor ?? AppTheme.customStatusIconSent(theme),
              ),
            ),
            Text(
              '${uploadProgress}%',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: iconColor ?? AppTheme.customStatusIconSent(theme),
              ),
            ),
          ],
        ),
      );
    }

    // Pending/Sending state
    if (status == 0) {
      return Icon(
        Icons.schedule,
        size: 14,
        color: iconColor ?? AppTheme.customStatusIconSent(theme),
      );
    }

    // Failed state
    if (status == -1) {
      return Tooltip(
        message: 'Failed to send',
        child: Icon(
          Icons.error_outline,
          size: 14,
          color: iconColor ?? AppTheme.customStatusIconFailed(theme),
        ),
      );
    }

    // Sent state (single tick)
    if (status == 1) {
      return Icon(
        Icons.check,
        size: 14,
        color: iconColor ?? AppTheme.customStatusIconSent(theme),
      );
    }

    // Delivered state (double tick grey)
    if (status == 2) {
      return Icon(
        Icons.done_all,
        size: 14,
        color: iconColor ?? AppTheme.customStatusIconDelivered(theme),
      );
    }

    // Read state (double tick blue)
    if (status == 3) {
      return Icon(
        Icons.done_all,
        size: 14,
        color: iconColor ?? AppTheme.customStatusIconRead(theme),
      );
    }

    // Default
    return Icon(
      Icons.done,
      size: 14,
      color: iconColor ?? AppTheme.customStatusIconSent(theme),
    );
  }

  /// Static helper to format time
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    // Time format
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    // Today
    if (msgDate == today) {
      return timeStr;
    }

    // Yesterday
    if (msgDate == yesterday) {
      return 'Yesterday $timeStr';
    }

    // Same year
    if (msgDate.year == now.year) {
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      return '$day/$month $timeStr';
    }

    // Different year
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day/$month/$year $timeStr';
  }

  /// Get status description
  static String getStatusDescription(int status) {
    switch (status) {
      case -1:
        return 'Failed';
      case 0:
        return 'Sending...';
      case 1:
        return 'Sent';
      case 2:
        return 'Delivered';
      case 3:
        return 'Read';
      default:
        return 'Unknown';
    }
  }

  /// Get status color
  static Color getStatusColor(int status, ThemeData theme) {
    switch (status) {
      case -1:
        return AppTheme.customStatusIconFailed(theme);
      case 0:
        return AppTheme.customStatusIconSent(theme);
      case 1:
        return AppTheme.customStatusIconSent(theme);
      case 2:
        return AppTheme.customStatusIconDelivered(theme);
      case 3:
        return AppTheme.customStatusIconRead(theme);
      default:
        return AppTheme.customStatusIconSent(theme);
    }
  }
}

// ============================================================================
// USAGE EXAMPLE
// ============================================================================

/// Example usage in a message bubble:
///
/// MessageTimeStatusWidget(
///   time: MessageTimeStatusWidget.formatTime(message.createdAt),
///   status: message.status, // -1, 0, 1, 2, 3
///   isMe: message.senderId == currentUserId,
///   uploadProgress: message.uploadProgress, // 0-100 (optional)
/// )
///
/// With custom colors:
///
/// MessageTimeStatusWidget(
///   time: MessageTimeStatusWidget.formatTime(message.createdAt),
///   status: message.status,
///   isMe: true,
///   textColor: Colors.white70,
///   iconColor: Colors.greenAccent,
/// )