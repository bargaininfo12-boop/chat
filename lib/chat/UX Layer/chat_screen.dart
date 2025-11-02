import 'dart:async';
import 'dart:io';
import 'package:bargain/chat/Chat_widgets/media_picker_helper.dart';
import 'package:bargain/chat/Core%20Services/cdn_uploader.dart';
import 'package:bargain/chat/Core%20Services/chat_service.dart';
import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';
import 'package:bargain/chat/UX%20Layer/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

import 'package:bargain/services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
    _loadInitialMessages();
  }

  void _subscribeToMessages() {
    _messageSubscription = ChatService.instance.messageStream.listen((message) {
      if (message.conversationId == widget.conversationId) {
        _handleNewMessage(message);
      }
    });
  }

  void _handleNewMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> _loadInitialMessages() async {
    final messages = await ChatService.instance.getMessages(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.addAll(messages.reversed);
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final senderId = UserService().currentUser?.uid;
    if (senderId == null) return;

    final tmpId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: tmpId,
      conversationId: widget.conversationId,
      senderId: senderId,
      receiverId: widget.receiverId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.insert(0, message);
      _textController.clear();
    });

    await ChatService.instance.sendMessage(message);
  }

  Future<void> _sendMediaMessage(File file, MediaType type) async {
    final senderId = UserService().currentUser?.uid;
    if (senderId == null) return;

    final mime = CdnUploader.detectMime(file);
    final signedInfo = await ChatService.instance.getSignedInfo(); // Your backend call
    final uploadedUrl = await CdnUploader.uploadFile(
      file: file,
      mime: mime,
      signedInfo: signedInfo,
    );
    if (uploadedUrl == null) return;

    final tmpId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: tmpId,
      conversationId: widget.conversationId,
      senderId: senderId,
      receiverId: widget.receiverId,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      imageUrl: type == MediaType.image ? uploadedUrl : null,
      videoUrl: type == MediaType.video ? uploadedUrl : null,
      audioUrl: type == MediaType.audio ? uploadedUrl : null,
    );

    setState(() {
      _messages.insert(0, message);
    });

    await ChatService.instance.sendMessage(message);
  }

  Future<void> _handleImagePick() async {
    final images = await MediaPickerHelper.pickAndCropMultiple(context);
    for (final img in images) {
      await _sendMediaMessage(img, MediaType.image);
    }
  }

  Future<void> _handleVideoPick() async {
    final video = await MediaPickerHelper.pickVideo();
    if (video != null) {
      await _sendMediaMessage(video, MediaType.video);
    }
  }

  Future<void> _handleVoiceSend() async {
    // Placeholder: integrate recorder and pass audio file
    final dummyAudio = File('path/to/audio.aac'); // Replace with actual recorded file
    await _sendMediaMessage(dummyAudio, MediaType.audio);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(theme),
        border: Border(top: BorderSide(color: AppTheme.dividerColor(theme))),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image), onPressed: _handleImagePick),
          IconButton(icon: const Icon(Icons.videocam), onPressed: _handleVideoPick),
          IconButton(icon: const Icon(Icons.mic), onPressed: _handleVoiceSend),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendTextMessage,
            color: AppTheme.primaryColor(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == UserService().currentUser?.uid;
        return MessageBubble(message: message, isMe: isMe);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: AppTheme.primaryColor(theme),
        foregroundColor: AppTheme.textOnPrimary(theme),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(context)),
          _buildMessageInput(context),
        ],
      ),
    );
  }
}
