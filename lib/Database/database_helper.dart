// DatabaseHelper (v5) - Updated: 2025-10-26T15:22 IST
// - Adds tempId/serverId/thumbUrl/uploadProgress for upload flow
// - v5 migration + indexes + helper methods (getMessageByTempId, linkTempToServer, etc.)
// - Validation: either messageId OR tempId required
//
// NOTE: Keep single source of truth for DB version: _databaseVersion = 5

import 'dart:async';
import 'dart:io';
import 'package:bargain/A_User_Data/user_model.dart';
import 'package:bargain/chat/utils/timestamp_utils.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final _log = Logger('DatabaseHelper');

/// ✅ DatabaseHelper (v5)
class DatabaseHelper {
  // ========= DB Config =========
  static final _databaseName = "bargain.db";
  static final _databaseVersion = 5; // bumped to v5
  static final columnLanguage = 'language';

  // ========= Tables =========
  static final tableMessages = 'messages';
  static final tableUsers = 'users';

  // ========= Columns: messages =========
  static final columnMessageId = 'messageId';
  static final columnTempId = 'tempId';           // NEW v5
  static final columnServerId = 'serverId';       // NEW v5
  static final columnConversationId = 'conversationId';
  static final columnSenderId = 'senderId';
  static final columnReceiverId = 'receiverId';
  static final columnMessage = 'message';
  static final columnMessageType = 'message_type';
  static final columnMediaUrl = 'media_url';
  static final columnThumbUrl = 'thumbUrl';       // NEW v5
  static final columnLocalPath = 'local_path';
  static final columnTimestamp = 'timestamp';
  static final columnStatus = 'Status';          // legacy casing kept
  static final columnFilename = 'Filename';      // legacy casing kept
  static final columnFilesize = 'filesize';
  static final columnMetadata = 'metadata';
  // download progress
  static final columnDownloadProgress = 'download_progress';
  static final columnDownloadStatus = 'download_status';
  // upload progress
  static final columnUploadProgress = 'uploadProgress'; // NEW v5

  // ========= Columns: users =========
  static final columnUid = 'uid';
  static final columnName = 'name';
  static final columnEmail = 'email';
  static final columnPhoneNumber = 'phoneNumber';
  static final columnPhotoURL = 'photoURL';
  static final columnPhotoLocal = 'photoLocal';
  static final columnAddress = 'address';
  static final columnCity = 'city';
  static final columnState = 'state';
  static final columnPinCode = 'pinCode';
  static final columnCreatedAt = 'createdAt';
  static final columnLastUpdated = 'lastUpdated';
  static const columnIsDeleted = 'isDeleted';
  static const columnDeletionPending = 'deletionPending';
  static const columnDeletionScheduledFor = 'deletionScheduledFor';

  // ========= Singleton =========
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ========= Init =========
  Future<Database> _initDatabase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = join(dir.path, _databaseName);

      return await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.rawQuery('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
        },
      );
    } catch (e) {
      _log.severe('Database init failed: $e');
      rethrow;
    }
  }

  // ========= Create =========
  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE $tableMessages (
        $columnMessageId       TEXT PRIMARY KEY,
        $columnTempId          TEXT,                    -- NEW v5
        $columnServerId        TEXT,                    -- NEW v5
        $columnConversationId  TEXT NOT NULL,
        $columnSenderId        TEXT NOT NULL,
        $columnReceiverId      TEXT NOT NULL,
        $columnMessage         TEXT,
        $columnMessageType     TEXT NOT NULL DEFAULT 'text',
        $columnMediaUrl        TEXT,
        $columnThumbUrl        TEXT,                    -- NEW v5
        $columnLocalPath       TEXT,
        $columnTimestamp       INTEGER NOT NULL,
        $columnStatus          INTEGER NOT NULL DEFAULT 1,
        $columnFilename        TEXT,
        $columnFilesize        TEXT,
        $columnMetadata        TEXT,
        $columnDownloadProgress REAL NOT NULL DEFAULT 0.0,
        $columnUploadProgress   REAL NOT NULL DEFAULT 0.0, -- NEW v5
        $columnDownloadStatus   TEXT NOT NULL DEFAULT 'idle'
      )
    ''');

      await db.execute('''
      CREATE TABLE $tableUsers (
        $columnUid         TEXT PRIMARY KEY,
        $columnName        TEXT,
        $columnEmail       TEXT,
        $columnPhoneNumber TEXT,
        $columnPhotoURL    TEXT,
        $columnPhotoLocal  INTEGER NOT NULL DEFAULT 0,
        $columnAddress     TEXT,
        $columnCity        TEXT,
        $columnState       TEXT,
        $columnPinCode     TEXT,
        $columnLanguage    TEXT,
        $columnCreatedAt   INTEGER,
        $columnLastUpdated INTEGER,
        $columnIsDeleted   INTEGER NOT NULL DEFAULT 0,
        $columnDeletionPending INTEGER NOT NULL DEFAULT 0,
        $columnDeletionScheduledFor TEXT
      )
    ''');

      await _createIndexes(db);
      _log.fine('Database v$version created successfully');
    } catch (e) {
      _log.severe('Error creating tables: $e');
      rethrow;
    }
  }

  // ========= Upgrade =========
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // v2 migration — added address & timestamps
      if (oldVersion < 2) {
        await _addColumnSafely(db, tableUsers, columnAddress, 'TEXT');
        await _addColumnSafely(db, tableUsers, columnCity, 'TEXT');
        await _addColumnSafely(db, tableUsers, columnState, 'TEXT');
        await _addColumnSafely(db, tableUsers, columnPinCode, 'TEXT');
        await _addColumnSafely(db, tableUsers, columnCreatedAt, 'INTEGER');
        await _addColumnSafely(db, tableUsers, columnLastUpdated, 'INTEGER');
        await _addColumnSafely(db, tableMessages, columnMetadata, 'TEXT');
      }

      // v3 migration — added download tracking
      if (oldVersion < 3) {
        await _addColumnSafely(db, tableMessages, columnDownloadProgress, 'REAL NOT NULL DEFAULT 0.0');
        await _addColumnSafely(db, tableMessages, columnDownloadStatus, "TEXT NOT NULL DEFAULT 'idle'");
      }

      // ✅ v4 migration — add soft delete support to users
      if (oldVersion < 4) {
        await _addColumnSafely(db, tableUsers, columnIsDeleted, 'INTEGER NOT NULL DEFAULT 0');
        await _addColumnSafely(db, tableUsers, columnDeletionPending, 'INTEGER NOT NULL DEFAULT 0');
        await _addColumnSafely(db, tableUsers, columnDeletionScheduledFor, 'TEXT');
        _log.info('✅ v4 migration complete — added soft delete columns to users');
      }

      // ✅ v5 migration — tempId, serverId, thumbUrl, uploadProgress
      if (oldVersion < 5) {
        await _addColumnSafely(db, tableMessages, columnTempId, 'TEXT');
        await _addColumnSafely(db, tableMessages, columnServerId, 'TEXT');
        await _addColumnSafely(db, tableMessages, columnThumbUrl, 'TEXT');
        await _addColumnSafely(db, tableMessages, columnUploadProgress, 'REAL NOT NULL DEFAULT 0.0');
        _log.info('✅ v5 migration complete - Added chat system columns');
      }

      await _createIndexes(db);
      _log.fine('✅ Database upgraded successfully from v$oldVersion → v$newVersion');
    } catch (e) {
      _log.severe('❌ Upgrade failed: $e');
      rethrow;
    }
  }

  Future<void> _addColumnSafely(Database db, String table, String column, String type) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    } catch (e) {
      if (!e.toString().contains('duplicate column name')) {
        _log.warning('Failed to add column $column on $table: $e');
        rethrow;
      }
    }
  }

  Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_conversation_timestamp ON $tableMessages ($columnConversationId, $columnTimestamp)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_message_status ON $tableMessages ($columnStatus)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sender_receiver ON $tableMessages ($columnSenderId, $columnReceiverId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_download_status ON $tableMessages ($columnDownloadStatus)');
      // new v5 indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tempId ON $tableMessages ($columnTempId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_serverId ON $tableMessages ($columnServerId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_messageType ON $tableMessages ($columnMessageType)');
    } catch (e) {
      _log.warning('Index creation failed: $e');
    }
  }

  // ========= Users CRUD =========
  Future<int> insertUser(UserModel user) async {
    if (user.uid.isEmpty) throw ArgumentError("UID cannot be empty");
    final db = await database;
    return await db.insert(tableUsers, user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(String uid) async {
    if (uid.isEmpty) return null;
    final db = await database;
    final rows = await db.query(tableUsers, where: '$columnUid = ?', whereArgs: [uid], limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<int> updateUser(UserModel user) async {
    if (user.uid.isEmpty) throw ArgumentError("UID cannot be empty");
    final db = await database;
    return await db.update(tableUsers, user.toMap(), where: '$columnUid = ?', whereArgs: [user.uid]);
  }

  Future<int> deleteUser(String uid) async {
    if (uid.isEmpty) return 0;
    final db = await database;
    return await db.delete(tableUsers, where: '$columnUid = ?', whereArgs: [uid]);
  }

  // ========= Messages CRUD =========
  Future<int> insertMessage(Map<String, dynamic> messageMap) async {
    _coerceAndValidateMessageData(messageMap);
    final db = await database;
    // avoid empty local_path writes + optional file check
    final lp = (messageMap[columnLocalPath]?.toString() ?? '');
    if (lp.isEmpty) {
      messageMap.remove(columnLocalPath);
    } else {
      try { if (!await File(lp).exists()) messageMap.remove(columnLocalPath); } catch (_) {}
    }
    return await db.insert(tableMessages, messageMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMessages(
      String conversationId, {
        int limit = 30,
        int? lastTimestamp,
      }) async {
    if (conversationId.isEmpty) return [];
    final db = await database;

    final where = lastTimestamp != null
        ? '$columnConversationId = ? AND $columnTimestamp < ?'
        : '$columnConversationId = ?';
    final args = lastTimestamp != null ? [conversationId, lastTimestamp] : [conversationId];

    return await db.query(
      tableMessages,
      where: where,
      whereArgs: args,
      orderBy: '$columnTimestamp DESC',
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> getMessage(String messageId) async {
    if (messageId.isEmpty) return null;
    final db = await database;
    final rows = await db.query(tableMessages, where: '$columnMessageId = ?', whereArgs: [messageId], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> updateMessage(String messageId, Map<String, dynamic> updates) async {
    if (messageId.isEmpty) return 0;
    final db = await database;
    // avoid empty local_path writes + optional file check
    final lp = (updates[columnLocalPath]?.toString() ?? '');
    if (lp.isEmpty) {
      updates.remove(columnLocalPath);
    } else {
      try { if (!await File(lp).exists()) updates.remove(columnLocalPath); } catch (_) {}
    }
    return await db.update(tableMessages, updates, where: '$columnMessageId = ?', whereArgs: [messageId]);
  }

  Future<int> updateMessageStatus(String messageId, int status) async {
    if (messageId.isEmpty) return 0;
    final db = await database;
    return await db.update(
      tableMessages,
      {columnStatus: status},
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<String?> getMediaPath(String messageId) async {
    if (messageId.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      tableMessages,
      columns: [columnLocalPath],
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first[columnLocalPath] as String?;
  }

  Future<int> updateMediaPath(String messageId, String localPath) async {
    if (messageId.isEmpty) return 0;
    final db = await database;
    final value = localPath.isEmpty
        ? null
        : (await File(localPath).exists() ? localPath : null);
    return await db.update(tableMessages, {columnLocalPath: value}, where: '$columnMessageId = ?', whereArgs: [messageId]);
  }

  Future<int> deleteMessage(String messageId) async {
    if (messageId.isEmpty) return 0;
    final db = await database;
    return await db.delete(tableMessages, where: '$columnMessageId = ?', whereArgs: [messageId]);
  }

  Future<Map<String, dynamic>?> getLastMessage(String conversationId) async {
    if (conversationId.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      tableMessages,
      where: '$columnConversationId = ?',
      whereArgs: [conversationId],
      orderBy: '$columnTimestamp DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  // ========= Download progress/status =========
  Future<int> updateDownloadProgress(String messageId, double progress) async {
    if (messageId.isEmpty) return 0;
    final db = await database;
    final p = progress.clamp(0.0, 1.0);
    return await db.update(
      tableMessages,
      {columnDownloadProgress: p},
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<double?> getDownloadProgress(String messageId) async {
    if (messageId.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      tableMessages,
      columns: [columnDownloadProgress],
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final val = rows.first[columnDownloadProgress];
    return val is num ? val.toDouble() : 0.0;
  }

  Future<int> updateDownloadStatus(String messageId, String status) async {
    if (messageId.isEmpty) return 0;
    final db = await database;
    return await db.update(
      tableMessages,
      {columnDownloadStatus: status},
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<String?> getDownloadStatus(String messageId) async {
    if (messageId.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      tableMessages,
      columns: [columnDownloadStatus],
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first[columnDownloadStatus] as String?;
  }

  // ========= Upload progress / server linking (v5 helpers) =========

  /// Get message by tempId (for local tracking)
  Future<Map<String, dynamic>?> getMessageByTempId(String tempId) async {
    if (tempId.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      tableMessages,
      where: '$columnTempId = ?',
      whereArgs: [tempId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Get message by serverId (for server tracking)
  Future<Map<String, dynamic>?> getMessageByServerId(String serverId) async {
    if (serverId.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      tableMessages,
      where: '$columnServerId = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Link tempId to serverId (update after server ACK)
  Future<int> linkTempToServer(String tempId, String serverId) async {
    if (tempId.isEmpty || serverId.isEmpty) return 0;
    final db = await database;
    return await db.update(
      tableMessages,
      {columnServerId: serverId},
      where: '$columnTempId = ?',
      whereArgs: [tempId],
    );
  }

  /// Update upload progress (accepts messageId OR tempId)
  Future<int> updateUploadProgress(String messageIdOrTempId, double progress) async {
    if (messageIdOrTempId.isEmpty) return 0;
    final db = await database;
    final p = (progress.clamp(0.0, 100.0) as num).toDouble();
    return await db.update(
      tableMessages,
      {columnUploadProgress: p},
      where: '$columnMessageId = ? OR $columnTempId = ?',
      whereArgs: [messageIdOrTempId, messageIdOrTempId],
    );
  }

  /// Update after successful upload
  Future<int> updateAfterUpload({
    required String tempId,
    String? cdnUrl,
    String? thumbUrl,
    required double uploadProgress,
  }) async {
    if (tempId.isEmpty) return 0;
    final db = await database;
    final p = (uploadProgress.clamp(0.0, 100.0) as num).toDouble();
    final data = <String, dynamic>{ columnUploadProgress: p };
    if (cdnUrl != null) data[columnMediaUrl] = cdnUrl;
    if (thumbUrl != null) data[columnThumbUrl] = thumbUrl;
    return await db.update(
      tableMessages,
      data,
      where: '$columnTempId = ?',
      whereArgs: [tempId],
    );
  }

  // ========= File utilities =========
  Future<bool> checkFileExists(String filePath) async {
    if (filePath.isEmpty) return false;
    try {
      return await File(filePath).exists();
    } catch (e) {
      _log.warning('File check failed for $filePath: $e');
      return false;
    }
  }

  Future<int> resetDownloadProgress(String messageId) async {
    if (messageId.isEmpty) return 0;
    final db = await database;
    return await db.update(
      tableMessages,
      {columnDownloadProgress: 0.0, columnDownloadStatus: 'idle'},
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Map<String, dynamic>>> getDownloadingMessages() async {
    final db = await database;
    return await db.query(
      tableMessages,
      where: '$columnDownloadStatus = ?',
      whereArgs: ['downloading'],
      orderBy: '$columnTimestamp DESC',
    );
  }

  Future<int> cleanupStaleDownloads() async {
    final db = await database;
    return await db.update(
      tableMessages,
      {columnDownloadStatus: 'idle', columnDownloadProgress: 0.0},
      where: '$columnDownloadStatus = ?',
      whereArgs: ['downloading'],
    );
  }

  // ========= Batch ops =========
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    // ✅ Pointer model: read अब pointer से handle होगा, DB write नहीं।
    if (messageIds.isEmpty) return;
    _log.info("ℹ️ markMessagesAsRead skipped (pointer model active)");
  }

  Future<void> insertMessagesBatch(List<Map<String, dynamic>> messages) async {
    if (messages.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final messageMap in messages) {
        _coerceAndValidateMessageData(messageMap);
        final lp = (messageMap[columnLocalPath]?.toString() ?? '');
        if (lp.isEmpty) {
          messageMap.remove(columnLocalPath);
        } else {
          try { if (!await File(lp).exists()) messageMap.remove(columnLocalPath); } catch (_) {}
        }
        batch.insert(tableMessages, messageMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  // ========= Stats / Search / Maintenance =========
  Future<int> getMessageCount(String conversationId) async {
    if (conversationId.isEmpty) return 0;
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableMessages WHERE $columnConversationId = ?',
      [conversationId],
    )) ?? 0;
  }

  Future<int> getUnreadMessageCount(String conversationId, String currentUserId) async {
    if (conversationId.isEmpty || currentUserId.isEmpty) return 0;
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableMessages WHERE $columnConversationId = ? AND $columnSenderId != ? AND $columnStatus < 3',
      [conversationId, currentUserId],
    )) ?? 0;
  }

  Future<List<Map<String, dynamic>>> searchMessages(
      String conversationId,
      String searchQuery, {
        int limit = 50,
      }) async {
    if (conversationId.isEmpty || searchQuery.isEmpty) return [];
    final db = await database;
    return await db.query(
      tableMessages,
      where: '$columnConversationId = ? AND $columnMessage LIKE ?',
      whereArgs: [conversationId, '%$searchQuery%'],
      orderBy: '$columnTimestamp DESC',
      limit: limit,
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableUsers);
      await txn.delete(tableMessages);
    });
  }

  /// ✅ Clears all local tables (users + messages)
  /// Called during logout to wipe sensitive data
  Future<void> clearLocalCache() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(tableUsers);
        await txn.delete(tableMessages);
      });
      _log.info('🧹 Local cache cleared successfully (users + messages)');
    } catch (e) {
      _log.severe('❌ Error clearing local cache: $e');
    }
  }

  Future<void> clearOldMessages({int days = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffMs = TimestampUtils.toMilliseconds(cutoff);
    await db.delete(tableMessages, where: '$columnTimestamp < ?', whereArgs: [cutoffMs]);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ========= Validation =========
  void _coerceAndValidateMessageData(Map<String, dynamic> map) {
    // ✅ Either messageId OR tempId required
    final messageId = map[columnMessageId];
    final tempId = map[columnTempId];

    if ((messageId == null || (messageId is String && messageId.isEmpty)) &&
        (tempId == null || (tempId is String && tempId.isEmpty))) {
      throw ArgumentError("Either $columnMessageId or $columnTempId must be provided");
    }

    final req = [columnConversationId, columnSenderId, columnReceiverId, columnTimestamp];
    for (final f in req) {
      final v = map[f];
      if (v == null || (v is String && v.isEmpty)) {
        throw ArgumentError("Required field $f cannot be empty");
      }
    }

    // ensure timestamp is int (ms)
    final ts = map[columnTimestamp];
    if (ts is! int) {
      if (ts is String) {
        final parsed = int.tryParse(ts.trim());
        if (parsed == null) {
          throw ArgumentError('timestamp must be milliseconds (int)');
        }
        map[columnTimestamp] = parsed;
      } else {
        // as a last resort, try to coerce via utils
        map[columnTimestamp] = TimestampUtils.toMilliseconds(ts);
      }
    }
  }

  // ========= Debug =========
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableUsers')) ?? 0;
    final messageCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableMessages')) ?? 0;
    final downloadingCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableMessages WHERE $columnDownloadStatus = ?', ['downloading']),
    ) ?? 0;

    return {
      'database_version': _databaseVersion,
      'user_count': userCount,
      'message_count': messageCount,
      'downloading_count': downloadingCount,
      'database_path': join((await getApplicationDocumentsDirectory()).path, _databaseName),
    };
  }

  Future<void> deleteDatabaseFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = join(dir.path, _databaseName);
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
        _log.info('🗑️ Database file deleted: $dbPath');
      }
      _database = null;
    } catch (e) {
      _log.severe('❌ Error deleting database file: $e');
    }
  }
}
