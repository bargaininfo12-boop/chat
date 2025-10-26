import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/productadd/add_product/data_holder.dart';
import 'package:bargain/productadd/forms/dynamic_details_wrapper.dart';
import 'package:bargain/productadd/forms/form_config_mapper.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:flutter/material.dart';

class MyAdsTab extends StatefulWidget {
  const MyAdsTab({super.key});

  @override
  State<MyAdsTab> createState() => _MyAdsTabState();
}

class _MyAdsTabState extends State<MyAdsTab>
    with AutomaticKeepAliveClientMixin<MyAdsTab>, TickerProviderStateMixin {
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
      appBar: SectionAppBar(
        title: "My Ads",
        onBack: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<ImageModel>>(
          stream: dataService.getUserProducts(userId!),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString(), theme);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            }

            final ads = snapshot.data ?? [];
            return ads.isEmpty
                ? _buildEmptyMyAdsState(theme)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ads.length,
              itemBuilder: (context, index) =>
                  _buildAdCard(context, ads[index], theme),
            );
          },
        ),
      ),
    );
  }

  // 🔹 User not logged in
  Widget _buildNotLoggedInView(ThemeData theme) => Center(
    child: Padding(
      padding: AppTheme.largePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            "Please log in to manage your ads",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary(theme),
            ),
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
          )
        ],
      ),
    ),
  );

  // 🔹 Empty ads state
  Widget _buildEmptyMyAdsState(ThemeData theme) => Center(
    child: Padding(
      padding: AppTheme.largePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            "You haven’t posted any ads yet",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary(theme),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pushNamed(context, '/addProduct'),
            icon: const Icon(Icons.add_circle),
            label: const Text("Post Your First Ad"),
          ),
        ],
      ),
    ),
  );

  Widget _buildError(String error, ThemeData theme) => Center(
    child: Text(
      "Error: $error",
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.error),
    ),
  );

  // 🔹 Ad Card
  Widget _buildAdCard(BuildContext context, ImageModel ad, ThemeData theme) {
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
                  child: Text(
                    ad.subcategory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!ad.isDeleted && !ad.isSoldOut)
                  _buildActionButton(
                    icon: ad.isActive ? Icons.pause_circle : Icons.play_circle,
                    label: ad.isActive ? "Pause" : "Resume",
                    color: ad.isActive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.secondary,
                    onTap: () => _togglePause(ad),
                  ),
                if (!ad.isDeleted && !ad.isSoldOut)
                  _buildActionButton(
                    icon: Icons.check_circle,
                    label: "Sold",
                    color: theme.colorScheme.primary,
                    onTap: () => _markAsSold(ad),
                  ),
                if (!ad.isDeleted)
                  _buildActionButton(
                    icon: Icons.edit,
                    label: "Edit",
                    color: theme.colorScheme.secondary,
                    onTap: () => _handleEdit(ad),
                  ),
                if (!ad.isDeleted)
                  _buildActionButton(
                    icon: Icons.delete,
                    label: "Delete",
                    color: theme.colorScheme.error,
                    onTap: () => _confirmDelete(ad),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

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

  // ==== Actions ====

  Future<void> _togglePause(ImageModel ad) async {
    if (ad.docRef == null || ad.isDeleted || ad.isSoldOut) return;
    try {
      await ad.docRef!.update({"Product.isActive": !ad.isActive});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ad.isActive ? "Ad paused" : "Ad resumed"),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } catch (e) {
      _showErrorSnack("Failed: $e");
    }
  }

  Future<void> _markAsSold(ImageModel ad) async {
    if (ad.docRef == null) return;
    final confirm = await _showConfirmDialog(
      title: "Mark as Sold",
      message: "Are you sure you want to mark this ad as SOLD?",
      confirmText: "Mark Sold",
    );

    if (confirm) {
      await ad.docRef!.update({
        "Product.isActive": false,
        "Product.isSoldOut": true,
      });
      _showSuccessSnack("Ad marked as Sold");
    }
  }

  Future<void> _confirmDelete(ImageModel ad) async {
    if (ad.docRef == null) return;
    final confirm = await _showConfirmDialog(
      title: "Delete Ad",
      message: "Are you sure you want to delete this ad? It cannot be resumed.",
      confirmText: "Delete",
    );

    if (confirm) {
      await ad.docRef!.update({
        "Product.isActive": false,
        "Product.isDeleted": true,
      });
      _showSuccessSnack("Ad deleted");
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(title, style: theme.textTheme.titleMedium),
        content: Text(message, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(confirmText),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
  );

  void _showSuccessSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.green.shade400),
  );

  // ==== Edit Action ====
  void _handleEdit(ImageModel ad) {
    DataHolder.uid = ad.userId;
    DataHolder.productId = ad.productId;
    DataHolder.imageUrls = ad.imageUrls;
    DataHolder.videoUrls = ad.videoUrls;
    DataHolder.category = ad.category;
    DataHolder.subcategory = ad.subcategory;
    DataHolder.priceData = ad.price;
    DataHolder.city = ad.city;
    DataHolder.state = ad.state;
    DataHolder.details = Map<String, dynamic>.from(ad.productDetails ?? {});
    DataHolder.isActive = ad.isActive;
    DataHolder.isSoldOut = ad.isSoldOut;

    final formConfig = FormConfigMapper.getFormConfig(ad.category);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicDetailsWrapper(
          categoryName: ad.subcategory,
          formConfig: formConfig,
        ),
      ),
    );
  }
}
