// lib/chat/screens/chat_list/chat_list_screen.dart
// v1.2-chat_list_screen · 2025-10-26T03:15 IST
// Updated ChatListScreen:
// - Adds _openChat(...) navigation wired to singletons
// - Defensive presence stream handling
// - Uses ChatService.instance and MessageRepository.instance (no new handler creation)

import 'dart:async';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bargain/chat/services/chat_service.dart';
import 'package:bargain/chat/model/conversation_summary.dart';
import 'package:bargain/chat/utils/timestamp_utils.dart';
import 'package:bargain/chat/chat_widgets/profile_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bargain/chat/screens/chat_screen/chat_screen.dart';
import 'package:bargain/chat/repository/message_repository.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const ChatListScreen({super.key, this.onBackToHome});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _chatService = ChatService.instance;
  final _searchCtrl = TextEditingController();

  String? _currentUserId;
  String _query = '';
  bool _isSearching = false;
  bool _initLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  Future<void> _init() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      setState(() {
        _currentUserId = uid;
        _initLoading = false;
      });
    } catch (_) {
      setState(() => _initLoading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  // -------------------------------
  // Navigation: Open chat screen
  // -------------------------------
  void _openChat(ConversationSummary s) {
    if (_currentUserId == null) {
      // defensive: user not signed in
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please sign in to open chat.'),
      ));
      return;
    }

    // obtain shared singletons (use existing instances; do not create new ones)
    final messageRepo = MessageRepository.instance;
    final chatService = ChatService.instance;

    // try to access ws handlers if exposed; fall back to null (ChatScreen constructor expects them)
    dynamic wsMessageHandler;
    dynamic wsAckHandler;
    try {
      wsMessageHandler = (chatService as dynamic).wsMessageHandler;
    } catch (_) {
      wsMessageHandler = null;
    }
    try {
      wsAckHandler = (chatService as dynamic).wsAckHandler;
    } catch (_) {
      wsAckHandler = null;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        conversationId: s.conversationId,
        currentUserId: _currentUserId!,
        chatService: chatService,
        messageRepository: messageRepo,
        wsMessageHandler: wsMessageHandler,
        wsAckHandler: wsAckHandler,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.onBackToHome != null) {
          widget.onBackToHome!();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor(theme),
        appBar: SectionAppBar(
          title: "Messages",
          onBack: () {
            debugPrint("🔙 ChatListScreen: Back button pressed");
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        body: Column(
          children: [
            // Header row with search icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chats",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(theme),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    color: AppTheme.iconColor(theme),
                    tooltip: _isSearching ? "Close search" : "Search",
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchCtrl.clear();
                          _query = '';
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Search bar
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceColor(theme),
                    hintText: 'Search conversations…',
                    hintStyle: TextStyle(color: AppTheme.textSecondary(theme)),
                    prefixIcon: Icon(Icons.search, color: AppTheme.iconColor(theme).withOpacity(0.8)),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor(theme)),
                    ),
                  ),
                ),
              ),

            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_initLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentUserId == null) {
      return _buildError(theme, "You're not signed in. Please login to see your messages.");
    }

    return RefreshIndicator(
      color: AppTheme.primaryAccent(theme),
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: StreamBuilder<List<ConversationSummary>>(
        stream: _chatService.watchConversations(currentUserId: _currentUserId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ListTileSkeleton();
          }
          if (snap.hasError) {
            return _buildError(theme, 'Something went wrong');
          }

          final list = (snap.data ?? <ConversationSummary>[])
              .where((c) {
            if (_query.isEmpty) return true;
            final nm = (c.peerName ?? c.peerId).toLowerCase();
            return nm.contains(_query);
          })
              .toList();

          if (list.isEmpty) return _buildEmpty(theme);

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.borderColor(theme).withOpacity(0.2),
            ),
            itemBuilder: (context, i) => _buildTile(theme, list[i]),
          );
        },
      ),
    );
  }

  Widget _buildTile(ThemeData theme, ConversationSummary s) {
    final title = s.peerName ?? s.peerId;
    final subtitle = s.lastMessageText.isNotEmpty
        ? s.lastMessageText
        : (s.lastMessageType == 'image'
        ? '📷 Photo'
        : s.lastMessageType == 'video'
        ? '🎬 Video'
        : s.lastMessageType == 'audio'
        ? '🎤 Voice message'
        : '');
    final timeText = TimestampUtils.formatLastMessageTime(s.lastUpdated);
    final isDeleted = s.isPeerDeleted == true;

    return Container(
      color: AppTheme.surfaceColor(theme),
      child: InkWell(
        onTap: isDeleted ? null : () => _openChat(s),
        splashColor: AppTheme.primaryAccent(theme).withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  ProfileAvatar.chatListItem(
                    imageUrl: s.peerPhoto,
                    name: title,
                    userId: s.peerId,
                    isOnline: s.isPeerOnline,
                    onTap: isDeleted ? null : () => _openChat(s),
                    desaturate: isDeleted,
                  ),
                  if (isDeleted)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeleted ? '$title (Suspended)' : title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDeleted
                            ? AppTheme.textSecondary(theme).withOpacity(0.6)
                            : AppTheme.textPrimary(theme),
                        fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (isDeleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: Text(
                          'Account suspended',
                          style: TextStyle(
                            color: Colors.redAccent.withOpacity(0.85),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      isDeleted ? 'You can no longer message this user' : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDeleted
                            ? AppTheme.textSecondary(theme).withOpacity(0.5)
                            : AppTheme.textSecondary(theme),
                        fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Time + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary(theme).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isDeleted)
                    Text(
                      'Suspended',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    StreamBuilder<Map<String, dynamic>>(
                      // filter presenceChanges to this peerId
                      stream: ChatService.instance.presenceChanges
                          .where((m) => (m['userId']?.toString() ?? '') == s.peerId),
                      builder: (context, snap) {
                        final online = (snap.data?['isOnline'] == true) || s.isPeerOnline;
                        int? lastSeenMs;
                        final ls = snap.data?['lastSeen'];
                        if (ls is Timestamp) {
                          lastSeenMs = ls.millisecondsSinceEpoch;
                        } else if (ls is int) {
                          lastSeenMs = ls;
                        } else {
                          lastSeenMs = s.peerLastSeenMs;
                        }

                        final statusText = online
                            ? 'Online'
                            : (lastSeenMs != null
                            ? TimestampUtils.formatLastSeen(DateTime.fromMillisecondsSinceEpoch(lastSeenMs))
                            : 'Offline');

                        return Text(
                          statusText,
                          style: TextStyle(fontSize: 12, color: online ? Colors.green : Colors.grey),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppTheme.errorColor(theme)),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary(theme))),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent(theme)),
              onPressed: _init,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: AppTheme.textSecondary(theme)),
            const SizedBox(height: 16),
            Text(
              _query.isEmpty ? 'No conversations yet' : 'No matching conversations',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary(theme)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _query.isEmpty ? 'Pull to refresh or start a new chat.' : 'Try different keywords.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary(theme)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTileSkeleton extends StatelessWidget {
  const _ListTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.borderColor(theme).withOpacity(0.3)),
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: AppTheme.surfaceColor(theme), shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 14, color: AppTheme.surfaceColor(theme)),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 160, color: AppTheme.surfaceColor(theme)),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(height: 10, width: 60, color: AppTheme.surfaceColor(theme)),
                const SizedBox(height: 6),
                Container(height: 10, width: 50, color: AppTheme.surfaceColor(theme)),
              ]),
            ],
          ),
        );
      },
    );
  }
}
