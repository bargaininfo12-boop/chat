// lib/MyAdsPage/my_ads_common.dart
// v1.7.0 — Fixed _navigateToDetail + context safety + AppTheme linked

import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/homesceen/carousel_screen.dart';
import 'package:bargain/productadd/add_product/data_holder.dart';
import 'package:bargain/productadd/forms/dynamic_details_wrapper.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_like_card.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:shimmer/shimmer.dart';

Widget buildAdCard({
  required BuildContext context,
  required ImageModel image,
  required bool isMyAds,
  required DataService dataService,
  Widget? controls,
  Widget? imageOverlay,
  VoidCallback? onUnlike,
}) {
  final currentUid = dataService.currentUserId;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: AppTheme.largeRadius,
      onTap: () {
        HapticFeedback.lightImpact();
        if (image.isSoldOut || !image.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This ad has been sold or deactivated.'),
              backgroundColor: AppTheme.warningColor(Theme.of(context)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _navigateToDetail(context, image);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(Theme.of(context)),
          borderRadius: AppTheme.largeRadius,
          boxShadow: AppTheme.cardShadow(Theme.of(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: _buildImageSection(
                context,
                image,
                isMyAds,
                dataService,
                currentUid,
                imageOverlay,
                onUnlike,
              ),
            ),
            Flexible(
              flex: 3,
              child: _buildInfoSection(context, image, isMyAds, controls),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildImageSection(
    BuildContext context,
    ImageModel image,
    bool isMyAds,
    DataService dataService,
    String? currentUid,
    Widget? imageOverlay,
    VoidCallback? onUnlike,
    ) {
  return Stack(
    children: [
      image.imageUrls.isNotEmpty
          ? Hero(
        tag: 'product_${image.id}',
        child: FadeInImage.memoryNetwork(
          placeholder: kTransparentImage,
          image: image.imageUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      )
          : _buildPlaceholderImage(context),

      if (!isMyAds && currentUid != null && image.docRef != null)
        Positioned(
          top: 12,
          right: 12,
          child: ImageLikeCard(
            isLiked: image.likedBy.contains(currentUid),
            likeCount: image.likeCount,
            showCount: true,
            onTap: () async {
              if (currentUid == image.userId) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("You cannot like your own ad."),
                    backgroundColor: AppTheme.warningColor(Theme.of(context)),
                  ),
                );
                return;
              }

              try {
                await dataService.toggleLike(image.docRef!, ownerId: image.userId);
                if (!context.mounted) return;
                if (onUnlike != null && !image.likedBy.contains(currentUid)) {
                  onUnlike();
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to update like: $e"),
                    backgroundColor: AppTheme.errorColor(Theme.of(context)),
                  ),
                );
              }
            },
          ),
        ),

      if (image.imageUrls.length > 1)
        Positioned(top: 12, left: 12, child: _buildImageCountBadge(image)),

      if (imageOverlay != null)
        Positioned(bottom: 12, right: 12, child: imageOverlay),

      if (image.isSoldOut || !image.isActive)
        buildStatusOverlay(context, image),
    ],
  );
}

Widget _buildInfoSection(
    BuildContext context,
    ImageModel image,
    bool isMyAds,
    Widget? controls,
    ) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                image.subcategory,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(theme),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "₹${_formatPrice(image.price ?? '0')}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor(theme),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (isMyAds)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _handleEdit(context, image),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Edit"),
            ),
          ),
        if (controls != null) controls,
      ],
    ),
  );
}

void _handleEdit(BuildContext context, ImageModel image) {
  DataHolder.uid = image.userId;
  DataHolder.productId = image.productId;
  DataHolder.imageUrls = image.imageUrls;
  DataHolder.videoUrls = image.videoUrls;
  DataHolder.category = image.category;
  DataHolder.subcategory = image.subcategory;
  DataHolder.priceData = image.price;
  DataHolder.city = image.city;
  DataHolder.state = image.state;
  DataHolder.details = image.productDetails ?? {};
  DataHolder.isActive = image.isActive;
  DataHolder.isSoldOut = image.isSoldOut;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DynamicDetailsWrapper(
        categoryName: image.subcategory,
        formConfig: const [],
      ),
    ),
  );
}

Widget _buildImageCountBadge(ImageModel image) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.photo_library, color: Colors.white, size: 14),
      const SizedBox(width: 4),
      Text(
        '${image.imageUrls.length}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ],
  ),
);

String _formatPrice(String price) {
  final numPrice = double.tryParse(price) ?? 0;
  if (numPrice >= 10000000) return '${(numPrice / 10000000).toStringAsFixed(1)}Cr';
  if (numPrice >= 100000) return '${(numPrice / 100000).toStringAsFixed(1)}L';
  if (numPrice >= 1000) return '${(numPrice / 1000).toStringAsFixed(1)}K';
  return numPrice.toInt().toString();
}

Widget _buildPlaceholderImage(BuildContext context) => Container(
  color: AppTheme.surfaceColor(Theme.of(context)),
  child: const Center(
    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
  ),
);

Widget buildStatusOverlay(BuildContext context, ImageModel image) {
  final theme = Theme.of(context);
  final statusText = image.isSoldOut ? 'SOLD OUT' : 'INACTIVE';
  final color =
  image.isSoldOut ? AppTheme.errorColor(theme) : AppTheme.warningColor(theme);

  return Container(
    color: Colors.black.withValues(alpha: 0.4),
    alignment: Alignment.center,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/// ✅ FIXED FUNCTION — navigate to product detail
void _navigateToDetail(BuildContext context, ImageModel image) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => CarouselScreen(
        imageUrls: image.imageUrls,
        videoUrls: image.videoUrls,
        productDetails: image,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
