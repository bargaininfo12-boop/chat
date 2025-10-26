// v0.5-ws_ack_handler · 2025-10-25T21:05 IST
// ws_ack_handler.dart
//
// Updated: expose `messageAck` and `messageNew` streams (Stream getters) so consumers
// can subscribe directly (e.g., ChatScreen). Kept existing callback setters
// setOnRemoteInsert / setOnAckForTemp for backward compatibility.
// Added dispose() and defensive subscribe logic.

import 'dart:async';

import 'package:bargain/chat/services/chat_database_helper.dart';
import 'package:bargain/chat/constants/message_status.dart';

class WsAckHandler {
  final dynamic wsMessageHandler; // WsMessageHandler instance (keep dynamic to avoid tight coupling)
  final ChatDatabaseHelper localDb;

  // Internal callbacks (nullable)
  void Function(Map<String, dynamic> message)? _onRemoteInsert;
  void Function(String tempId, String serverId)? _onAckForTemp;

  StreamSubscription? _ackSub;
  StreamSubscription? _newSub;

  // Exposed streams for external subscribers
  final StreamController<Map<String, dynamic>> _ackController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _newController = StreamController.broadcast();

  WsAckHandler(
      this.wsMessageHandler,
      this.localDb, {
        void Function(Map<String, dynamic> message)? onRemoteInsert,
        void Function(String tempId, String serverId)? onAckForTemp,
      }) {
    _onRemoteInsert = onRemoteInsert;
    _onAckForTemp = onAckForTemp;
  }

  /// Allow later registration (non-breaking)
  void setOnRemoteInsert(void Function(Map<String, dynamic> message)? cb) {
    _onRemoteInsert = cb;
  }

  void setOnAckForTemp(void Function(String tempId, String serverId)? cb) {
    _onAckForTemp = cb;
  }

  /// Streams exposed for consumers
  Stream<Map<String, dynamic>> get messageAck => _ackController.stream;
  Stream<Map<String, dynamic>> get messageNew => _newController.stream;

  /// Start listening to ws events
  void start() {
    // expecting wsMessageHandler to expose Streams named messageAck and messageNew
    try {
      if (_ackSub == null) {
        final ackStream = _safeGetStream(wsMessageHandler, 'messageAck');
        if (ackStream != null) {
          _ackSub = ackStream.listen((m) async {
            try {
              await _handleAck(m);
              // forward to external subscribers
              _ackController.add(m);
            } catch (_) {}
          }, onError: (e) {});
        }
      }
    } catch (_) {}

    try {
      if (_newSub == null) {
        final newStream = _safeGetStream(wsMessageHandler, 'messageNew');
        if (newStream != null) {
          _newSub = newStream.listen((m) async {
            try {
              await _handleMessageNew(m);
              // forward to external subscribers
              _newController.add(m);
            } catch (_) {}
          }, onError: (e) {});
        }
      }
    } catch (_) {}
  }

  /// Safely extract a stream from a handler via reflection-like access.
  /// Returns null if the property isn't present or isn't a Stream.
  Stream<Map<String, dynamic>>? _safeGetStream(dynamic obj, String propName) {
    try {
      final dynamic value = obj == null ? null : obj.__proto__ == null ? null : null;
      // The above is intentionally a no-op fallback to avoid real reflection.
      // Prefer direct property access via known API:
      try {
        final maybe = propName == 'messageAck' ? obj.messageAck : obj.messageNew;
        if (maybe is Stream<Map<String,dynamic>>) return maybe;
        if (maybe is Stream) return maybe.map((e) => e as Map<String,dynamic>);
      } catch (_) { /* property not found */ }
    } catch (_) {}
    return null;
  }

  Future<void> stop() async {
    try {
      await _ackSub?.cancel();
    } catch (_) {}
    _ackSub = null;
    try {
      await _newSub?.cancel();
    } catch (_) {}
    _newSub = null;
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _ackController.close();
    } catch (_) {}
    try {
      await _newController.close();
    } catch (_) {}
  }

  Future<void> _handleAck(Map<String, dynamic> ack) async {
    try {
      final tempId = ack['tempId'] as String?;
      final serverId = ack['serverId'] as String?;
      final statusRaw = ack['status'];
      String statusStr = 'sent';
      if (statusRaw is String) statusStr = statusRaw;
      else if (statusRaw is int) {
        // optional numeric mapping if server uses ints
        if (statusRaw == 2) statusStr = 'delivered';
        if (statusRaw == 3) statusStr = 'read';
      }

      if (tempId == null || tempId.isEmpty) return;

      // Update local DB: set serverId and status appropriately
      if (serverId != null && serverId.isNotEmpty) {
        await localDb.updateMessageServerId(tempId, serverId);
      }

      if (statusStr == 'delivered') {
        await localDb.updateMessageStatus(tempId, MessageStatus.Delivered);
      } else if (statusStr == 'read') {
        await localDb.updateMessageStatus(tempId, MessageStatus.Read);
      } else {
        await localDb.updateMessageStatus(tempId, MessageStatus.Sent);
      }

      // Callback
      _onAckForTemp?.call(tempId, serverId ?? '');
    } catch (e) {
      // swallow but could log
    }
  }

  Future<void> _handleMessageNew(Map<String, dynamic> raw) async {
    try {
      final serverId = raw['serverId'] as String?;
      final conversationId = raw['conversationId'] as String?;
      final senderId = raw['senderId'] as String?;
      final text = raw['text'] as String?;
      final cdnUrl = raw['cdnUrl'] as String?;
      final thumbUrl = raw['thumbUrl'] as String?;
      final contentType = raw['contentType'] as String? ?? 'text';
      final createdAt = raw['createdAt'] as String? ?? DateTime.now().toUtc().toIso8601String();
      final rawMap = raw['raw'] as Map<String, dynamic>? ?? raw;

      if (serverId == null || conversationId == null) return;

      final existingByServer = await localDb.getMessageByServerId(serverId);
      if (existingByServer != null) {
        final needsUpdate = (existingByServer['cdnUrl'] == null || existingByServer['cdnUrl'] == '');
        if (needsUpdate) {
          final tempId = existingByServer['tempId'] as String? ?? '';
          await localDb.updateMessageAfterUpload(
            tempId: tempId,
            cdnUrl: cdnUrl ?? existingByServer['cdnUrl'],
            thumbUrl: thumbUrl ?? existingByServer['thumbUrl'],
            uploadProgress: 100,
          );
          if (tempId.isNotEmpty) {
            await localDb.updateMessageServerId(tempId, serverId);
          }
        }
        return;
      }

      final tempIdFromServer = rawMap['tempId'] as String?;
      if (tempIdFromServer != null) {
        final existingByTemp = await localDb.getMessageByTempId(tempIdFromServer);
        if (existingByTemp != null) {
          await localDb.updateMessageServerId(tempIdFromServer, serverId);
          await localDb.updateMessageAfterUpload(
            tempId: tempIdFromServer,
            cdnUrl: cdnUrl ?? existingByTemp['cdnUrl'],
            thumbUrl: thumbUrl ?? existingByTemp['thumbUrl'],
            uploadProgress: 100,
          );
          // invoke remote insert callback to update UI if desired
          final payload = {
            'tempId': tempIdFromServer,
            'serverId': serverId,
            'conversationId': conversationId,
            'senderId': senderId,
            'text': text,
            'contentType': contentType,
            'cdnUrl': cdnUrl,
            'thumbUrl': thumbUrl,
            'createdAt': createdAt
          };
          _onRemoteInsert?.call(payload);
          return;
        }
      }

      // Insert new remote message
      final newMsg = <String, dynamic>{
        'tempId': null,
        'serverId': serverId,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'contentType': contentType,
        'cdnUrl': cdnUrl,
        'thumbUrl': thumbUrl,
        'localPath': null,
        'uploadProgress': 100,
        'status': 'sent',
        'createdAt': createdAt,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      await localDb.saveMessage(newMsg);
      _onRemoteInsert?.call(newMsg);
    } catch (e) {
      // ignore/log
    }
  }
}
