import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatDatabaseHelper {
  static final ChatDatabaseHelper _instance = ChatDatabaseHelper._internal();
  factory ChatDatabaseHelper() => _instance;
  ChatDatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'chat.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT,
        senderId TEXT,
        receiverId TEXT,
        text TEXT,
        imageUrl TEXT,
        videoUrl TEXT,
        audioUrl TEXT,
        cdnUrl TEXT,
        thumbUrl TEXT,
        localPath TEXT,
        uploadProgress INTEGER,
        timestamp TEXT,
        status INTEGER
      )
    ''');
  }

  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
    );
    return result.map((row) => ChatMessage.fromMap(row)).toList();
  }

  Future<List<ChatMessage>> getAllMessages() async {
    final db = await database;
    final result = await db.query('messages');
    return result.map((row) => ChatMessage.fromMap(row)).toList();
  }

  Future<void> updateMessage(ChatMessage message) async {
    final db = await database;
    await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  Future<void> linkTempToServer(String tempId, String serverId) async {
    final db = await database;
    await db.update(
      'messages',
      {'id': serverId},
      where: 'id = ?',
      whereArgs: [tempId],
    );
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': _statusToInt(status)},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  int _statusToInt(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return 1;
      case 'delivered':
        return 2;
      case 'read':
        return 3;
      default:
        return 0;
    }
  }

  Future<Map<String, dynamic>?> getMessageByServerId(String serverId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getMessageByTempId(String tempId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [tempId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateMessageAfterUpload({
    required String tempId,
    String? cdnUrl,
    String? thumbUrl,
    int? uploadProgress,
  }) async {
    final db = await database;
    await db.update(
      'messages',
      {
        if (cdnUrl != null) 'cdnUrl': cdnUrl,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        if (uploadProgress != null) 'uploadProgress': uploadProgress,
      },
      where: 'id = ?',
      whereArgs: [tempId],
    );
  }

  Future<void> saveMessage(Map<String, dynamic> raw) async {
    final db = await database;
    await db.insert(
      'messages',
      raw,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
