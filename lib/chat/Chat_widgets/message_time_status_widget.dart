import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

class MessageTimeStatusWidget extends StatelessWidget {
  final String time;
  final int status;
  final bool isMe;
  final Color? textColor;
  final Color? iconColor;

  const MessageTimeStatusWidget({
    super.key,
    required this.time,
    required this.status,
    required this.isMe,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finalTextColor = textColor ?? AppTheme.customTimeTextColor(theme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Message Time
        Text(
          time,
          style: TextStyle(
            color: finalTextColor,
            fontSize: 11,
          ),
        ),

        // Status Icon (sirf bheje gaye message ke liye)
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(theme),
        ],
      ],
    );
  }

  // Single source of truth - only use status field
  Widget _buildStatusIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (status) {
      case -1: // failed
        icon = Icons.error_outline;
        color = AppTheme.customStatusIconFailed(theme);
        break;

      case 0: // sending/pending
        icon = Icons.access_time; // clock icon
        color = AppTheme.customStatusIconSent(theme);
        break;

      case 1: // sent to server
        icon = Icons.done; // single tick
        color = AppTheme.customStatusIconSent(theme);
        break;

      case 2: // delivered to peer
        icon = Icons.done_all; // double tick grey
        color = AppTheme.customStatusIconDelivered(theme);
        break;

      case 3: // read by peer (via read pointer)
        icon = Icons.done_all; // double tick blue
        color = AppTheme.customStatusIconRead(theme);
        break;

      default:
        icon = Icons.done;
        color = AppTheme.customStatusIconSent(theme);
    }

    // Use override color if provided
    final finalIconColor = iconColor ?? color;

    return Icon(icon, size: 16, color: finalIconColor);
  }
}
