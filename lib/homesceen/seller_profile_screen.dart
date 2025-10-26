import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:bargain/homesceen/carousel_screen.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

class SellerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String userId;

  const SellerProfileScreen({
    super.key,
    required this.userData,
    required this.userId,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  late final AnimationController _headerController;
  late final AnimationController _contentController;
  late final Animation<double> _headerAnim;
  late final Animation<double> _contentAnim;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _headerController =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _contentController =
        AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _headerAnim = CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic);
    _contentAnim = CurvedAnimation(parent: _contentController, curve: Curves.easeInOut);

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(title: "Profile", actions: const []),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildProfileHeader(theme),
          _buildStatsSection(theme),
          _buildProductsSection(theme),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildProfileHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerAnim,
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _headerAnim.value)),
            child: Opacity(
              opacity: _headerAnim.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryAccent(theme).withOpacity(0.1),
                      AppTheme.secondaryAccent(theme).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: AppTheme.largeRadius,
                  border: AppTheme.glassBorder(theme),
                  boxShadow: AppTheme.cardShadow(theme),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor(theme).withOpacity(0.8),
                    borderRadius: AppTheme.largeRadius,
                  ),
                  padding: AppTheme.largePadding,
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile_${widget.userId}',
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.surfaceColor(theme),
                          backgroundImage: _getUserImage(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getUserName(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent(theme).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_rounded,
                                size: 16, color: AppTheme.primaryAccent(theme)),
                            const SizedBox(width: 6),
                            Text("Professional Seller",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryAccent(theme),
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- STATS SECTION ----------------
  Widget _buildStatsSection(ThemeData theme) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _contentAnim,
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _contentAnim.value)),
            child: Opacity(
              opacity: _contentAnim.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<ImageModel>>(
                  stream: _dataService.getUserProducts(widget.userId),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Row(
                      children: [
                        Expanded(child: _buildStatCard(theme, "Products", "$count", Icons.inventory_2_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(theme, "Rating", "4.8", Icons.star_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(theme, "Reviews", "127", Icons.rate_review_rounded)),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(theme),
        borderRadius: AppTheme.mediumRadius,
        border: AppTheme.glassBorder(theme),
        boxShadow: AppTheme.softShadow(theme),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryAccent(theme), size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(theme),
              )),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary(theme),
              )),
        ],
      ),
    );
  }

  // ---------------- PRODUCTS SECTION ----------------
  Widget _buildProductsSection(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Products",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(theme),
                )),
            const SizedBox(height: 16),
            _EnhancedProductGrid(userId: widget.userId),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  ImageProvider _getUserImage() {
    final url = widget.userData?['photoURL'] ?? '';
    if (url is String && url.isNotEmpty) {
      return CachedNetworkImageProvider(
        url,
        cacheManager: CustomCacheManager.fileCache, // ✅ centralized cache
      );
    }
    return const AssetImage('assets/user.png');
  }

  String _getUserName() {
    final name = widget.userData?['name'] ?? '';
    if (name is String && name.isNotEmpty) {
      return name[0].toUpperCase() + name.substring(1).toLowerCase();
    }
    return "Unknown User";
  }
}

// ---------------- ENHANCED PRODUCT GRID ----------------
class _EnhancedProductGrid extends StatelessWidget {
  final String userId;
  final DataService _dataService = DataService();

  _EnhancedProductGrid({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<ImageModel>>(
      stream: _dataService.getUserProducts(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingGrid(theme);
        }

        final images = snapshot.data ?? [];
        if (images.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text("No products yet",
                  style: TextStyle(color: AppTheme.textSecondary(theme))),
            ),
          );
        }

        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: images.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildProductCard(context, theme, images[index], index);
          },
        );
      },
    );
  }

  Widget _buildProductCard(
      BuildContext context, ThemeData theme, ImageModel image, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarouselScreen(
              imageUrls: image.imageUrls,
              videoUrls: image.videoUrls,
              productDetails: image,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(theme),
          borderRadius: AppTheme.mediumRadius,
          border: AppTheme.glassBorder(theme),
          boxShadow: AppTheme.cardShadow(theme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: image.imageUrls.isNotEmpty ? image.imageUrls[0] : '',
                cacheManager: CustomCacheManager.fileCache,
                fit: BoxFit.cover,
                height: index % 2 == 0 ? 160 : 200,
                width: double.infinity,
                placeholder: (_, __) => _buildImageShimmer(theme),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceColor(theme),
                  child: Icon(Icons.broken_image_rounded,
                      color: AppTheme.textSecondary(theme), size: 40),
                ),
              ),
            ),
            Padding(
              padding: AppTheme.mediumPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(image.subcategory,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(theme),
                      )),
                  const SizedBox(height: 8),
                  Text('₹${image.price ?? 'N/A'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAccent(theme),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmerBaseColor(theme),
      highlightColor: AppTheme.shimmerHighlightColor(theme),
      child: Container(color: AppTheme.surfaceColor(theme)),
    );
  }

  Widget _buildLoadingGrid(ThemeData theme) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.shimmerBaseColor(theme),
        highlightColor: AppTheme.shimmerHighlightColor(theme),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(theme),
            borderRadius: AppTheme.mediumRadius,
          ),
          height: index % 2 == 0 ? 160 : 200,
        ),
      ),
    );
  }
}
