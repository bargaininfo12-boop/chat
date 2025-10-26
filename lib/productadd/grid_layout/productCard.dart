import 'dart:ui';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/homesceen/carousel_screen.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_like_card.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends StatefulWidget {
  final ImageModel imageModel;
  final double width;
  final double height;

  const ProductCard({
    super.key,
    required this.imageModel,
    this.width = 170,
    this.height = 250,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _hoverAnim = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarouselScreen(
          imageUrls: widget.imageModel.imageUrls,
          videoUrls: widget.imageModel.videoUrls,
          productDetails: widget.imageModel,
        ),
      ),
    );
  }

  String _formatPrice(String? price) {
    final value = double.tryParse(price ?? '') ?? 0;
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return format.format(value);
  }

  Widget _shimmer(ThemeData theme) => Shimmer.fromColors(
    baseColor: AppTheme.shimmerBaseColor(theme),
    highlightColor: AppTheme.shimmerHighlightColor(theme),
    child: Container(color: AppTheme.surfaceColor(theme)),
  );

  Widget _fallback(ThemeData theme) => Container(
    color: AppTheme.surfaceColor(theme),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        color: AppTheme.iconColor(theme).withOpacity(0.28),
        size: 40,
      ),
    ),
  );

  Widget _sellerAvatar(String? url, ThemeData theme) {
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: AppTheme.surfaceColor(theme),
        child: Icon(
          Icons.person,
          size: 14,
          color: AppTheme.textSecondary(theme),
        ),
      );
    }
    return CircleAvatar(
      radius: 12,
      backgroundImage: NetworkImage(url),
    );
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = widget.imageModel;
    final imageUrl = model.imageUrls.isNotEmpty ? model.imageUrls.first : '';
    final currentUid = DataService.instance.currentUserId;
    final isLiked = model.likedBy.contains(currentUid);

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.035).animate(_hoverAnim),
        child: GestureDetector(
          onTap: _onTap,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.surfaceColor(theme),
              border: Border.all(
                color: AppTheme.borderColor(theme),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor(theme).withOpacity(0.06),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.02),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // ========== IMAGE SECTION (60%) ==========
                  Expanded(
                    flex: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Product Image
                        if (imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _shimmer(theme),
                            errorWidget: (_, __, ___) => _fallback(theme),
                            fadeInDuration: const Duration(milliseconds: 340),
                          )
                        else
                          _fallback(theme),

                        // Gradient Overlay
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                              stops: [0.45, 1.0],
                            ),
                          ),
                        ),

                        // Top-Left: Rating Badge
                        if (model.productDetails?['rating'] != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.amber[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (model.productDetails!['rating'])
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Top-Right: Like Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ImageLikeCard(
                            isLiked: isLiked,
                            likeCount: model.likeCount,
                            showCount: false,
                            onTap: () async {
                              HapticFeedback.mediumImpact();
                              if (model.docRef != null) {
                                await DataService.instance.toggleLike(
                                  model.docRef!,
                                  ownerId: model.userId,
                                );
                                setState(() {});
                              }
                            },
                          ),
                        ),


                      ],
                    ),
                  ),

                  // ========== INFO SECTION (40%) ==========
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      color: AppTheme.cardColor(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Title + Price Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  model.subcategory.isNotEmpty
                                      ? model.subcategory
                                      : 'Unnamed',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary(theme),
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatPrice(model.price),
                                style: TextStyle(
                                  color: AppTheme.primaryColor(theme),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Location Row
                          if ((model.city ?? '').isNotEmpty ||
                              (model.state ?? '').isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: AppTheme.textSecondary(theme),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    model.location,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary(theme),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                          const Spacer(),

                          // Bottom Row: Time + Condition
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _relativeTime(model.time),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary(theme),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if ((model.productDetails?['condition'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor(theme),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.borderColor(theme),
                                    ),
                                  ),
                                  child: Text(
                                    model.productDetails!['condition']
                                        .toString(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary(theme),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
