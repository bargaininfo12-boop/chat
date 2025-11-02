import 'dart:io';
import 'package:bargain/chat/Core%20Services/chat_service.dart';
import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:bargain/chat/utils/media_uploader.dart';

class MessageInputField extends StatefulWidget {
  final String conversationId;
  final String senderId;
  final String receiverId;

  const MessageInputField({
    super.key,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  Future<void> _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(
      id: const Uuid().v4(),
      conversationId: widget.conversationId,
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    _controller.clear();
    await ChatService.instance.sendMessage(message);
  }

  Future<void> _sendMediaMessage({
    required XFile file,
    required MediaType mediaType,
  }) async {
    setState(() => _isSending = true);

    try {
      final signedInfo = await ChatService.instance.getSignedInfo();
      final cdnUrl = await MediaUploader.uploadFile(
        file: File(file.path),
        signedInfo: signedInfo,
      );

      final message = ChatMessage(
        id: const Uuid().v4(),
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        imageUrl: mediaType == MediaType.image ? cdnUrl : null,
        videoUrl: mediaType == MediaType.video ? cdnUrl : null,
        audioUrl: mediaType == MediaType.audio ? cdnUrl : null,
      );

      await ChatService.instance.sendMessage(message);
    } catch (e) {
      debugPrint('❌ Media send failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send media')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      await _sendMediaMessage(file: file, mediaType: MediaType.image);
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      await _sendMediaMessage(file: file, mediaType: MediaType.video);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _pickVideo,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextMessage(),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.send),
            onPressed: _isSending ? null : _sendTextMessage,
          ),
        ],
      ),
    );
  }
}
