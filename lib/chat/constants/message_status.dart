// v0.4-message_status · 2025-10-25T10:45 IST
// message_status.dart
//
// Unified enum for all message delivery/upload states
// used by MessageRepository, ChatBloc, WsAckHandler, and ChatService.
//
// Includes DB helpers for storing as strings in SQLite.

enum MessageStatus {
  /// 🕓 Message created locally, not yet confirmed by server
  SentOptimistic,

  /// ✅ Successfully sent to server but not yet delivered
  Sent,

  /// 📬 Delivered to recipient device
  Delivered,

  /// 👁️  Recipient has read the message
  Read,

  /// ⬆️ Upload (image/video/file) currently in progress
  Uploading,

  /// ❌ Upload or send failed permanently
  Failed,
}

extension MessageStatusExtension on MessageStatus {
  /// Convert enum to short DB string
  String toDb() {
    switch (this) {
      case MessageStatus.SentOptimistic:
        return 'sent_optimistic';
      case MessageStatus.Sent:
        return 'sent';
      case MessageStatus.Delivered:
        return 'delivered';
      case MessageStatus.Read:
        return 'read';
      case MessageStatus.Uploading:
        return 'uploading';
      case MessageStatus.Failed:
        return 'failed';
    }
  }

  /// Emoji + text for debugging/logging
  String toEmoji() {
    switch (this) {
      case MessageStatus.SentOptimistic:
        return '🕓 Pending';
      case MessageStatus.Sent:
        return '✅ Sent';
      case MessageStatus.Delivered:
        return '📬 Delivered';
      case MessageStatus.Read:
        return '👁️ Read';
      case MessageStatus.Uploading:
        return '⬆️ Uploading';
      case MessageStatus.Failed:
        return '❌ Failed';
    }
  }

  /// Parse from stored string (safe fallback)
  static MessageStatus fromDb(String? value) {
    switch (value) {
      case 'sent':
        return MessageStatus.Sent;
      case 'sent_optimistic':
        return MessageStatus.SentOptimistic;
      case 'delivered':
        return MessageStatus.Delivered;
      case 'read':
        return MessageStatus.Read;
      case 'uploading':
        return MessageStatus.Uploading;
      case 'failed':
        return MessageStatus.Failed;
      default:
        return MessageStatus.SentOptimistic;
    }
  }
}
