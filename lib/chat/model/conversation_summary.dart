// lib/chat/model/conversation_summary.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one conversation preview tile in the chat list.
/// Includes last message info, peer details, and now also
/// peer deletion/suspension status.
class ConversationSummary {
  final String conversationId;
  final String peerId;

  final String? peerName;
  final String? peerPhoto;
  final bool isPeerOnline;
  final int? peerLastSeenMs;

  final int lastUpdated;
  final String lastMessageText;
  final String lastMessageType;
  final int lastMessageStatus;
  final String? lastMessageMediaUrl;

  /// ✅ NEW: indicates if the peer has deleted or suspended their account.
  final bool? isPeerDeleted;

  const ConversationSummary({
    required this.conversationId,
    required this.peerId,
    required this.lastUpdated,
    required this.lastMessageText,
    required this.lastMessageType,
    required this.lastMessageStatus,
    this.lastMessageMediaUrl,
    this.peerName,
    this.peerPhoto,
    this.isPeerOnline = false,
    this.peerLastSeenMs,
    this.isPeerDeleted = false, // ✅ default false
  });

  /// ✅ copyWith for easy immutability updates
  ConversationSummary copyWith({
    String? peerName,
    String? peerPhoto,
    bool? isPeerOnline,
    int? peerLastSeenMs,
    bool? isPeerDeleted,
  }) {
    return ConversationSummary(
      conversationId: conversationId,
      peerId: peerId,
      lastUpdated: lastUpdated,
      lastMessageText: lastMessageText,
      lastMessageType: lastMessageType,
      lastMessageStatus: lastMessageStatus,
      lastMessageMediaUrl: lastMessageMediaUrl,
      peerName: peerName ?? this.peerName,
      peerPhoto: peerPhoto ?? this.peerPhoto,
      isPeerOnline: isPeerOnline ?? this.isPeerOnline,
      peerLastSeenMs: peerLastSeenMs ?? this.peerLastSeenMs,
      isPeerDeleted: isPeerDeleted ?? this.isPeerDeleted,
    );
  }

  /// ✅ Factory for Firestore / map deserialization
  factory ConversationSummary.fromMap(Map<String, dynamic> data) {
    return ConversationSummary(
      conversationId: data['conversationId'] ?? '',
      peerId: data['peerId'] ?? '',
      peerName: data['peerName'],
      peerPhoto: data['peerPhoto'],
      isPeerOnline: data['isPeerOnline'] ?? false,
      peerLastSeenMs: _parseLastSeen(data['peerLastSeenMs']),
      lastUpdated: _parseTimestamp(data['lastUpdated']),
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageType: data['lastMessageType'] ?? 'text',
      lastMessageStatus: data['lastMessageStatus'] ?? 0,
      lastMessageMediaUrl: data['lastMessageMediaUrl'],
      isPeerDeleted: data['isDeleted'] ?? data['isPeerDeleted'] ?? false,
    );
  }

  /// ✅ Convert back to map (for updates or cache)
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'peerId': peerId,
      'peerName': peerName,
      'peerPhoto': peerPhoto,
      'isPeerOnline': isPeerOnline,
      'peerLastSeenMs': peerLastSeenMs,
      'lastUpdated': lastUpdated,
      'lastMessageText': lastMessageText,
      'lastMessageType': lastMessageType,
      'lastMessageStatus': lastMessageStatus,
      'lastMessageMediaUrl': lastMessageMediaUrl,
      'isPeerDeleted': isPeerDeleted,
    };
  }

  /// Helpers for safety
  static int _parseTimestamp(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }

  static int? _parseLastSeen(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return null;
  }
}
