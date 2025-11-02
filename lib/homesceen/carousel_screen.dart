import 'package:bargain/Services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/chat/UX Layer/chat_screen.dart';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:bargain/productadd/grid_layout/media_carousel.dart';
import 'package:bargain/productadd/grid_layout/image_like_card.dart';
import 'package:bargain/homesceen/seller_profile_screen.dart';

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
    _fetchSellerDetails();
    _scheduleGuide();

    final currentUser = UserService().currentUser;
    _isLiked = widget.productDetails.likedBy.contains(currentUser?.uid);
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

  Future<void> _fetchSellerDetails() async {
    final sellerId = widget.productDetails.userId;
    final cacheKey = 'seller_$sellerId';

    try {
      final cached = await CustomCacheManager.loadJsonCache(cacheKey, expiry: const Duration(hours: 24));
      if (cached != null && cached.isNotEmpty) {
        _userData = Map<String, dynamic>.from(cached.first);
        if (mounted) setState(() {});
      }

      final sellerProfile = await UserService().getUserById(sellerId);
      if (sellerProfile != null) {
        _userData = sellerProfile.toJson();
        if (mounted) setState(() {});
        await CustomCacheManager.saveJsonCache(cacheKey, _userData!);
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

  void _navigateToChat() {
    final userId = UserService().currentUser?.uid;
    if (userId == null) {
      _showSnackBar("User not identified", isError: true);
      return;
    }

    final peerId = widget.productDetails.userId;
    final conversationId = _deriveConversationId(userId, peerId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          receiverId: peerId,
          receiverName: _userData?['name'] ?? 'Seller',
        ),
      ),
    );
  }


  String _deriveConversationId(String a, String b) {
    return (a.compareTo(b) <= 0) ? '$a:$b' : '$b:$a';
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
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final userId = UserService().currentUser?.uid;
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
        title: Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text("Seller", style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
          Text(p.category,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary(theme),
              )),
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
                  child: Text("${e.value}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary(theme),
                      )),
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
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow(theme),
                borderRadius: AppTheme.smallRadius,
              ),
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

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}
