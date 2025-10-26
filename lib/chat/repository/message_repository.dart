// v0.7-message_repository-singleton-full · 2025-10-25T22:55 IST
// message_repository.dart (singleton + init + dispose + watchConversations added)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bargain/chat/constants/message_status.dart';
import 'package:bargain/chat/utils/network_exceptions.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import '../core/config.dart';
import '../services/cdn_uploader.dart';
import '../services/chat_database_helper.dart';
import '../services/ws_client.dart';
import 'package:bargain/chat/model/conversation_summary.dart';

/// MessageRepository: singleton with lazy init, upload, send flows, and dispose support.
class MessageRepository {
  // ---------------- Singleton boilerplate ----------------
  static final MessageRepository instance = MessageRepository._internal();
  MessageRepository._internal();
  factory MessageRepository() => instance;

  // ---------------- Dependencies (must be injected via init) ----------------
  late WsClient _wsClient;
  late CdnUploader _cdnUploader;
  late ChatDatabaseHelper _localDb;
  Uri? _httpFallbackEndpoint;
  void Function(String msg)? _logger;

  bool _initialized = false;
  final _uuid = const Uuid();

  /// Initialize repository with dependencies. Call once during app start.
  Future<void> init({
    required WsClient wsClient,
    required CdnUploader cdnUploader,
    required ChatDatabaseHelper localDb,
    Uri? httpFallbackEndpoint,
    void Function(String msg)? logger,
  }) async {
    if (_initialized) {
      _log('MessageRepository: re-init called; overriding dependencies');
    }
    _wsClient = wsClient;
    _cdnUploader = cdnUploader;
    _localDb = localDb;
    _httpFallbackEndpoint = httpFallbackEndpoint;
    _logger = logger;
    _initialized = true;
    _log('MessageRepository: initialized');
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('MessageRepository not initialized. Call MessageRepository.instance.init(...) first.');
    }
  }

  void _log(String m) {
    if (_logger != null) _logger!(m);
  }

  // -------------------------
  // Text message flow
  // -------------------------
  Future<String> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    _ensureInit();
    final tempId = 'local-${_uuid.v4()}';
    final now = DateTime.now().toUtc().toIso8601String();

    final localRow = <String, dynamic>{
      'tempId': tempId,
      'serverId': null,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'contentType': 'text',
      'cdnUrl': null,
      'thumbUrl': null,
      'localPath': null,
      'uploadProgress': 100,
      'status': 'sent_optimistic',
      'createdAt': now,
      'updatedAt': now,
    };

    await _localDb.saveMessage(localRow);

    final payload = {
      'tempId': tempId,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'contentType': 'text',
      'meta': {},
      'createdAt': now,
    };

    try {
      await _wsClient.sendEvent('message.send', payload);
      _log('sendTextMessage: queued via WS, tempId=$tempId');
    } catch (e) {
      _log('sendTextMessage: WS send failed: $e');
      // fallback to HTTP persist if configured
      if (_httpFallbackEndpoint != null) {
        try {
          await _sendViaHttp(payload);
        } catch (err) {
          _log('sendTextMessage: HTTP fallback failed: $err');
          await _localDb.updateMessageStatus(tempId, MessageStatus.Failed);
        }
      } else {
        // Mark failed to surface in UI
        await _localDb.updateMessageStatus(tempId, MessageStatus.Failed);
      }
    }

    return tempId;
  }

  // -------------------------
  // Media message flow
  // -------------------------
  Future<String> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required File file,
    required String mime,
    Map<String, dynamic>? meta,
  }) async {
    _ensureInit();
    final tempId = 'local-${_uuid.v4()}';
    final now = DateTime.now().toUtc().toIso8601String();

    final placeholder = <String, dynamic>{
      'tempId': tempId,
      'serverId': null,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': null,
      'contentType': _mimeToContentTypeString(mime),
      'cdnUrl': null,
      'thumbUrl': null,
      'localPath': file.path,
      'uploadProgress': 0,
      'status': 'uploading',
      'createdAt': now,
      'updatedAt': now,
    };

    await _localDb.saveMessage(placeholder);

    // 1) Optional compression step (left as hook)
    File toUpload = file;
    try {
      // If you have a compression service, do it here
    } catch (e) {
      // ignore compression errors
    }

    final filesize = await toUpload.length();
    if (filesize > Config.MAX_UPLOAD_SIZE_MB * 1024 * 1024) {
      await _localDb.updateMessageStatus(tempId, MessageStatus.Failed);
      throw UploadFailedException('File too large');
    }

    // 2) request signed upload url
    CdnUploadResponse signed;
    try {
      signed = await _cdnUploader.getSignedUploadUrl(
        filename: p.basename(toUpload.path),
        mime: mime,
        size: filesize,
        metadata: {'conversationId': conversationId, 'senderId': senderId},
      );
    } on Exception catch (e) {
      await _localDb.updateMessageStatus(tempId, MessageStatus.Failed);
      throw SigningFailedException('Failed to get signed URL: $e');
    }

    // 3) upload with progress and CancelToken support
    final cancelToken = CancelToken();
    try {
      final result = await _cdnUploader.uploadFile(
        file: toUpload,
        mime: mime,
        signedInfo: signed,
        cancelToken: cancelToken,
        onProgress: (pct) async {
          final intPct = pct.clamp(0.0, 100.0).toInt();
          await _localDb.updateMessageProgress(tempId, intPct);
        },
      );

      if (!result.success || result.response == null) {
        await _localDb.updateMessageStatus(tempId, MessageStatus.Failed);
        throw UploadFailedException('Upload failed');
      }

      final cdnUrl = result.response!.cdnUrl;
      final thumbUrl = result.response!.thumbUrl;

      // 4) update local DB with CDN info
      await _localDb.updateMessageAfterUpload(
        tempId: tempId,
        cdnUrl: cdnUrl,
        thumbUrl: thumbUrl,
        uploadProgress: 100,
      );

      // 5) send message metadata via WS
      final payload = {
        'tempId': tempId,
        'conversationId': conversationId,
        'senderId': senderId,
        'contentType': _mimeToContentTypeString(mime),
        'cdnUrl': cdnUrl,
        'thumbUrl': thumbUrl,
        'size': filesize,
        'meta': meta ?? {},
        'createdAt': now,
      };

      try {
        await _wsClient.sendEvent('message.send', payload);
        _log('sendMediaMessage: WS sendEvent done for tempId=$tempId');
      } catch (e) {
        _log('sendMediaMessage: WS send failed: $e');
        if (_httpFallbackEndpoint != null) {
          try {
            await _sendViaHttp(payload);
          } catch (err) {
            _log('sendMediaMessage: HTTP fallback failed: $err');
            await _localDb.updateMessageStatus(tempId, MessageStatus.Failed);
          }
        } else {
          await _localDb.updateMessageStatus(tempId, MessageStatus.SentOptimistic);
        }
      }
    } catch (e) {
      _log('sendMediaMessage: upload error: $e');
      await _localDb.updateMessageStatus(tempId, MessageStatus.Failed);
      rethrow;
    }

    return tempId;
  }

  // -------------------------
  // Retry helpers
  // -------------------------
  Future<void> retryUpload(String tempId) async {
    _ensureInit();
    final row = await _localDb.getMessageByTempId(tempId);
    if (row == null) throw Exception('No local message for tempId $tempId');

    final localPath = row['localPath'] as String?;
    final contentType = row['contentType'] as String? ?? 'image';
    if (localPath == null || localPath.isEmpty) throw Exception('No local file to retry');

    final file = File(localPath);
    if (!file.existsSync()) throw Exception('Local file missing');

    await sendMediaMessage(
      conversationId: row['conversationId'] as String,
      senderId: row['senderId'] as String,
      file: file,
      mime: contentType == 'image' ? 'image/jpeg' : 'application/octet-stream',
      meta: {},
    );
  }

  // -------------------------
  // watchConversations: new
  // -------------------------
  /// Emit a stream of ConversationSummary lists by polling the local messages table.
  /// - `currentUserId` optional: if provided repository will compute `peerId` by
  ///   splitting the conversationId (`a:b`) and picking the other participant.
  /// - `pollInterval`: how often to refresh. Default 2s (adjust if you prefer).
  // inside MessageRepository (replace only the watchConversations() method)

  // Replace the existing watchConversations(...) with this version
  Stream<List<ConversationSummary>> watchConversations({
    String? currentUserId,
    Duration pollInterval = const Duration(seconds: 2),
  }) {
    if (!_initialized) {
      final c = StreamController<List<ConversationSummary>>();
      c.add(<ConversationSummary>[]);
      c.close();
      return c.stream;
    }

    final controller = StreamController<List<ConversationSummary>>.broadcast();
    Timer? timer;
    bool closed = false;

    int _statusStringToInt(String? s) {
      if (s == null) return 0;
      final st = s.toLowerCase();
      if (st == 'failed' || st == 'error') return -1;
      if (st == 'pending' || st == 'uploading' || st == 'sent_optimistic' || st == 'sending') return 0;
      if (st == 'sent' || st == 'sent_ok') return 1;
      if (st == 'delivered') return 2;
      if (st == 'read') return 3;
      // fallback
      return 0;
    }

    Future<void> emitOnce() async {
      try {
        final db = await _localDb.database;
        final rows = await db.rawQuery(
          'SELECT conversationId, text, contentType, createdAt, senderId, serverId, thumbUrl, status '
              'FROM messages ORDER BY createdAt DESC, id DESC',
        );

        final Map<String, Map<String, dynamic>> latestPerConv = {};
        for (final r in rows) {
          final conv = (r['conversationId'] as String?) ?? '';
          if (conv.isEmpty) continue;
          if (!latestPerConv.containsKey(conv)) {
            latestPerConv[conv] = Map<String, dynamic>.from(r);
          }
        }

        final List<ConversationSummary> list = [];
        for (final entry in latestPerConv.entries) {
          final convId = entry.key;
          final r = entry.value;
          final lastText = (r['text'] as String?) ?? '';
          final lastType = (r['contentType'] as String?) ?? 'text';
          final createdAtStr = (r['createdAt'] as String?) ?? '';
          int lastUpdatedMs = DateTime.now().millisecondsSinceEpoch;
          if (createdAtStr.isNotEmpty) {
            try {
              lastUpdatedMs = DateTime.parse(createdAtStr).millisecondsSinceEpoch;
            } catch (_) {}
          }

          String peerId = convId;
          if (currentUserId != null) {
            final parts = convId.split(':');
            if (parts.length == 2) {
              peerId = (parts[0] == currentUserId) ? parts[1] : parts[0];
            }
          }

          final statusStr = (r['status'] as String?) ?? 'sent';
          final statusInt = _statusStringToInt(statusStr);

          final cs = ConversationSummary(
            conversationId: convId,
            peerId: peerId,
            peerName: null,
            peerPhoto: null,
            lastMessageText: lastText,
            lastMessageType: lastType,
            lastMessageStatus: statusInt,   // now an int
            lastUpdated: lastUpdatedMs,     // int timestamp as your model expects
            isPeerOnline: false,
            peerLastSeenMs: null,
            isPeerDeleted: false,
          );

          list.add(cs);
        }

        list.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) controller.add(<ConversationSummary>[]);
      }
    }

    emitOnce();
    timer = Timer.periodic(pollInterval, (_) {
      if (closed) return;
      emitOnce();
    });

    controller.onCancel = () {
      timer?.cancel();
      closed = true;
    };

    return controller.stream;
  }

  // -------------------------
  // HTTP fallback (simple)
  // -------------------------
  Future<void> _sendViaHttp(Map<String, dynamic> payload) async {
    if (_httpFallbackEndpoint == null) throw Exception('HTTP fallback not configured');

    final client = HttpClient();
    try {
      final req = await client.postUrl(_httpFallbackEndpoint!);
      req.headers.set('Content-Type', 'application/json');
      req.add(const Utf8Encoder().convert(jsonEncode(payload)));
      final resp = await req.close();
      final body = await resp.transform(const Utf8Decoder()).join();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('HTTP fallback failed: ${resp.statusCode} $body');
      }
      if (body.isNotEmpty) {
        try {
          final map = jsonDecode(body) as Map<String, dynamic>;
          final serverId = map['serverId'] as String?;
          final tempId = payload['tempId'] as String?;
          if (serverId != null && tempId != null) {
            await _localDb.updateMessageServerId(tempId, serverId);
            await _localDb.updateMessageStatus(tempId, MessageStatus.Sent);
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }
  }

  // -------------------------
  // Utilities
  // -------------------------
  String _mimeToContentTypeString(String mime) {
    if (mime.startsWith('image/')) return 'image';
    if (mime.startsWith('video/')) return 'video';
    if (mime.startsWith('audio/')) return 'audio';
    return 'file';
  }

  // -------------------------
  // Dispose / Close
  // -------------------------
  /// Instance dispose — closes sockets, uploader and DB
  Future<void> dispose() async {
    if (!_initialized) return;
    _log('MessageRepository: disposing resources');

    // 1) Dispose/close wsClient if available
    try {
      // prefer dispose() if available else disconnect
      try {
        await _wsClient.dispose();
      } catch (_) {
        await _wsClient.disconnect();
      }
    } catch (e) {
      _log('MessageRepository: error disposing wsClient: $e');
    }

    // 2) Dispose cdn uploader (if implement dispose)
    try {
      _cdnUploader.dispose();
    } catch (e) {
      _log('MessageRepository: error disposing cdnUploader: $e');
    }

    // 3) Close local DB helper
    try {
      await _localDb.close();
    } catch (e) {
      _log('MessageRepository: error closing localDb: $e');
      try {
        // fallback if different method exists
        await _localDb.clearAllMessages();
      } catch (_) {}
    }

    _initialized = false;
    _log('MessageRepository: disposed');
  }

  /// Static helper so older code can call statically if needed.
  static Future<void> disposeInstance() async {
    try {
      await instance.dispose();
    } catch (_) {
      // swallow
    }
  }
}
