import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe
        ? AppTheme.primaryColor(theme).withOpacity(0.85)
        : AppTheme.surfaceColor(theme);
    final textColor = isMe
        ? AppTheme.textOnPrimary(theme)
        : AppTheme.textColor(theme);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildMessageContent(context, textColor),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    if (message.imageUrl != null) {
      return _buildImageMessage(context);
    } else if (message.videoUrl != null) {
      return _buildVideoMessage(context);
    } else if (message.audioUrl != null) {
      return _buildAudioMessage(context);
    } else {
      return Text(
        message.text ?? '',
        style: TextStyle(color: textColor, fontSize: 15),
      );
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Open full-screen image viewer
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text('❌ Failed to load image');
          },
        ),
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.videoUrl!,
            fit: BoxFit.cover,
            height: 180,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return const Text('❌ Failed to load video thumbnail');
            },
          ),
        ),
        const Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
      ],
    );
  }

  Widget _buildAudioMessage(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          'Voice message',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
