import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:flutter/material.dart';

class LikedTab extends StatefulWidget {
  const LikedTab({super.key});

  @override
  State<LikedTab> createState() => _LikedTabState();
}

class _LikedTabState extends State<LikedTab>
    with AutomaticKeepAliveClientMixin<LikedTab>, TickerProviderStateMixin {
  final DataService dataService = DataService();
  String? userId;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    userId = dataService.currentUserId;
    _fadeController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (userId == null) return _buildNotLoggedInView(theme);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: const SectionAppBar(title: "Liked Ads"),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<ImageModel>>(
          stream: dataService.getLikedImages(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString(), theme);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child:
                CircularProgressIndicator(color: theme.colorScheme.primary),
              );
            }

            final ads = snapshot.data ?? [];
            return ads.isEmpty
                ? _buildEmptyLikedState(theme)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ads.length,
              itemBuilder: (context, index) =>
                  _buildLikedAdCard(context, ads[index], theme),
            );
          },
        ),
      ),
    );
  }

  // 🔹 Not logged in view
  Widget _buildNotLoggedInView(ThemeData theme) => Center(
    child: Padding(
      padding: AppTheme.largePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            "Please log in to view your liked ads",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.textSecondary(theme)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.login),
            label: const Text("Log In"),
          ),
        ],
      ),
    ),
  );

  // 🔹 Empty liked ads state
  Widget _buildEmptyLikedState(ThemeData theme) => Center(
    child: Padding(
      padding: AppTheme.largePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            "No liked ads yet",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.textSecondary(theme)),
          ),
          const SizedBox(height: 8),
          Text(
            "Start browsing to find something you love!",
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.textHint(theme)),
          ),
        ],
      ),
    ),
  );

  // 🔹 Error message
  Widget _buildError(String error, ThemeData theme) => Center(
    child: Text(
      "Error: $error",
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.error),
    ),
  );

  // 🔹 Liked Ad Card
  Widget _buildLikedAdCard(BuildContext context, ImageModel ad, ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ad.imageUrls.isNotEmpty
                  ? Image.network(
                ad.imageUrls.first,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 180,
                color: theme.colorScheme.surfaceVariant,
                child: Icon(Icons.image_not_supported,
                    size: 40, color: theme.colorScheme.onSurfaceVariant),
              ),
              Positioned(top: 12, left: 12, child: _buildStatusChip(ad, theme)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(ad.subcategory,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface)),
                ),
                Text(
                  "₹${ad.price ?? '0'}",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.favorite,
                label: "Unlike",
                color: theme.colorScheme.error,
                onTap: () => _removeLikedItem(ad),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 🔹 Status Chip
  Widget _buildStatusChip(ImageModel ad, ThemeData theme) {
    String text = "Active";
    Color color = theme.colorScheme.primary;

    if (ad.isDeleted) {
      text = "Deleted";
      color = theme.colorScheme.error;
    } else if (ad.isSoldOut) {
      text = "Sold Out";
      color = theme.colorScheme.tertiary;
    } else if (!ad.isActive) {
      text = "Paused";
      color = theme.colorScheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🔹 Reusable Action Button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }

  // 🔹 Remove Liked Item
  Future<void> _removeLikedItem(ImageModel ad) async {
    if (ad.docRef == null) return;
    try {
      await dataService.removeLike(ad.docRef!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Removed from Liked Ads"),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: $e"),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }
}
