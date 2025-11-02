import 'package:bargain/chat/Core%20Services/chat_service.dart';
import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';
import 'package:flutter/material.dart';

import 'package:bargain/chat/UX Layer/chat_screen.dart';
import 'package:bargain/app_theme/app_theme.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;
  const ChatListScreen({super.key, required this.currentUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatMessage> _latestMessages = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final allMessages = await ChatService.instance.getMessagesForAllConversations();
    final filtered = allMessages.where((msg) =>
    msg.senderId == widget.currentUserId || msg.receiverId == widget.currentUserId).toList();
    final grouped = _groupByConversation(filtered);
    setState(() {
      _latestMessages = grouped;
    });
  }

  List<ChatMessage> _groupByConversation(List<ChatMessage> messages) {
    final Map<String, ChatMessage> latestMap = {};
    for (final msg in messages) {
      final existing = latestMap[msg.conversationId];
      if (existing == null || msg.timestamp.isAfter(existing.timestamp)) {
        latestMap[msg.conversationId] = msg;
      }
    }
    return latestMap.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: AppTheme.primaryColor(theme),
        foregroundColor: AppTheme.textOnPrimary(theme),
      ),
      body: ListView.builder(
        itemCount: _latestMessages.length,
        itemBuilder: (context, index) {
          final message = _latestMessages[index];
          final isMe = message.senderId == widget.currentUserId;
          final peerId = isMe ? message.receiverId : message.senderId;
          final peerName = _getPeerName(message, isMe);

          return ListTile(
            leading: CircleAvatar(child: Text(peerName[0])),
            title: Text(peerName),
            subtitle: Text(_getPreviewText(message)),
            trailing: Text(_formatTimestamp(message.timestamp)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: message.conversationId,
                    receiverId: peerId,
                    receiverName: peerName,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getPeerName(ChatMessage message, bool isMe) {
    // TODO: Replace with actual user lookup if available
    return isMe ? message.receiverId : message.senderId;
  }

  String _getPreviewText(ChatMessage message) {
    if (message.text != null && message.text!.isNotEmpty) return message.text!;
    if (message.imageUrl != null) return '📷 Photo';
    if (message.videoUrl != null) return '🎥 Video';
    if (message.audioUrl != null) return '🎙️ Voice message';
    return 'New message';
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays >= 1) {
      return '${time.day}/${time.month}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
