import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/productadd/grid_layout/ProductCard.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:bargain/productadd/grid_layout/subcategory_card.dart';
import 'package:bargain/productadd/search_page_Activity/searchpage/searchpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ImageGrid extends StatefulWidget {
  final User user;
  const ImageGrid({super.key, required this.user});

  @override
  State<ImageGrid> createState() => _ImageGridState();
}

class _ImageGridState extends State<ImageGrid> {
  final DataService _dataService = DataService.instance;
  String? _selectedSubcategory;
  bool _isRefreshing = false;

  // 🔄 Pull-to-refresh
  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _dataService.refreshImages();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isRefreshing = false);
  }

  // 🧭 Subcategory scroll bar
  Widget _buildSubcategories(List<String> subcategories) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          final isSelected = subcategory == _selectedSubcategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSubcategory = isSelected ? null : subcategory;
              });
            },
            child: SubcategoryCard(
              subcategory: subcategory,
              width: 130,
              height: 130,
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }

  // 🏷️ Category sections
  Widget _buildMainContent(List<ImageModel> images, List<String> categories) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        final filteredImages = images.where((image) {
          if (image.category != category) return false;
          if (_selectedSubcategory != null &&
              image.subcategory != _selectedSubcategory) return false;
          return true;
        }).take(10).toList();

        if (filteredImages.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(theme),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchBarPage(query: category),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: AppTheme.primaryColor(theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal list
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, imageIndex) {
                  final imageModel = filteredImages[imageIndex];
                  return SizedBox(
                    width: 180,
                    child: ProductCard(imageModel: imageModel),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ✨ Shimmer layout
  Widget _buildShimmerLayout() {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.shimmerBaseColor(theme),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, _) {
                  return Container(
                    width: 170,
                    height: 220,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.shimmerHighlightColor(theme),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppTheme.iconColor(theme)),
          const SizedBox(height: 16),
          Text(
            "No products available",
            style: TextStyle(
              color: AppTheme.textSecondary(theme),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor(theme)),
            const SizedBox(height: 16),
            Text('Error loading products',
                style: TextStyle(color: AppTheme.textPrimary(theme))),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(theme)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(theme),
                foregroundColor: AppTheme.textOnPrimary(theme),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryColor(theme),
      backgroundColor: AppTheme.surfaceColor(theme),
      child: StreamBuilder<List<ImageModel>>(
        stream: _dataService.getImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _dataService.refreshImages();
            });
            return _buildShimmerLayout();
          }

          if (snapshot.hasError) {
            return _buildErrorState(theme, snapshot.error.toString());
          }

          if (snapshot.hasData) {
            final images = snapshot.data!;
            if (images.isEmpty) return _buildEmptyState(theme);

            final categories = images
                .map((img) => img.category)
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();

            final subcategories = images
                .map((img) => img.subcategory)
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();

            // ✅ Scrollable layout for RefreshIndicator
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (subcategories.isNotEmpty)
                  _buildSubcategories(subcategories),
                _buildMainContent(images, categories),
                const SizedBox(height: 80),
              ],
            );
          }

          return _buildEmptyState(theme);
        },
      ),
    );
  }
}
