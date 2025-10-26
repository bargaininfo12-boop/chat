// v1.1-message_model · 2025-10-26T02:04 IST
// lib/chat/model/message_model.dart
//
// Corrected MessageModel (removed const constructor to avoid "Invalid constant value")
// - DB-compatible (toDbMap / fromDbMap) using ISO timestamps
// - Network JSON (toJson / fromJson) for WS / HTTP payloads
// - Uses MessageStatus enum for status conversions
// - copyWith() for immutability convenience
//
// Note: Keep fields final, constructor non-const so runtime values (db/network) work fine.

import 'dart:convert';

import '../constants/message_status.dart';

class MessageModel {
  final String? tempId; // local temp id (e.g. "local-xxxx" or "tmp_123")
  final String? serverId; // server assigned id (nullable until acked)
  final String conversationId;
  final String senderId;

  final String? text; // text body (nullable for media-only messages)
  final String contentType; // 'text' | 'image' | 'video' | 'audio' | 'file'
  final String? cdnUrl; // public CDN URL (after upload)
  final String? thumbUrl; // optional thumbnail or transform URL
  final String? localPath; // local filesystem path for outgoing / cached file
  final int? size; // optional file size in bytes

  final Map<String, dynamic>? meta; // arbitrary metadata (kept structured)

  final int uploadProgress; // 0..100
  final MessageStatus status; // MessageStatus enum

  final DateTime createdAt;
  final DateTime updatedAt;

  // Non-const constructor (fixes invalid constant value issues)
  MessageModel({
    required this.tempId,
    required this.serverId,
    required this.conversationId,
    required this.senderId,
    this.text,
    this.contentType = 'text',
    this.cdnUrl,
    this.thumbUrl,
    this.localPath,
    this.size,
    this.meta,
    this.uploadProgress = 0,
    this.status = MessageStatus.SentOptimistic,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  // ---------- Factory / parsing helpers ----------

  /// Build from DB row (Map<String,dynamic>) — expects createdAt/updatedAt stored as ISO strings.
  factory MessageModel.fromDbMap(Map<String, dynamic> m) {
    String? readString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    DateTime parseIso(dynamic v) {
      if (v == null) return DateTime.now().toUtc();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v).toUtc();
      if (v is String) {
        try {
          return DateTime.parse(v).toUtc();
        } catch (_) {
          return DateTime.now().toUtc();
        }
      }
      return DateTime.now().toUtc();
    }

    Map<String, dynamic>? parseMeta(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
      if (v is String) {
        try {
          final parsed = jsonDecode(v);
          if (parsed is Map) return Map<String, dynamic>.from(parsed);
        } catch (_) {}
      }
      return null;
    }

    final statusStr = (m['status'] as String?) ?? '';
    return MessageModel(
      tempId: readString(m['tempId']),
      serverId: readString(m['serverId']),
      conversationId: (m['conversationId'] as String?) ?? '',
      senderId: (m['senderId'] as String?) ?? '',
      text: readString(m['text']),
      contentType: (m['contentType'] as String?) ?? 'text',
      cdnUrl: readString(m['cdnUrl']),
      thumbUrl: readString(m['thumbUrl']),
      localPath: readString(m['localPath']),
      size: m['size'] is int ? m['size'] as int : (m['size'] != null ? int.tryParse(m['size'].toString()) : null),
      meta: parseMeta(m['meta']),
      uploadProgress: m['uploadProgress'] is int ? (m['uploadProgress'] as int).clamp(0, 100) : 0,
      status: MessageStatusExtension.fromDb(statusStr),
      createdAt: parseIso(m['createdAt']),
      updatedAt: parseIso(m['updatedAt']),
    );
  }

  /// Convert to DB map for insert/update (stores meta as JSON string)
  Map<String, dynamic> toDbMap() {
    String? metaStr;
    try {
      if (meta != null) metaStr = jsonEncode(meta);
    } catch (_) {
      metaStr = meta?.toString();
    }

    return {
      'tempId': tempId,
      'serverId': serverId,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'contentType': contentType,
      'cdnUrl': cdnUrl,
      'thumbUrl': thumbUrl,
      'localPath': localPath,
      'size': size,
      'meta': metaStr,
      'uploadProgress': uploadProgress.clamp(0, 100),
      'status': status.toDb(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ---------- Network (JSON) serialization ----------
  /// Build from network JSON (server payload or API)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.now().toUtc();
      if (v is int) {
        // treat as milliseconds if large, else seconds
        if (v < 4102444800) {
          return DateTime.fromMillisecondsSinceEpoch(v * 1000).toUtc();
        }
        return DateTime.fromMillisecondsSinceEpoch(v).toUtc();
      }
      if (v is String) {
        try {
          return DateTime.parse(v).toUtc();
        } catch (_) {
          return DateTime.now().toUtc();
        }
      }
      return DateTime.now().toUtc();
    }

    Map<String, dynamic>? meta;
    if (json['meta'] is Map) meta = Map<String, dynamic>.from(json['meta'] as Map);
    return MessageModel(
      tempId: (json['tempId'] as String?) ?? (json['localTempId'] as String?),
      serverId: (json['serverId'] as String?),
      conversationId: (json['conversationId'] as String?) ?? '',
      senderId: (json['senderId'] as String?) ?? '',
      text: (json['text'] as String?),
      contentType: (json['contentType'] as String?) ?? 'text',
      cdnUrl: (json['cdnUrl'] as String?),
      thumbUrl: (json['thumbUrl'] as String?),
      localPath: (json['localPath'] as String?),
      size: json['size'] is int ? json['size'] as int : (json['size'] != null ? int.tryParse(json['size'].toString()) : null),
      meta: meta,
      uploadProgress: json['uploadProgress'] is int ? (json['uploadProgress'] as int).clamp(0, 100) : 0,
      status: MessageStatusExtension.fromDb(json['status'] as String?),
      createdAt: parseTs(json['createdAt']),
      updatedAt: parseTs(json['updatedAt']),
    );
  }

  /// Convert to JSON suitable for WS/HTTP (uses ISO timestamps)
  Map<String, dynamic> toJson() {
    return {
      'tempId': tempId,
      'serverId': serverId,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'contentType': contentType,
      'cdnUrl': cdnUrl,
      'thumbUrl': thumbUrl,
      'localPath': localPath,
      'size': size,
      'meta': meta,
      'uploadProgress': uploadProgress,
      'status': status.toDb(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ---------- Utilities ----------
  MessageModel copyWith({
    String? tempId,
    String? serverId,
    String? conversationId,
    String? senderId,
    String? text,
    String? contentType,
    String? cdnUrl,
    String? thumbUrl,
    String? localPath,
    int? size,
    Map<String, dynamic>? meta,
    int? uploadProgress,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      tempId: tempId ?? this.tempId,
      serverId: serverId ?? this.serverId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      contentType: contentType ?? this.contentType,
      cdnUrl: cdnUrl ?? this.cdnUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      localPath: localPath ?? this.localPath,
      size: size ?? this.size,
      meta: meta ?? this.meta,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convenience: create optimistic local message before send
  static MessageModel optimisticText({
    required String tempId,
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    final now = DateTime.now().toUtc();
    return MessageModel(
      tempId: tempId,
      serverId: null,
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      contentType: 'text',
      cdnUrl: null,
      thumbUrl: null,
      localPath: null,
      size: null,
      meta: null,
      uploadProgress: 100,
      status: MessageStatus.SentOptimistic,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convenience: create optimistic media placeholder (upload in progress)
  static MessageModel optimisticMedia({
    required String tempId,
    required String conversationId,
    required String senderId,
    required String localPath,
    required String contentType,
    int? sizeBytes,
  }) {
    final now = DateTime.now().toUtc();
    return MessageModel(
      tempId: tempId,
      serverId: null,
      conversationId: conversationId,
      senderId: senderId,
      text: null,
      contentType: contentType,
      cdnUrl: null,
      thumbUrl: null,
      localPath: localPath,
      size: sizeBytes,
      meta: null,
      uploadProgress: 0,
      status: MessageStatus.Uploading,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() {
    return 'MessageModel(tempId: $tempId, serverId: $serverId, conv: $conversationId, sender: $senderId, type: $contentType, status: ${status.toDb()}, progress: $uploadProgress)';
  }
}
