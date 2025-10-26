import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  String id; // Make 'id' non-final
  final String name;
  final String? photoUrl; // Allow null for photoUrl
  final bool isOnline;
  final DateTime lastSeen;
  final String? lastMessage;

  // ✅ NEW: Notification related fields
  final String? fcmToken; // Firebase Cloud Messaging token
  final String? activeConversationId; // Currently active chat (for smart notifications)

  ChatUser({
    required this.id,
    required this.name,
    this.photoUrl, // Allow null for photoUrl
    required this.isOnline,
    required this.lastSeen,
    this.lastMessage,
    this.fcmToken, // NEW
    this.activeConversationId, // NEW
  });

  // ✅ Updated Factory constructor with notification fields
  factory ChatUser.fromFirestore(
      Map<String, dynamic> data,
      String receiverId, {
        String? lastMessage,
      }) {
    return ChatUser(
      id: receiverId,
      name: data['name'] ?? 'Unknown',
      photoUrl: data['photoURL'] as String?, // Use 'photoURL' instead of 'customPhotoUrl'
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: lastMessage,
      fcmToken: data['fcmToken'] as String?, // NEW
      activeConversationId: data['activeConversationId'] as String?, // NEW
    );
  }

  // ✅ Updated copyWith method with new fields
  ChatUser copyWith({
    String? id,
    String? name,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? lastMessage,
    String? fcmToken, // NEW
    String? activeConversationId, // NEW
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      lastMessage: lastMessage ?? this.lastMessage,
      fcmToken: fcmToken ?? this.fcmToken, // NEW
      activeConversationId: activeConversationId ?? this.activeConversationId, // NEW
    );
  }

  // ✅ Updated toFirestore method with new fields
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'lastMessage': lastMessage,
      'fcmToken': fcmToken, // NEW
      'activeConversationId': activeConversationId, // NEW
    };
  }

  // ✅ Additional helper methods for better functionality

  /// Get user initials for avatar fallback
  String getInitials() {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  /// Check if user has a valid photo URL
  bool get hasValidPhotoUrl {
    return photoUrl != null && photoUrl!.trim().isNotEmpty;
  }

  /// Get display name (formatted)
  String get displayName {
    if (name.isEmpty) return 'Unknown User';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  /// Check if user was recently online (within last 5 minutes)
  bool get wasRecentlyOnline {
    if (isOnline) return true;
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes <= 5;
  }

  /// Get formatted last seen text
  String getLastSeenText() {
    if (isOnline) return 'Online';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Long time ago';
    }
  }

  // ✅ NEW: Notification related helper methods

  /// Check if user can receive notifications
  bool get canReceiveNotifications {
    return fcmToken != null && fcmToken!.trim().isNotEmpty;
  }

  /// Check if user is currently in a specific chat
  bool isActiveInChat(String conversationId) {
    return activeConversationId == conversationId;
  }

  /// Get notification display text based on message type
  String getNotificationText(String messageType, String messageContent) {
    switch (messageType) {
      case 'text':
        return messageContent;
      case 'image':
        return '📷 Sent an image';
      case 'video':
        return '🎬 Sent a video';
      case 'audio':
        return '🎤 Sent a voice message';
      default:
        return 'Sent a message';
    }
  }

  /// Create a ChatUser instance for unknown/fallback users
  factory ChatUser.unknown(String userId) {
    return ChatUser(
      id: userId,
      name: 'Unknown User',
      photoUrl: null,
      isOnline: false,
      lastSeen: DateTime.now(),
      lastMessage: null,
      fcmToken: null, // NEW
      activeConversationId: null, // NEW
    );
  }

  /// Create a ChatUser instance from minimal data
  factory ChatUser.minimal({
    required String id,
    required String name,
    String? photoUrl,
    String? fcmToken, // NEW
  }) {
    return ChatUser(
      id: id,
      name: name,
      photoUrl: photoUrl,
      isOnline: false,
      lastSeen: DateTime.now(),
      lastMessage: null,
      fcmToken: fcmToken, // NEW
      activeConversationId: null, // NEW
    );
  }

  // ✅ Equality and hashCode for proper object comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChatUser &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  // ✅ Updated toString for debugging with new fields
  @override
  String toString() {
    return 'ChatUser{id: $id, name: $name, photoUrl: $photoUrl, isOnline: $isOnline, lastSeen: $lastSeen, lastMessage: $lastMessage, fcmToken: ${fcmToken?.substring(0, 10)}..., activeConversationId: $activeConversationId}';
  }
}
