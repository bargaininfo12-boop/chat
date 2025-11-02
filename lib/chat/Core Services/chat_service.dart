// lib/chat/services/chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:bargain/chat/Core%20Services/ws_ack_handler.dart';
import 'package:bargain/chat/Local Database Layer/chat_database_helper.dart';
import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

/// Central chat service: WS connection, ack handler, local DB bridge, message streams.
class ChatService {
  ChatService._internal();
  static final ChatService instance = ChatService._internal();

  late Uri _wsEndpoint;
  late Uri _imagekitAuthEndpoint;
  late ChatDatabaseHelper _localDb;
  late Future<String> Function() _tokenProvider;
  Uri? _httpFallbackEndpoint;
  void Function(String msg)? _logger;

  WebSocketChannel? _channel;
  late WsAckHandler _ackHandler;

  final StreamController<ChatMessage> _messageController = StreamController.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  bool _isConnected = false;

  // init must be called once at app startup
  Future<void> init({
    required Uri wsEndpoint,
    required Uri imagekitAuthEndpoint,
    required ChatDatabaseHelper localDb,
    required Future<String> Function() tokenProvider,
    Uri? httpFallbackEndpoint,
    void Function(String msg)? logger,
  }) async {
    _wsEndpoint = wsEndpoint;
    _imagekitAuthEndpoint = imagekitAuthEndpoint;
    _localDb = localDb;
    _tokenProvider = tokenProvider;
    _httpFallbackEndpoint = httpFallbackEndpoint;
    _logger = logger ?? (msg) => print('[ChatService] $msg');

    await _connectWebSocket();
    _setupAckHandler();
    _logger?.call('✅ ChatService initialized');
  }

  Future<void> _connectWebSocket() async {
    try {
      final token = await _tokenProvider();
      final uri = _wsEndpoint.replace(queryParameters: {'token': token});
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen((data) {
        try {
          final decoded = json.decode(data);
          // best-effort: transform raw map into ChatMessage if possible
          if (decoded is Map<String, dynamic>) {
            final msg = ChatMessage.fromMap(decoded);
            _messageController.add(msg);
          }
        } catch (e) {
          _logger?.call('⚠️ WS decode error: $e');
        }
      }, onError: (e) {
        _logger?.call('❌ WS error: $e');
        _isConnected = false;
      }, onDone: () {
        _logger?.call('🔌 WS closed');
        _isConnected = false;
      });

      _logger?.call('🔗 WebSocket connected');
    } catch (e) {
      _logger?.call('❌ WebSocket connect failed: $e');
      _isConnected = false;
    }
  }

  void _setupAckHandler() {
    _ackHandler = WsAckHandler(
      this,
      _localDb,
      onRemoteInsert: (raw) {
        try {
          final msg = ChatMessage.fromMap(Map<String, dynamic>.from(raw));
          _messageController.add(msg);
        } catch (e) {
          _logger?.call('⚠️ ack->msg decode failed: $e');
        }
      },
      onAckForTemp: (tempId, serverId) {
        _logger?.call('🔁 Ack linked: $tempId -> $serverId');
      },
    );
    _ackHandler.start();
  }

  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _localDb.insertMessage(message);
      final encoded = json.encode(message.toMap());
      if (_isConnected && _channel != null) {
        _channel!.sink.add(encoded);
        _logger?.call('📤 Message sent: ${message.id}');
      } else {
        _logger?.call('⚠️ WS not connected, message queued locally: ${message.id}');
      }
    } catch (e) {
      _logger?.call('❌ sendMessage error: $e');
    }
  }

  /// Returns signed info for direct uploads (ImageKit or other)
  Future<Map<String, dynamic>> getSignedInfo() async {
    try {
      final token = await _tokenProvider();
      final response = await http.get(
        _imagekitAuthEndpoint,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get signed info: ${response.statusCode}');
      }
    } catch (e) {
      _logger?.call('❌ getSignedInfo error: $e');
      rethrow;
    }
  }

  /// Graceful cleanup: close ack handler, controllers and socket
  Future<void> dispose() async {
    try {
      await _ackHandler.dispose();
    } catch (_) {}
    try {
      await _messageController.close();
    } catch (_) {}
    try {
      _channel?.sink.close();
    } catch (_) {}
    _isConnected = false;
    _logger?.call('🧹 ChatService disposed');
  }

  // Expose ack/new streams for consumers that need raw WS events
  Stream<Map<String, dynamic>> get messageAck => _ackHandler.messageAck;
  Stream<Map<String, dynamic>> get messageNew => _ackHandler.messageNew;

  // -------------------------
  // New: Database access helpers
  // -------------------------

  /// Fetch messages for a conversation from local DB (most recent first)
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final rows = await _localDb.getMessages(conversationId);
      return rows;
    } catch (e) {
      _logger?.call('❌ getMessages error: $e');
      return <ChatMessage>[];
    }
  }

  /// Fetch latest message per conversation (used by ChatListScreen)
  Future<List<ChatMessage>> getMessagesForAllConversations() async {
    try {
      final all = await _localDb.getAllMessages();
      // group by conversationId and pick latest by timestamp
      final Map<String, ChatMessage> latest = {};
      for (final m in all) {
        final conv = m.conversationId ?? '';
        final existing = latest[conv];
        if (existing == null) {
          latest[conv] = m;
        } else {
          // compare parsed timestamps; ChatMessage.timestamp is DateTime
          final a = m.timestamp;
          final b = existing.timestamp;
          if (a.isAfter(b)) latest[conv] = m;
        }
      }
      final list = latest.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      _logger?.call('❌ getMessagesForAllConversations error: $e');
      return <ChatMessage>[];
    }
  }
}
