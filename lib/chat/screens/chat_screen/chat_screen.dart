// v2.2-chat_screen · 2025-10-26T11:15 IST
// lib/chat/screens/chat_screen/chat_screen.dart
//
// Updated: Proper type declarations for all dependencies
// - Mounted guards for safe async setState
// - Correct ack stream source from wsAckHandler
// - Safer async operations with null checks

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bargain/chat/services/ws_message_handler.dart';
import 'package:bargain/chat/services/ws_ack_handler.dart';
import 'package:bargain/chat/services/chat_service.dart';
import 'package:bargain/chat/repository/message_repository.dart';

/// UI representation of a message
class UiMessage {
  String id; // mutable so serverId can replace tempId
  final String text;
  final String senderId;
  final DateTime createdAt;
  final bool isLocal;
  int status; // -1 failed, 0 pending, 1 sent, 2 delivered, 3 read

  UiMessage({
    required this.id,
    required this.text,
    required this.senderId,
    DateTime? createdAt,
    this.isLocal = false,
    this.status = 0,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Main chat screen widget
/// Requires all chat dependencies to be passed via constructor
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;

  // Concrete type declarations for better type safety
  final ChatService chatService;
  final MessageRepository messageRepository;
  final WsMessageHandler wsMessageHandler;
  final WsAckHandler wsAckHandler;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.currentUserId,
    required this.chatService,
    required this.messageRepository,
    required this.wsMessageHandler,
    required this.wsAckHandler,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<UiMessage> _messages = [];

  StreamSubscription? _msgSub;
  StreamSubscription? _ackSub;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start handlers (idempotent)
    try {
      widget.wsMessageHandler.start();
      widget.wsAckHandler.start();
    } catch (e) {
      debugPrint('⚠️ Handler start failed: $e');
    }

    // Listen to new incoming messages
    _msgSub = widget.wsMessageHandler.messageNew.listen(
          (m) {
        if (!mounted) return;
        _onRemoteMessage(m);
      },
      onError: (e) {
        debugPrint('❌ WsMessageHandler messageNew error: $e');
      },
    );

    // Listen to message acknowledgments (FIX: from wsAckHandler, not wsMessageHandler)
    _ackSub = widget.wsAckHandler.messageAck.listen(
          (ack) {
        if (!mounted) return;
        _onMessageAck(ack);
      },
      onError: (e) {
        debugPrint('❌ WsAckHandler messageAck error: $e');
      },
    );

    // Load recent messages from local DB
    _loadRecentMessages();
  }

  /// Load recent messages from repository/database
  Future<void> _loadRecentMessages() async {
    try {
      final rows = await widget.chatService.getMessagesForConversation(
        widget.conversationId,
        limit: 100,
      );

      if (!mounted) return;

      final List<UiMessage> loadedMessages = [];
      for (final row in rows.reversed) {
        try {
          final msg = UiMessage(
            id: row['id']?.toString() ?? UniqueKey().toString(),
            text: row['text']?.toString() ?? '',
            senderId: row['senderId']?.toString() ?? 'unknown',
            createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? '') ?? DateTime.now(),
            isLocal: row['senderId']?.toString() == widget.currentUserId,
            status: _parseStatus(row['status']),
          );
          loadedMessages.add(msg);
        } catch (e) {
          debugPrint('⚠️ Error parsing message row: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _messages.addAll(loadedMessages);
      });

      debugPrint('✅ Loaded ${loadedMessages.length} messages');
    } catch (e) {
      debugPrint('⚠️ loadRecentMessages error: $e');
    }
  }

  /// Parse status from various formats (int, string, null)
  int _parseStatus(dynamic status) {
    if (status == null) return 1;
    if (status is int) return status;
    if (status is String) {
      if (status == 'sent') return 1;
      if (status == 'delivered') return 2;
      if (status == 'read') return 3;
      if (status == 'pending') return 0;
      if (status == 'failed') return -1;
      return int.tryParse(status) ?? 1;
    }
    return 1;
  }

  /// Handle incoming remote message
  void _onRemoteMessage(Map<String, dynamic> data) {
    try {
      final convId = data['conversationId']?.toString();
      if (convId != widget.conversationId) return;

      final serverId = data['serverId']?.toString() ??
          data['id']?.toString() ??
          UniqueKey().toString();
      final senderId = data['senderId']?.toString() ?? 'unknown';
      final text = data['text']?.toString() ?? '';
      final createdAtStr = data['createdAt']?.toString();

      DateTime createdAt = DateTime.now();
      if (createdAtStr != null) {
        try {
          createdAt = DateTime.parse(createdAtStr);
        } catch (_) {
          createdAt = DateTime.now();
        }
      }

      final msg = UiMessage(
        id: serverId,
        text: text,
        senderId: senderId,
        createdAt: createdAt,
        isLocal: false,
        status: 1, // Remote messages are at least "sent"
      );

      if (!mounted) return;
      setState(() {
        // Check for duplicates before adding
        final exists = _messages.any((m) => m.id == serverId);
        if (!exists) {
          _messages.insert(0, msg);
        }
      });
      _scrollToBottomIfNeeded();

      debugPrint('✅ Received remote message: ${msg.id}');
    } catch (e) {
      debugPrint('❌ Error in _onRemoteMessage: $e');
    }
  }

  /// Handle message acknowledgment (status updates)
  void _onMessageAck(Map<String, dynamic> ack) {
    try {
      final tempId = ack['tempId']?.toString();
      final serverId = ack['serverId']?.toString();
      final statusRaw = ack['status'];

      int status = 1;
      if (statusRaw is int) {
        status = statusRaw;
      } else if (statusRaw is String) {
        status = _parseStatus(statusRaw);
      }

      // Try to find by tempId first (for local messages awaiting server confirmation)
      if (tempId != null && tempId.isNotEmpty) {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          if (!mounted) return;
          setState(() {
            // Replace tempId with serverId if available
            if (serverId != null && serverId.isNotEmpty) {
              _messages[idx].id = serverId;
            }
            _messages[idx].status = status;
          });
          debugPrint('✅ Updated message by tempId: $tempId -> $serverId (status: $status)');
          return;
        }
      }

      // Try to find by serverId (for messages already confirmed)
      if (serverId != null && serverId.isNotEmpty) {
        final idxServer = _messages.indexWhere((m) => m.id == serverId);
        if (idxServer != -1) {
          if (!mounted) return;
          setState(() {
            _messages[idxServer].status = status;
          });
          debugPrint('✅ Updated message by serverId: $serverId (status: $status)');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _onMessageAck: $e');
    }
  }

  /// Send text message
  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;
    setState(() => _isSending = true);

    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = UiMessage(
      id: tempId,
      text: text,
      senderId: widget.currentUserId,
      isLocal: true,
      status: 0, // Pending
    );

    if (!mounted) return;
    setState(() {
      _messages.insert(0, localMsg);
      _textController.clear();
    });
    _scrollToBottomIfNeeded();

    try {
      // Send via WebSocket
      await widget.wsMessageHandler.sendEvent('message.send', {
        'tempId': tempId,
        'conversationId': widget.conversationId,
        'senderId': widget.currentUserId,
        'text': text,
        'contentType': 'text',
        'meta': {},
      });

      debugPrint('✅ Message sent with tempId: $tempId');
      // Keep waiting for ack to update status to sent/delivered
    } catch (e) {
      debugPrint('❌ Send failed: $e');
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        setState(() => _messages[idx].status = -1); // Failed
      }
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  /// Scroll to bottom when new messages arrive
  void _scrollToBottomIfNeeded() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgSub?.cancel();
    _ackSub?.cancel();

    try {
      widget.wsMessageHandler.stop();
    } catch (_) {}

    try {
      widget.wsAckHandler.stop();
    } catch (_) {}

    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(theme)),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  /// Build messages list view
  Widget _buildMessagesList(ThemeData theme) {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, idx) {
        final m = _messages[idx];
        final mine = m.senderId == widget.currentUserId;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: mine ? Colors.blueAccent : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        m.text,
                        style: TextStyle(
                          color: mine ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(m.createdAt),
                            style: TextStyle(
                              color: mine ? Colors.white70 : Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (mine) _buildStatusIcon(m.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build status icon based on message status
  Widget _buildStatusIcon(int status) {
    switch (status) {
      case -1: // Failed
        return const Icon(Icons.error_outline, size: 14, color: Colors.redAccent);
      case 0: // Pending
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case 1: // Sent
        return const Icon(Icons.check, size: 14, color: Colors.white70);
      case 2: // Delivered
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case 3: // Read
        return const Icon(Icons.done_all, size: 14, color: Colors.greenAccent);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Build input bar at bottom
  Widget _buildInputBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                // TODO: Implement media attachment
              },
              icon: const Icon(Icons.attach_file_rounded),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            IconButton(
              onPressed: _isSending ? null : _sendText,
              icon: _isSending
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  /// Format time as HH:MM
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}