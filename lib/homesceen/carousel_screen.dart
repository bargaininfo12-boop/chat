// lib/homesceen/carousel_screen.dart
// v2.3-carousel_screen · 2025-10-26T03:30 IST
// Updated: defensive wiring for ChatScreen from CarouselScreen.
// - Resolves ChatService & MessageRepository safely
// - Prefer existing wsMessageHandler if exposed by ChatService
// - Construct WsMessageHandler from ChatService.wsClient when needed
// - Construct WsAckHandler(msgHandler, localDb)
// - Start/stop handlers; retry UI on failure

import 'dart:io';

import 'package:bargain/Database/Firebase_all/app_auth_provider.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/chat/services/chat_service.dart';
import 'package:bargain/chat/repository/message_repository.dart';
import 'package:bargain/chat/screens/chat_screen/chat_screen.dart';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:bargain/productadd/grid_layout/media_carousel.dart';
import 'package:bargain/productadd/grid_layout/image_like_card.dart';
import 'package:bargain/homesceen/seller_profile_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Chat WS handlers (defensive usage)
import 'package:bargain/chat/services/ws_message_handler.dart';
import 'package:bargain/chat/services/ws_ack_handler.dart';
import 'package:bargain/chat/services/chat_database_helper.dart';

final _logger = Logger();

class CarouselScreen extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> videoUrls;
  final ImageModel productDetails;

  const CarouselScreen({
    super.key,
    required this.imageUrls,
    required this.videoUrls,
    required this.productDetails,
  });

  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const String _guideKey = 'carousel_screen_guide_shown';
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  Map<String, dynamic>? _userData;
  bool _isLiked = false;
  int _likeCount = 0;

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserDetails();
    _scheduleGuide();

    final auth = context.read<AppAuthProvider>();
    _isLiked = widget.productDetails.likedBy.contains(auth.currentUserId);
    _likeCount = widget.productDetails.likeCount;
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  void _scheduleGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_guideKey)) {
      await prefs.setBool(_guideKey, true);
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      final sellerId = widget.productDetails.userId;
      final cached = await CustomCacheManager.loadJsonCache('seller_$sellerId', expiry: const Duration(hours: 24));
      if (cached != null && cached.isNotEmpty) {
        _userData = Map<String, dynamic>.from(cached.first);
        if (mounted) setState(() {});
      }

      final data = await _authService.getUserData(sellerId);
      if (data != null) {
        _userData = data;
        if (mounted) setState(() {});
        await CustomCacheManager.saveJsonCache('seller_$sellerId', data);
      }
    } catch (e) {
      _logger.e("User fetch error: $e");
    }
  }

  Future<void> _shareProduct() async {
    final p = widget.productDetails;
    final shareText = '''
🛍️ ${p.subcategory} for Sale
💰 Price: ₹${p.price ?? 'N/A'}
📍 Location: ${p.city ?? 'N/A'}, ${p.state ?? 'N/A'}
📝 ${p.description ?? 'No description available'}

View this product on Bargain App!
''';
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      shareText,
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final userId = context.read<AppAuthProvider>().currentUserId;
    final isOwner = userId == widget.productDetails.userId;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: widget.productDetails.subcategory,
        onBack: () => Navigator.pop(context),
        backgroundColor: AppTheme.appBarBackground(theme),
        foregroundColor: AppTheme.textPrimary(theme),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            color: AppTheme.iconColor(theme),
            onPressed: _shareProduct,
          ),
        ],
      ),

      floatingActionButton: isOwner
          ? null
          : FadeTransition(
        opacity: CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeIn),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
          child: FloatingActionButton(
            backgroundColor: AppTheme.primaryAccent(theme),
            elevation: 4,
            highlightElevation: 6,
            onPressed: _navigateToChat,
            child: Icon(Icons.chat_bubble_rounded, color: AppTheme.textOnPrimary(theme), size: 26),
          ),
        ),
      ),

      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) => ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildMediaSection(theme),
            _buildSellerCard(theme),
            _buildProductOverview(theme),
            _buildDescriptionCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(ThemeData theme) {
    return Stack(
      children: [
        MediaCarousel(
          imageUrls: widget.imageUrls,
          videoUrls: widget.videoUrls,
          height: 400,
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: AnimatedScale(
            scale: _isLiked ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ImageLikeCard(
              isLiked: _isLiked,
              likeCount: _likeCount,
              onTap: _toggleLike,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCard(ThemeData theme) {
    final name = _userData?['name'] ?? 'Unknown Seller';
    final photo = _userData?['photoURL'];
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer(theme),
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.cardShadow(theme),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: (photo != null && photo.isNotEmpty)
              ? NetworkImage(photo)
              : const AssetImage('assets/user.png') as ImageProvider,
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(theme),
          ),
        ),
        subtitle: Text(
          "Seller",
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary(theme),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textSecondary(theme)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerProfileScreen(userData: _userData, userId: widget.productDetails.userId),
          ),
        ),
      ),
    );
  }

  Widget _buildProductOverview(ThemeData theme) {
    final p = widget.productDetails;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh(theme),
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.cardShadow(theme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.subcategory,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryAccent(theme),
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 4),
          Text(p.category, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary(theme))),
          const SizedBox(height: 12),
          Text("₹${p.price ?? 'N/A'}",
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.successColor(theme),
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
    final p = widget.productDetails;
    final details = p.productDetails ?? {};
    final description = p.description;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh(theme),
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.cardShadow(theme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Product Details",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryAccent(theme),
                fontWeight: FontWeight.bold,
              )),
          Divider(color: AppTheme.outlineVariant(theme)),
          const SizedBox(height: 6),
          ...details.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${e.key}: ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(theme),
                    )),
                Expanded(
                  child: Text("${e.value}", style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary(theme))),
                ),
              ],
            ),
          )),
          if (description != null && description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: AppTheme.outlineVariant(theme)),
            const SizedBox(height: 6),
            Text("Description",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryAccent(theme),
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceContainerLow(theme), borderRadius: AppTheme.smallRadius),
              padding: const EdgeInsets.all(12),
              child: Text(
                description,
                textAlign: TextAlign.justify,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary(theme),
                  height: 1.5,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _navigateToChat() {
    final userId = context.read<AppAuthProvider>().currentUserId;
    if (userId == null) {
      _showSnackBar("User not identified", isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreenWrapper(
          currentUserId: userId,
          peerId: widget.productDetails.userId,
          peerName: _userData?['name'] ?? 'Seller',
          peerPhoto: _userData?['photoURL'],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor(theme) : AppTheme.successColor(theme),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}

/// ChatScreenWrapper
/// - Resolves ChatService & MessageRepository safely
/// - Constructs WsMessageHandler & WsAckHandler and starts them
/// - When ready, builds ChatScreen with required args
class ChatScreenWrapper extends StatefulWidget {
  final String currentUserId;
  final String peerId;
  final String peerName;
  final String? peerPhoto;

  const ChatScreenWrapper({
    super.key,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
    this.peerPhoto,
  });

  @override
  State<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends State<ChatScreenWrapper> {
  bool _loading = true;
  String? _error;
  ChatService? _chatService;
  MessageRepository? _messageRepo;
  WsMessageHandler? _wsMessageHandler;
  WsAckHandler? _wsAckHandler;
  final ChatDatabaseHelper _localDb = ChatDatabaseHelper();

  @override
  void initState() {
    super.initState();
    _wireUp();
  }

  Future<void> _wireUp() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Resolve singletons defensively
      try {
        _chatService = ChatService.instance;
      } catch (e) {
        _chatService = null;
      }
      try {
        _messageRepo = MessageRepository.instance;
      } catch (e) {
        _messageRepo = null;
      }

      if (_chatService == null || _messageRepo == null) {
        setState(() {
          _error = 'Chat service unavailable. Try restarting the app.';
          _loading = false;
        });
        return;
      }

      final convId = _deriveConversationId(widget.currentUserId, widget.peerId);

      // 1) Prefer an already-created message handler exposed by ChatService
      WsMessageHandler? msgHandler;
      try {
        final dynamic csDyn = _chatService!;
        if (csDyn.wsMessageHandler != null) {
          msgHandler = csDyn.wsMessageHandler as WsMessageHandler;
        }
      } catch (_) {}

      // 2) If not exposed, try to build from wsClient inside ChatService
      if (msgHandler == null) {
        try {
          final dynamic csDyn = _chatService!;
          final wsClient = csDyn.wsClient;
          if (wsClient != null) {
            msgHandler = WsMessageHandler(wsClient, logger: (m) => _logger.d('[WS] $m'));
          }
        } catch (_) {}
      }

      // 3) Fallback: try a parameterized constructor that accepts conversationId (some variants)
      if (msgHandler == null) {
        try {
          msgHandler = WsMessageHandler(_chatService! as dynamic, logger: (m) => _logger.d('[WS] $m'));
        } catch (_) {}
      }

      if (msgHandler == null) {
        setState(() {
          _error = 'Could not create WS message handler';
          _loading = false;
        });
        return;
      }

      // Ack handler expects (wsMessageHandler, localDb)
      WsAckHandler ackHandler;
      try {
        ackHandler = WsAckHandler(msgHandler, _localDb);
      } catch (e) {
        _logger.e('WsAckHandler construction failed: $e');
        setState(() {
          _error = 'Could not create WS ack handler';
          _loading = false;
        });
        return;
      }

      // Start handlers (defensive)
      try {
        msgHandler.start();
      } catch (e) {
        _logger.w('WsMessageHandler.start failed: $e');
      }
      try {
        ackHandler.start();
      } catch (e) {
        _logger.w('WsAckHandler.start failed: $e');
      }

      _wsMessageHandler = msgHandler;
      _wsAckHandler = ackHandler;

      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
    } catch (e, st) {
      _logger.e('ChatScreenWrapper wiring error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = 'Internal error while preparing chat';
          _loading = false;
        });
      }
    }
  }

  String _deriveConversationId(String a, String b) {
    return (a.compareTo(b) <= 0) ? '$a:$b' : '$b:$a';
  }

  @override
  void dispose() {
    try {
      _wsMessageHandler?.stop();
    } catch (_) {}
    try {
      _wsAckHandler?.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: SectionAppBar(title: widget.peerName, onBack: () => Navigator.of(context).pop()),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent(theme))),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: SectionAppBar(title: widget.peerName, onBack: () => Navigator.of(context).pop()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _wireUp,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent(theme)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ready -> show ChatScreen with resolved handlers & repos
    return ChatScreen(
      conversationId: _deriveConversationId(widget.currentUserId, widget.peerId),
      currentUserId: widget.currentUserId,
      chatService: _chatService!,
      messageRepository: _messageRepo!,
      wsMessageHandler: _wsMessageHandler!,
      wsAckHandler: _wsAckHandler!,
    );
  }
}
