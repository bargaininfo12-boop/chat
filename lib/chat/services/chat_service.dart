// v1.2-chat_service · 2025-10-26T11:00 IST
// lib/chat/services/chat_service.dart
//
// Central façade for chat-related functionality used by UI.
// - Single-source-of-truth singleton (ChatService.instance)
// - Delegates to MessageRepository for send/upload/retry/watch
// - Exposes presenceChanges (from WsMessageHandler) and ack/new streams (from WsAckHandler)
// - Provides a progress stream that UI/Bloc can subscribe to
// - init(...) accepts injected dependencies (keeps testability)
// - All comments in Hinglish (technical terms English)

import 'dart:async';

import 'package:bargain/chat/model/conversation_summary.dart';
import 'package:bargain/chat/services/cdn_uploader.dart';
import 'package:bargain/chat/services/chat_database_helper.dart';
import 'package:bargain/chat/services/ws_ack_handler.dart';
import 'package:bargain/chat/services/ws_client.dart';
import 'package:bargain/chat/services/ws_message_handler.dart';
import 'package:bargain/chat/repository/message_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/file.dart';

/// ChatService: lightweight façade used by UI/screens.
/// Usage:
///   await ChatService.instance.init(...);
///   ChatService.instance.watchConversations(...);
///   ChatService.instance.sendText(...);
///   ChatService.instance.sendMedia(...);
class ChatService {
  // Singleton pattern
  static ChatService? _instance;
  static ChatService get instance {
    _instance ??= ChatService._internal();
    return _instance!;
  }

  ChatService._internal();

  // Core dependencies - exposed for other modules to access
  late final WsClient wsClient;
  late final CdnUploader cdnUploader;
  late final ChatDatabaseHelper localDb;

  // Internal dependencies - private to ChatService
  late final MessageRepository _repo;
  late final WsMessageHandler _wsMessageHandler;
  late final WsAckHandler _wsAckHandler;

  // State tracking
  bool _initialized = false;
  String? _currentUserId;

  // Broadcast streams exposed to UI/Bloc layer
  final StreamController<Map<String, dynamic>> _presenceController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageAckController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageNewController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _progressController =
  StreamController<Map<String, dynamic>>.broadcast();

  // Internal subscriptions management
  StreamSubscription? _presenceSub;
  StreamSubscription? _ackSub;
  StreamSubscription? _newSub;

  // Heartbeat timer for keeping connection alive
  Timer? _heartbeatTimer;

  /// Main initialization method - sets up all dependencies and wiring.
  /// Call this once during app startup with all required dependencies.
  ///
  /// Parameters:
  /// - wsClient: WebSocket client for real-time communication
  /// - cdnUploader: Service for uploading media files to CDN
  /// - localDb: Local SQLite database helper
  /// - repo: Message repository for business logic
  /// - wsMessageHandler: Handles incoming WebSocket messages
  /// - wsAckHandler: Handles message acknowledgments
  /// - currentUserId: Current logged-in user ID (optional)
  Future<void> init({
    required WsClient wsClient,
    required CdnUploader cdnUploader,
    required ChatDatabaseHelper localDb,
    required MessageRepository repo,
    required WsMessageHandler wsMessageHandler,
    required WsAckHandler wsAckHandler,
    String? currentUserId,
  }) async {
    // Allow graceful re-initialization
    if (_initialized) {
      await dispose();
    }

    // Assign core dependencies (accessible by other modules)
    this.wsClient = wsClient;
    this.cdnUploader = cdnUploader;
    this.localDb = localDb;

    // Assign internal dependencies
    _repo = repo;
    _wsMessageHandler = wsMessageHandler;
    _wsAckHandler = wsAckHandler;
    _currentUserId = currentUserId;

    // Start WebSocket message handler (idempotent start)
    try {
      _wsMessageHandler.start();
    } catch (e) {
      // Log or handle initialization error if needed
    }

    // Start acknowledgment handler (idempotent start)
    try {
      _wsAckHandler.start();
    } catch (e) {
      // Log or handle initialization error if needed
    }

    // Wire presence changes from WsMessageHandler to public stream
    try {
      _presenceSub = _wsMessageHandler.presence.listen(
            (presenceData) {
          // presenceData: { userId, status, lastSeen, conversationId, raw }
          _presenceController.add(presenceData);
        },
        onError: (error) {
          // Swallow errors or log externally
        },
      );
    } catch (e) {
      // Handle subscription error
    }

    // Wire message acknowledgments to public stream
    try {
      _ackSub = _wsAckHandler.messageAck.listen(
            (ackData) {
          _messageAckController.add(ackData);
        },
        onError: (error) {
          // Swallow errors
        },
      );
    } catch (e) {
      // Handle subscription error
    }

    // Wire new incoming messages to public stream
    try {
      _newSub = _wsAckHandler.messageNew.listen(
            (messageData) {
          _messageNewController.add(messageData);
        },
        onError: (error) {
          // Swallow errors
        },
      );
    } catch (e) {
      // Handle subscription error
    }

    _initialized = true;

    // Start heartbeat to keep presence active
    _startHeartbeat();
  }

  /// Internal check to ensure ChatService is initialized before use
  void _ensureInit() {
    if (!_initialized) {
      throw StateError(
        'ChatService not initialized. Call ChatService.instance.init(...) first.',
      );
    }
  }

  // ============================================================================
  // PUBLIC STREAM GETTERS - Subscribe karo UI/Bloc layer se
  // ============================================================================

  /// Stream of presence changes
  /// Emits: { userId, status, lastSeen, conversationId, raw }
  Stream<Map<String, dynamic>> get presenceChanges => _presenceController.stream;

  /// Stream of message acknowledgments (sent -> delivered -> read transitions)
  Stream<Map<String, dynamic>> get messageAck => _messageAckController.stream;

  /// Stream of new incoming messages from other users
  Stream<Map<String, dynamic>> get messageNew => _messageNewController.stream;

  /// Stream of upload progress for media messages
  /// Emits: { 'tempId': String, 'progress': double } where progress is 0.0 to 1.0
  Stream<Map<String, dynamic>> get uploadProgress => _progressController.stream;

  // ============================================================================
  // CONVERSATION METHODS
  // ============================================================================

  /// Watch conversation summaries (live stream with periodic polling)
  /// Returns stream of conversation list sorted by latest message
  Stream<List<ConversationSummary>> watchConversations({
    String? currentUserId,
    Duration pollInterval = const Duration(seconds: 2),
  }) {
    _ensureInit();
    return _repo.watchConversations(
      currentUserId: currentUserId ?? _currentUserId,
      pollInterval: pollInterval,
    );
  }

  /// Get messages for a specific conversation (one-time fetch)
  /// Returns list of message maps ordered by createdAt
  Future<List<Map<String, dynamic>>> getMessagesForConversation(
      String conversationId, {
        int limit = 500,
      }) async {
    _ensureInit();
    final db = await localDb.database;
    final rows = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt ASC, id ASC',
      limit: limit,
    );
    return rows;
  }

  /// Mark all messages in a conversation as read
  /// Updates local DB and sends read receipt to server
  Future<void> markConversationRead(String conversationId) async {
    _ensureInit();
    try {
      final db = await localDb.database;
      await db.rawUpdate(
        "UPDATE messages SET status = ?, updatedAt = ? WHERE conversationId = ? AND senderId != ?",
        [
          'read',
          DateTime.now().toUtc().toIso8601String(),
          conversationId,
          _currentUserId ?? '',
        ],
      );

      // Send read receipt to server via WebSocket
      try {
        await _wsMessageHandler.sendEvent('conversation.read', {
          'conversationId': conversationId,
          'readerId': _currentUserId,
        });
      } catch (e) {
        // Network error - server will sync later
      }
    } catch (e) {
      // Database error - handle or log
    }
  }

  // ============================================================================
  // MESSAGE SENDING METHODS
  // ============================================================================

  /// Send a text message
  /// Returns tempId for tracking before server confirms
  Future<String> sendText({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    _ensureInit();
    return await _repo.sendTextMessage(
      conversationId: conversationId,
      senderId: senderId,
      text: text,
    );
  }

  /// Send a media message (image/video/audio/document)
  /// Handles upload -> DB update -> WebSocket send flow
  /// Returns tempId for tracking upload progress
  Future<String> sendMedia({
    required String conversationId,
    required String senderId,
    required File file,
    required String mime,
    Map<String, dynamic>? meta,
  }) async {
    _ensureInit();
    return await _repo.sendMediaMessage(
      conversationId: conversationId,
      senderId: senderId,
      file: file,
      mime: mime,
      meta: meta,
    );
  }

  /// Retry failed upload for a message
  /// Use tempId to identify the message
  Future<void> retryUpload(String tempId) async {
    _ensureInit();
    await _repo.retryUpload(tempId);
  }

  // ============================================================================
  // UPLOAD PROGRESS TRACKING
  // ============================================================================

  /// Notify about upload progress
  /// Called by MessageRepository or CdnUploader during upload
  /// Accepts progress as 0-1 (fraction) or 0-100 (percentage) - normalizes automatically
  void notifyUploadProgress(String tempId, double progress) {
    if (tempId.isEmpty) return;

    // Normalize progress to 0.0-1.0 range
    double normalizedProgress = progress;
    if (progress > 1.0 && progress <= 100.0) {
      normalizedProgress = progress / 100.0;
    }
    if (normalizedProgress.isNaN) {
      normalizedProgress = 0.0;
    }
    normalizedProgress = normalizedProgress.clamp(0.0, 1.0);

    _progressController.add({
      'tempId': tempId,
      'progress': normalizedProgress,
    });
  }

  // ============================================================================
  // CONNECTION & PRESENCE MANAGEMENT
  // ============================================================================

  /// Connect to WebSocket server
  /// Call this after user login to establish real-time connection
  Future<void> connect() async {
    _ensureInit();
    try {
      await wsClient.connect();
      debugPrint('✅ ChatService: WebSocket connected');
    } catch (e) {
      debugPrint('⚠️ ChatService: WebSocket connect failed: $e');
      rethrow;
    }
  }

  /// Set user presence status (online/offline/away)
  /// Updates both local state and notifies server
  Future<void> setPresence({
    required String userId,
    required String status,
  }) async {
    _ensureInit();
    try {
      await _wsMessageHandler.sendEvent('presence.update', {
        'userId': userId,
        'status': status,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('✅ ChatService: Presence set to $status for user $userId');
    } catch (e) {
      debugPrint('⚠️ ChatService: setPresence failed: $e');
      // Don't rethrow - presence is not critical
    }
  }

  /// Disconnect from WebSocket server
  /// Call this on logout or app termination
  Future<void> disconnect() async {
    try {
      // Stop heartbeat first
      _stopHeartbeat();

      // Set offline presence before disconnect
      if (_currentUserId != null) {
        try {
          await setPresence(userId: _currentUserId!, status: 'offline');
        } catch (_) {}
      }

      await wsClient.disconnect();
      debugPrint('✅ ChatService: WebSocket disconnected');
    } catch (e) {
      debugPrint('⚠️ ChatService: disconnect failed: $e');
    }
  }

  // ============================================================================
  // HEARTBEAT MECHANISM
  // ============================================================================

  /// Start periodic heartbeat to keep connection alive and update presence
  void _startHeartbeat() {
    _stopHeartbeat(); // Clear any existing timer

    if (_currentUserId == null) return;

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentUserId != null && _initialized) {
        try {
          // Send presence update to keep connection alive
          setPresence(userId: _currentUserId!, status: 'online');
        } catch (e) {
          debugPrint('⚠️ Heartbeat failed: $e');
        }
      }
    });

    debugPrint('✅ ChatService: Heartbeat started (30s interval)');
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose all resources
  /// Cancel subscriptions, close streams, disconnect services
  Future<void> dispose() async {
    // Stop heartbeat
    _stopHeartbeat();

    // Cancel all stream subscriptions
    await _presenceSub?.cancel();
    _presenceSub = null;

    await _ackSub?.cancel();
    _ackSub = null;

    await _newSub?.cancel();
    _newSub = null;

    // Close all broadcast controllers
    try {
      await _presenceController.close();
    } catch (e) {
      // Already closed
    }

    try {
      await _messageAckController.close();
    } catch (e) {
      // Already closed
    }

    try {
      await _messageNewController.close();
    } catch (e) {
      // Already closed
    }

    try {
      await _progressController.close();
    } catch (e) {
      // Already closed
    }

    // Disconnect WebSocket client
    try {
      await wsClient.disconnect();
    } catch (e) {
      // Already disconnected or error
    }

    // Dispose CDN uploader
    try {
      cdnUploader.dispose();
    } catch (e) {
      // Already disposed or error
    }

    _initialized = false;
  }
}