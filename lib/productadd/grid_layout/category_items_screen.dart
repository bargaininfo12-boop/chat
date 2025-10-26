import 'package:bargain/homesceen/carousel_screen.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String category;

  const CategoryItemsScreen({super.key, required this.category});

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final DataService _dataService = DataService();
  bool _isGridView = true;

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _refreshData() async {
    await _dataService.refreshImages();
    HapticFeedback.lightImpact();
  }

  // ✅ Local fallback widget (same as ProductCard)
  Widget _buildLocalFallbackImage(ThemeData theme) {
    return Container(
      color: AppTheme.surfaceColor(theme),
      child: Center(
        child: Image.asset(
          'assets/no_image.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          color: theme.brightness == Brightness.dark
              ? Colors.white54
              : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildGridView(List<ImageModel> categoryImages, ThemeData theme) {
    return GridView.builder(
      padding: AppTheme.mediumPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: categoryImages.length,
      itemBuilder: (context, index) {
        return _buildGridItem(categoryImages[index], theme);
      },
    );
  }

  Widget _buildListView(List<ImageModel> categoryImages, ThemeData theme) {
    return ListView.builder(
      padding: AppTheme.mediumPadding,
      itemCount: categoryImages.length,
      itemBuilder: (context, index) {
        return _buildListItem(categoryImages[index], theme);
      },
    );
  }

  Widget _buildGridItem(ImageModel imageModel, ThemeData theme) {
    final imageUrl = imageModel.imageUrls.isNotEmpty ? imageModel.imageUrls[0] : '';

    return GestureDetector(
      onTap: () => _navigateToCarousel(imageModel),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(theme),
          borderRadius: AppTheme.mediumRadius,
          border: Border.all(
            color: AppTheme.borderColor(theme),
            width: 1,
          ),
          boxShadow: AppTheme.cardShadow(theme),
        ),
        child: ClipRRect(
          borderRadius: AppTheme.mediumRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  tag: imageUrl,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.cardColor(theme),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor(theme),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildLocalFallbackImage(theme), // ✅ local fallback
                  )
                      : _buildLocalFallbackImage(theme), // ✅ no image fallback
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(theme),
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.borderColor(theme),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        imageModel.subcategory.isNotEmpty
                            ? imageModel.subcategory
                            : widget.category,
                        style: TextStyle(
                          color: AppTheme.textPrimary(theme),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (imageModel.category.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          imageModel.category,
                          style: TextStyle(
                            color: AppTheme.textSecondary(theme),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(ImageModel imageModel, ThemeData theme) {
    final imageUrl = imageModel.imageUrls.isNotEmpty ? imageModel.imageUrls[0] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(theme),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(
          color: AppTheme.borderColor(theme),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow(theme),
      ),
      child: InkWell(
        onTap: () => _navigateToCarousel(imageModel),
        borderRadius: AppTheme.mediumRadius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.smallRadius,
                  border: Border.all(
                    color: AppTheme.borderColor(theme),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppTheme.smallRadius,
                  child: Hero(
                    tag: imageUrl,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.cardColor(theme),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor(theme),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildLocalFallbackImage(theme), // ✅ fallback
                    )
                        : _buildLocalFallbackImage(theme), // ✅ fallback
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      imageModel.subcategory.isNotEmpty
                          ? imageModel.subcategory
                          : widget.category,
                      style: TextStyle(
                        color: AppTheme.textPrimary(theme),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (imageModel.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        imageModel.category,
                        style: TextStyle(
                          color: AppTheme.textSecondary(theme),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 16, color: AppTheme.iconColor(theme)),
                        const SizedBox(width: 4),
                        Text(
                          '${imageModel.imageUrls.length} images',
                          style: TextStyle(
                            color: AppTheme.textSecondary(theme),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.iconColor(theme)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCarousel(ImageModel imageModel) {
    if (imageModel.imageUrls.isNotEmpty) {
      HapticFeedback.lightImpact();
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CarouselScreen(
                imageUrls: imageModel.imageUrls,
                videoUrls: imageModel.videoUrls,
                productDetails: imageModel,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: AppTheme.mediumDuration,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: AppBar(
        title: Text(
          widget.category,
          style: TextStyle(
            color: AppTheme.textPrimary(theme),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.appBarBackground(theme),
        elevation: 1,
        iconTheme: IconThemeData(color: AppTheme.iconColor(theme)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: AppTheme.iconColor(theme),
            ),
            onPressed: _toggleView,
          ),
        ],
      ),
      body: StreamBuilder<List<ImageModel>>(
        stream: _dataService.getImagesByCategory(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final categoryImages = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.primaryColor(theme),
              child: _isGridView
                  ? _buildGridView(categoryImages, theme)
                  : _buildListView(categoryImages, theme),
            );
          }

          return const Center(child: Text('No products available.'));
        },
      ),
    );
  }
}
