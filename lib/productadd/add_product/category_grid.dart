// lib/widgets/category_grid.dart

import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';

class CategoryGrid extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> categories;
  final void Function(String category, String subcategory) onTap;

  const CategoryGrid({
    super.key,
    required this.title,
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final systemTheme = Theme.of(context);

    return Theme(
      data: systemTheme.brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.appBarTheme.foregroundColor ??
                      theme.colorScheme.onPrimary,
                ),
              ),
              backgroundColor:
              theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
            ),
            body: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final String name = category['name'];
                final Color accentColor =
                    category['color'] ?? theme.colorScheme.primary;
                final String? imagePath = category['image'];
                final IconData? icon = category['icon'];

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: accentColor.withValues(alpha: 0.3),
                  highlightColor: accentColor.withValues(alpha: 0.1),
                  onTap: () => onTap(title, name),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ✅ Priority: show image if available, else icon
                          if (imagePath != null)
                            Image.asset(
                              imagePath,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: theme.colorScheme.onPrimaryContainer,
                                );
                              },
                            )
                          else if (icon != null)
                            Icon(
                              icon,
                              size: 40,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),

                          const SizedBox(height: 10),

                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
