// v1.0-ws_client.dart · 2025-10-25T15:45 IST
// lib/chat/services/ws_client.dart
//
// WsClient: lightweight WebSocket wrapper for app realtime messaging.
// - Accepts Uri endpoint (type-safe)
// - Uses tokenProvider to attach auth token to connection (query param `access_token`)
// - Emits parsed event envelopes { event: String, data: Map<String,dynamic> }
// - reconnects with exponential backoff
// - supports sendEvent(event, data)
// - connectionChanges stream emits true/false

import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef TokenProvider = Future<String> Function();

class WsClient {
  final Uri endpoint;
  final TokenProvider? tokenProvider;
  final Duration connectTimeout;
  final Duration pingInterval;
  final int maxReconnectAttempts;
  final Duration initialReconnectDelay;

  WebSocket? _socket;
  bool _closing = false;
  int _reconnectAttempts = 0;
  Timer? _pingTimer;

  final StreamController<Map<String, dynamic>> _eventsController = StreamController.broadcast();
  final StreamController<bool> _connController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  Stream<bool> get connectionChanges => _connController.stream;

  WsClient(
      this.endpoint, {
        this.tokenProvider,
        this.connectTimeout = const Duration(seconds: 15),
        this.pingInterval = const Duration(seconds: 20),
        this.maxReconnectAttempts = 8,
        this.initialReconnectDelay = const Duration(seconds: 1),
      });

  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  Future<void> connect() async {
    _closing = false;
    await _attemptConnect();
  }

  Future<void> _attemptConnect() async {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _connController.add(true);
      return;
    }

    try {
      final token = (tokenProvider != null) ? (await tokenProvider!()) : '';
      final connUri = _withAuthToken(endpoint, token);

      final ws = await WebSocket.connect(
        connUri.toString(),
        headers: {
          'User-Agent': 'BargainApp/1.0',
        },
      ).timeout(connectTimeout);

      _attachSocket(ws);
      _reconnectAttempts = 0;
      _connController.add(true);
    } catch (e) {
      _connController.add(false);
      _reconnectAttempts++;
      if (_reconnectAttempts <= maxReconnectAttempts && !_closing) {
        final delay = _computeBackoff(_reconnectAttempts);
        Future.delayed(delay, () {
          if (!_closing) _attemptConnect();
        });
      }
    }
  }

  Uri _withAuthToken(Uri base, String token) {
    if (token.isEmpty) return base;
    final existing = Map<String, String>.from(base.queryParameters);
    existing['access_token'] = token;
    return base.replace(queryParameters: existing);
  }

  Duration _computeBackoff(int attempt) {
    final int ms = (initialReconnectDelay.inMilliseconds * (1 << (attempt - 1)));
    final jitter = (ms * 0.25).toInt();
    final rand = DateTime.now().millisecondsSinceEpoch % (jitter + 1);
    final totalMs = ms + rand;
    final cappedMs = totalMs.clamp(initialReconnectDelay.inMilliseconds, 30000);
    return Duration(milliseconds: cappedMs);
  }

  void _attachSocket(WebSocket ws) {
    _detachSocket();
    _socket = ws;
    _socket!.pingInterval = pingInterval;

    _socket!.listen((dynamic raw) {
      _handleRawMessage(raw);
    }, onError: (err) {
      _eventsController.add({'event': 'error', 'data': {'error': err.toString()}});
      _scheduleReconnect();
    }, onDone: () {
      _eventsController.add({'event': 'closed', 'data': {}});
      _connController.add(false);
      _scheduleReconnect();
    }, cancelOnError: true);

    _startPingTimer();
  }

  void _detachSocket() {
    try {
      _pingTimer?.cancel();
    } catch (_) {}
    _pingTimer = null;

    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void _startPingTimer() {
    try {
      _pingTimer?.cancel();
    } catch (_) {}
    _pingTimer = Timer.periodic(pingInterval, (_) {
      try {
        if (_socket != null && _socket!.readyState == WebSocket.open) {
          _socket!.add(jsonEncode({'event': 'ping', 'data': {}}));
        }
      } catch (_) {}
    });
  }

  void _handleRawMessage(dynamic raw) {
    if (raw == null) return;
    try {
      if (raw is String) {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          final envelope = <String, dynamic>{};
          envelope['event'] = parsed['event'] ?? parsed['type'] ?? 'message';
          envelope['data'] = parsed['data'] ?? parsed['payload'] ?? {};
          _eventsController.add(envelope);
        } else {
          _eventsController.add({'event': 'message.raw', 'data': {'value': parsed}});
        }
      } else if (raw is List<int>) {
        final s = utf8.decode(raw);
        final parsed = jsonDecode(s);
        if (parsed is Map<String, dynamic>) {
          _eventsController.add({'event': parsed['event'] ?? 'message', 'data': parsed['data'] ?? {}});
        } else {
          _eventsController.add({'event': 'message.binary', 'data': {'value': parsed}});
        }
      } else {
        _eventsController.add({'event': 'message.unknown', 'data': {'value': raw}});
      }
    } catch (e) {
      try {
        _eventsController.add({'event': 'message.parse_error', 'data': {'raw': raw.toString(), 'error': e.toString()}});
      } catch (_) {}
    }
  }

  void _scheduleReconnect() {
    if (_closing) return;
    _reconnectAttempts++;
    if (_reconnectAttempts > maxReconnectAttempts) {
      _connController.add(false);
      return;
    }
    final delay = _computeBackoff(_reconnectAttempts);
    Future.delayed(delay, () {
      if (!_closing) _attemptConnect();
    });
  }

  Future<void> sendEvent(String event, Map<String, dynamic> data) async {
    final envelope = jsonEncode({'event': event, 'data': data});
    try {
      if (_socket == null || _socket!.readyState != WebSocket.open) {
        await connect();
      }
      if (_socket != null && _socket!.readyState == WebSocket.open) {
        _socket!.add(envelope);
      } else {
        throw Exception('WebSocket not connected');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _closing = true;
    _reconnectAttempts = 0;
    _connController.add(false);
    try {
      await _socket?.close(WebSocketStatus.normalClosure, 'client disconnect');
    } catch (_) {}
    try {
      _pingTimer?.cancel();
    } catch (_) {}
    _pingTimer = null;
    _detachSocket();
  }

  Future<void> dispose() async {
    _closing = true;
    try {
      await disconnect();
    } catch (_) {}
    try {
      await _eventsController.close();
    } catch (_) {}
    try {
      await _connController.close();
    } catch (_) {}
  }
}
