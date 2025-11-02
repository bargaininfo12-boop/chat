import 'package:bargain/chat/Core%20Services/chat_service.dart';
import 'package:bargain/chat/Local Database Layer/chat_database_helper.dart';
import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';

class MessageRepository {
  MessageRepository._internal();
  static final MessageRepository instance = MessageRepository._internal();

  /// Save message to local database
  Future<void> saveMessageLocally(ChatMessage message) async {
    await ChatDatabaseHelper().insertMessage(message);
  }

  /// Send message via WebSocket or fallback
  Future<void> sendMessage(ChatMessage message) async {
    await saveMessageLocally(message);
    await ChatService.instance.sendMessage(message);
  }

  /// Fetch all messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    return await ChatDatabaseHelper().getMessages(conversationId);
  }

  /// Optional: update message status
  Future<void> updateMessage(ChatMessage message) async {
    await ChatDatabaseHelper().updateMessage(message);
  }

  /// Optional: delete message
  Future<void> deleteMessage(String id) async {
    await ChatDatabaseHelper().deleteMessage(id);
  }

  /// Optional: clear all messages
  Future<void> clearAllMessages() async {
    await ChatDatabaseHelper().clearAllMessages();
  }

  /// ✅ Dispose any listeners or cleanup
  Future<void> dispose() async {
    await ChatService.instance.dispose();
  }
}
