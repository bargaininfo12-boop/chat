// v0.4-ws_message_handler · 2025-10-25T16:10 IST
// lib/chat/services/ws_message_handler.dart
//
// Typed, robust WsMessageHandler implementation.
// Expects WsClient from lib/chat/services/ws_client.dart

import 'dart:async';

import 'package:bargain/chat/Core%20Services/ws_client.dart';

typedef JsonMap = Map<String, dynamic>;

class WsMessageHandler {
  final WsClient wsClient;
  StreamSubscription? _sub;

  final StreamController<JsonMap> _messageNewController = StreamController.broadcast();
  final StreamController<JsonMap> _messageAckController = StreamController.broadcast();
  final StreamController<JsonMap> _presenceController = StreamController.broadcast();
  final StreamController<JsonMap> _typingController = StreamController.broadcast();
  final StreamController<JsonMap> _errorController = StreamController.broadcast();

  void Function(String msg)? logger;

  WsMessageHandler(this.wsClient, {this.logger});

  Stream<JsonMap> get messageNew => _messageNewController.stream;
  Stream<JsonMap> get messageAck => _messageAckController.stream;
  Stream<JsonMap> get presence => _presenceController.stream;
  Stream<JsonMap> get typing => _typingController.stream;
  Stream<JsonMap> get errors => _errorController.stream;

  void start() {
    _log('WsMessageHandler: start()');
    if (_sub != null) return;

    _sub = wsClient.events.listen(_onRawEvent, onError: (e, st) {
      _log('WsMessageHandler: ws error: $e');
      _errorController.add({'error': e.toString(), 'stack': st.toString()});
    }, onDone: () {
      _log('WsMessageHandler: ws done');
    });
  }

  Future<void> stop() async {
    _log('WsMessageHandler: stop()');
    await _sub?.cancel();
    _sub = null;
  }

  void _onRawEvent(dynamic raw) {
    if (raw == null || raw is! Map<String, dynamic>) {
      _log('WsMessageHandler: unexpected raw event type: ${raw.runtimeType}');
      return;
    }

    final evt = raw['event'] as String?;
    final data = raw['data'] as Map<String, dynamic>?;

    if (evt == null) {
      _log('WsMessageHandler: missing event field in raw: $raw');
      return;
    }

    switch (evt) {
      case 'message.new':
        _handleMessageNew(data);
        break;
      case 'message.ack':
        _handleMessageAck(data);
        break;
      case 'presence.update':
        _handlePresence(data);
        break;
      case 'typing.start':
      case 'typing.stop':
        _handleTyping(evt, data);
        break;
      case 'error':
        _handleServerError(data);
        break;
      default:
        _log('WsMessageHandler: unhandled event "$evt" — forwarding to errors');
        _errorController.add({'event': evt, 'data': data});
    }
  }

  void _handleMessageNew(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('serverId') || !data.containsKey('conversationId')) {
      _log('WsMessageHandler: message.new missing serverId/conversationId');
      _errorController.add({'event': 'message.new', 'data': data});
      return;
    }

    final normalized = <String, dynamic>{
      'serverId': data['serverId'],
      'conversationId': data['conversationId'],
      'senderId': data['senderId'],
      'text': data['text'],
      'cdnUrl': data['cdnUrl'],
      'thumbUrl': data['thumbUrl'],
      'contentType': data['contentType'],
      'meta': data['meta'] ?? {},
      'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
      'raw': data,
    };

    _messageNewController.add(normalized);
  }

  void _handleMessageAck(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('tempId')) {
      _log('WsMessageHandler: message.ack missing tempId');
      _errorController.add({'event': 'message.ack', 'data': data});
      return;
    }

    final ack = <String, dynamic>{
      'tempId': data['tempId'],
      'serverId': data['serverId'],
      'status': data['status'] ?? 'sent',
      'raw': data,
    };

    _messageAckController.add(ack);
  }

  void _handlePresence(Map<String, dynamic>? data) {
    if (data == null) {
      _log('WsMessageHandler: presence.update null data');
      return;
    }
    final presence = <String, dynamic>{
      'userId': data['userId'],
      'status': data['status'],
      'lastSeen': data['lastSeen'],
      'conversationId': data['conversationId'],
      'raw': data,
    };
    _presenceController.add(presence);
  }

  void _handleTyping(String evt, Map<String, dynamic>? data) {
    if (data == null) {
      _log('WsMessageHandler: typing event null data');
      return;
    }
    final typing = <String, dynamic>{
      'userId': data['userId'],
      'conversationId': data['conversationId'],
      'type': evt == 'typing.start' ? 'start' : 'stop',
      'raw': data,
    };
    _typingController.add(typing);
  }

  void _handleServerError(Map<String, dynamic>? data) {
    _log('WsMessageHandler: server error event: $data');
    _errorController.add({'event': 'server.error', 'data': data});
  }

  Future<void> sendEvent(String event, Map<String, dynamic> data) async {
    try {
      await wsClient.sendEvent(event, data);
    } catch (e) {
      _log('WsMessageHandler: failed to sendEvent: $e');
    }
  }

  void _log(String msg) {
    if (logger != null) {
      logger!(msg);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _messageNewController.close();
    await _messageAckController.close();
    await _presenceController.close();
    await _typingController.close();
    await _errorController.close();
  }
}
