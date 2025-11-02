import 'package:flutter/foundation.dart';


enum MediaType {
  image,
  video,
  audio,
}

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final DateTime timestamp;
  final MessageStatus status;


  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    required this.timestamp,
    required this.status,
  });

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    MessageStatus? status,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: this.conversationId,
      senderId: this.senderId,
      receiverId: this.receiverId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  /// Convert to Map for SQLite or Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
    };
  }

  /// Create from Map (e.g., from SQLite or Firestore)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      conversationId: map['conversationId'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      audioUrl: map['audioUrl'],
      timestamp: DateTime.parse(map['timestamp']),
      status: MessageStatus.values[map['status'] ?? 0],
    );
  }

  /// Optional: for debugging
  @override
  String toString() {
    return 'ChatMessage(id: $id, text: $text, image: $imageUrl, video: $videoUrl, audio: $audioUrl, status: $status)';
  }
}
