// v0.6-chat_database_helper · 2025-10-25T10:55 IST
// chat_database_helper.dart (updated: MessageStatus handling + toDb usage)
//
// Responsibilities:
// - Local SQLite helper for messages (CRUD + helpers used by repo/bloc/ack handler)
// - Stores MessageStatus as snake_case strings via MessageStatus.toDb()
// - Returns raw Map<String,dynamic> rows so UI/Bloc can interpret them

import 'dart:async';
import 'package:bargain/chat/constants/message_status.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class ChatDatabaseHelper {
  static final ChatDatabaseHelper _instance = ChatDatabaseHelper._internal();
  factory ChatDatabaseHelper() => _instance;
  ChatDatabaseHelper._internal();

  static const _dbName = 'chat_local.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tempId TEXT,
        serverId TEXT,
        conversationId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        text TEXT,
        contentType TEXT,
        cdnUrl TEXT,
        thumbUrl TEXT,
        localPath TEXT,
        size INTEGER,
        meta TEXT,
        uploadProgress INTEGER DEFAULT 0,
        status TEXT,
        createdAt TEXT,
        updatedAt TEXT
      );
    ''');

    await db.execute('CREATE INDEX idx_conv_created ON messages(conversationId, createdAt);');
    await db.execute('CREATE INDEX idx_serverId ON messages(serverId);');
    await db.execute('CREATE INDEX idx_tempId ON messages(tempId);');
  }

  // ---------------- Basic CRUD ----------------

  /// Save a message row (if tempId exists, try to update existing row; else insert)
  Future<int> saveMessage(Map<String, dynamic> row) async {
    final db = await database;
    // normalize meta map to JSON string if present
    final toInsert = Map<String, dynamic>.from(row);
    if (toInsert.containsKey('meta') && toInsert['meta'] is Map) {
      try {
        toInsert['meta'] = toInsert['meta'] != null ? toInsert['meta'] is String ? toInsert['meta'] : toInsert['meta'].toString() : null;
      } catch (_) {
        toInsert['meta'] = toInsert['meta'].toString();
      }
    }

    // Ensure status saved consistently if enum provided
    if (toInsert.containsKey('status') && toInsert['status'] is! String) {
      toInsert['status'] = _statusToString(toInsert['status']);
    }

    // try update by tempId if exists and non-empty
    if (toInsert['tempId'] != null && (toInsert['tempId'] as String).isNotEmpty) {
      final updated = await db.update('messages', toInsert, where: 'tempId = ?', whereArgs: [toInsert['tempId']]);
      if (updated > 0) return updated;
    }

    // else insert
    final id = await db.insert('messages', toInsert);
    return id;
  }

  /// Fetch messages for a conversation (oldest first). Returns typed list.
  Future<List<Map<String, dynamic>>> fetchMessagesForConversation(String conversationId, {int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt ASC, id ASC',
      limit: limit,
    );
    return rows;
  }

  Future<Map<String, dynamic>?> getMessageByServerId(String serverId) async {
    final db = await database;
    final rows = await db.query('messages', where: 'serverId = ?', whereArgs: [serverId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> getMessageByTempId(String tempId) async {
    final db = await database;
    final rows = await db.query('messages', where: 'tempId = ?', whereArgs: [tempId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Update message serverId for a message identified by tempId
  Future<int> updateMessageServerId(String tempId, String serverId) async {
    final db = await database;
    return await db.update('messages', {'serverId': serverId, 'updatedAt': DateTime.now().toUtc().toIso8601String()}, where: 'tempId = ?', whereArgs: [tempId]);
  }

  /// Update message status by tempId or serverId (tries tempId first)
  /// `status` may be a MessageStatus enum or a string.
  Future<int> updateMessageStatus(String id, dynamic status) async {
    final db = await database;
    final s = _statusToString(status);
    // try tempId
    var updated = await db.update('messages', {'status': s, 'updatedAt': DateTime.now().toUtc().toIso8601String()}, where: 'tempId = ?', whereArgs: [id]);
    if (updated > 0) return updated;
    // try serverId
    updated = await db.update('messages', {'status': s, 'updatedAt': DateTime.now().toUtc().toIso8601String()}, where: 'serverId = ?', whereArgs: [id]);
    return updated;
  }

  /// Update upload progress by tempId (0..100)
  Future<int> updateMessageProgress(String tempId, int progress) async {
    final db = await database;
    final p = progress.clamp(0, 100);
    return await db.update('messages', {'uploadProgress': p, 'updatedAt': DateTime.now().toUtc().toIso8601String()}, where: 'tempId = ?', whereArgs: [tempId]);
  }

  /// After successful upload: update cdnUrl, thumbUrl and optionally progress/status
  Future<int> updateMessageAfterUpload({
    required String tempId,
    String? cdnUrl,
    String? thumbUrl,
    int uploadProgress = 100,
    dynamic status,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {
      'uploadProgress': uploadProgress,
      'cdnUrl': cdnUrl,
      'thumbUrl': thumbUrl,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (status != null) updates['status'] = _statusToString(status);
    return await db.update('messages', updates, where: 'tempId = ?', whereArgs: [tempId]);
  }

  /// Delete by tempId
  Future<int> deleteMessageByTempId(String tempId) async {
    final db = await database;
    return await db.delete('messages', where: 'tempId = ?', whereArgs: [tempId]);
  }

  /// Delete by serverId
  Future<int> deleteMessageByServerId(String serverId) async {
    final db = await database;
    return await db.delete('messages', where: 'serverId = ?', whereArgs: [serverId]);
  }

  // ---------------- Utilities ----------------

  /// Convert enum or string to plain string (prefer snake_case via MessageStatus.toDb())
  String _statusToString(dynamic status) {
    if (status == null) return '';
    if (status is String) return status;
    // If caller passed enum MessageStatus -> use toDb() to store snake_case
    if (status is MessageStatus) {
      try {
        return status.toDb();
      } catch (_) {
        // fallback
        return status.toString().split('.').last.toLowerCase();
      }
    }
    try {
      // fallback: try toString() split
      return status.toString();
    } catch (_) {
      return status.toString();
    }
  }

  /// Close DB (useful in tests)
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// Clear messages table (for debug/tests)
  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }
}
