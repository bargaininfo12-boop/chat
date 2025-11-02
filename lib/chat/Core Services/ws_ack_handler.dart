// lib/chat/services/ws_ack_handler.dart
// v2025-10-28 · WsAckHandler (streams + callback shim)
// - Exposes messageAck & messageNew streams
// - Provides setOnRemoteInsert / setOnAckForTemp for backward compat
// - Links to ChatDatabaseHelper to perform tempId->serverId linking

import 'dart:async';
import 'package:bargain/chat/Local%20Database%20Layer/chat_database_helper.dart';

typedef RemoteInsertCb = void Function(Map<String, dynamic> message);
typedef AckForTempCb = void Function(String tempId, String serverId);

class WsAckHandler {
  final dynamic wsMessageHandler;
  final ChatDatabaseHelper localDb;

  RemoteInsertCb? _onRemoteInsert;
  AckForTempCb? _onAckForTemp;

  StreamSubscription? _ackSub;
  StreamSubscription? _newSub;

  final StreamController<Map<String, dynamic>> _ackController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _newController = StreamController.broadcast();

  WsAckHandler(
      this.wsMessageHandler,
      this.localDb, {
        RemoteInsertCb? onRemoteInsert,
        AckForTempCb? onAckForTemp,
      }) {
    _onRemoteInsert = onRemoteInsert;
    _onAckForTemp = onAckForTemp;
  }

  void setOnRemoteInsert(RemoteInsertCb? cb) => _onRemoteInsert = cb;
  void setOnAckForTemp(AckForTempCb? cb) => _onAckForTemp = cb;

  Stream<Map<String, dynamic>> get messageAck => _ackController.stream;
  Stream<Map<String, dynamic>> get messageNew => _newController.stream;

  void start() {
    try {
      if (_ackSub == null) {
        final ackStream = _safeGetStream(wsMessageHandler, 'messageAck');
        if (ackStream != null) {
          _ackSub = ackStream.listen((m) async {
            try {
              await _handleAck(m);
              _ackController.add(m);
            } catch (_) {}
          });
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
              _newController.add(m);
            } catch (_) {}
          });
        }
      }
    } catch (_) {}
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

  Stream<Map<String, dynamic>>? _safeGetStream(dynamic obj, String propName) {
    try {
      final maybe = propName == 'messageAck' ? obj.messageAck : obj.messageNew;
      if (maybe is Stream<Map<String, dynamic>>) return maybe;
      if (maybe is Stream) return maybe.map((e) => e as Map<String, dynamic>);
    } catch (_) {}
    return null;
  }

  Future<void> _handleAck(Map<String, dynamic> ack) async {
    try {
      final tempId = (ack['tempId'] ?? ack['raw']?['tempId'])?.toString() ?? '';
      final serverId = (ack['serverId'] ?? ack['raw']?['serverId'])?.toString() ?? '';
      final statusRaw = ack['status'] ?? ack['raw']?['status'];

      if (tempId.isEmpty || serverId.isEmpty) return;

      try {
        await localDb.linkTempToServer(tempId, serverId);
      } catch (_) {}

      String statusStr = 'sent';
      try {
        if (statusRaw is String) statusStr = statusRaw.toLowerCase();
        else if (statusRaw is int) {
          if (statusRaw == 2) statusStr = 'delivered';
          if (statusRaw == 3) statusStr = 'read';
        }
      } catch (_) {}

      try {
        await localDb.updateMessageStatus(tempId, statusStr);
      } catch (_) {
        try {
          await localDb.updateMessageStatus(serverId, statusStr);
        } catch (_) {}
      }

      try {
        _onAckForTemp?.call(tempId, serverId);
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _handleMessageNew(Map<String, dynamic> raw) async {
    try {
      final serverId = (raw['serverId'] ?? raw['raw']?['serverId'] ?? raw['server_id'])?.toString() ?? '';
      final conversationId = (raw['conversationId'] ?? raw['raw']?['conversationId'] ?? raw['conversation_id'])?.toString() ?? '';

      if (serverId.isEmpty || conversationId.isEmpty) return;

      final existingByServer = await localDb.getMessageByServerId(serverId);
      if (existingByServer != null) {
        final needsUpdate = (existingByServer['cdnUrl'] == null || (existingByServer['cdnUrl'] as String).isEmpty);
        if (needsUpdate) {
          final cdnUrl = raw['cdnUrl'] ?? raw['raw']?['cdnUrl'];
          final thumbUrl = raw['thumbUrl'] ?? raw['raw']?['thumbUrl'];
          final tempId = existingByServer['tempId'] as String? ?? '';
          try {
            await localDb.updateMessageAfterUpload(
              tempId: tempId,
              cdnUrl: cdnUrl,
              thumbUrl: thumbUrl,
              uploadProgress: 100,
            );
          } catch (_) {}
        }
        try {
          _onRemoteInsert?.call(raw);
        } catch (_) {}
        return;
      }

      final tempIdFromServer = (raw['tempId'] ?? raw['raw']?['tempId'])?.toString() ?? '';
      if (tempIdFromServer.isNotEmpty) {
        final existingByTemp = await localDb.getMessageByTempId(tempIdFromServer);
        if (existingByTemp != null) {
          try {
            await localDb.linkTempToServer(tempIdFromServer, serverId);
            await localDb.updateMessageAfterUpload(
              tempId: tempIdFromServer,
              cdnUrl: raw['cdnUrl'] ?? raw['raw']?['cdnUrl'],
              thumbUrl: raw['thumbUrl'] ?? raw['raw']?['thumbUrl'],
              uploadProgress: 100,
            );
          } catch (_) {}
          try {
            _onRemoteInsert?.call(raw);
          } catch (_) {}
          return;
        }
      }

      final newMsg = <String, dynamic>{
        'tempId': null,
        'serverId': serverId,
        'conversationId': conversationId,
        'senderId': raw['senderId'] ?? raw['raw']?['senderId'],
        'text': raw['text'] ?? raw['raw']?['text'],
        'contentType': raw['contentType'] ?? raw['raw']?['contentType'] ?? 'text',
        'cdnUrl': raw['cdnUrl'] ?? raw['raw']?['cdnUrl'],
        'thumbUrl': raw['thumbUrl'] ?? raw['raw']?['thumbUrl'],
        'localPath': null,
        'uploadProgress': 100,
        'status': 'sent',
        'createdAt': raw['createdAt'] ?? raw['raw']?['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        await localDb.saveMessage(newMsg);
      } catch (_) {}

      try {
        _onRemoteInsert?.call(newMsg);
      } catch (_) {}
    } catch (_) {}
  }
}
