// File: books_content.dart
// Version: 2.2.1
// Updated: Replaced unsupported icons for backward compatibility.

import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/productadd/add_product/data_holder.dart';
import 'package:bargain/productadd/forms/dynamic_details_wrapper.dart';
import 'package:bargain/productadd/Config_files/books_form_config.dart';
import 'package:flutter/material.dart';

class BooksContent extends StatelessWidget {
  const BooksContent({super.key});

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
          final String selectedCategory =
              ModalRoute.of(context)?.settings.arguments as String? ?? 'Books';

          final List<Map<String, dynamic>> subCategories = [
            {'name': 'Novels', 'icon': Icons.menu_book},
            {'name': 'Science Books', 'icon': Icons.science},
            {'name': 'Fiction Books', 'icon': Icons.auto_stories},
            {'name': 'Non-Fiction Books', 'icon': Icons.history_edu},
            {'name': 'Literature Books', 'icon': Icons.library_books},
            {'name': 'Storybooks', 'icon': Icons.child_care},
            {'name': 'School Books', 'icon': Icons.school},
            {'name': 'College Books', 'icon': Icons.local_library},
            {'name': 'Comics', 'icon': Icons.collections_bookmark}, // ✅ fallback
            {'name': 'Magazines', 'icon': Icons.bookmark_border},    // ✅ fallback
            {'name': 'Other', 'icon': Icons.book_outlined},
          ];

          return Scaffold(
            appBar: SectionAppBar(
              title: selectedCategory,
              onBack: () => Navigator.pop(context),
            ),
            body: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              padding: const EdgeInsets.all(16.0),
              children: subCategories.map((subcategory) {
                return _buildCard(
                  context,
                  subcategory['name'] as String,
                  selectedCategory,
                  subcategory['icon'] as IconData,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, String subcategory, String? category, IconData icon) {
    final theme = Theme.of(context);
    final Color cardColor = theme.colorScheme.primaryContainer;
    final Color textColor = theme.colorScheme.onPrimaryContainer;

    return InkWell(
      onTap: () async {
        await DataHolder.startNewProduct(); // ✅ productId generated

        DataHolder.category = category ?? '';
        DataHolder.subcategory = subcategory;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicDetailsWrapper(
              categoryName: subcategory,
              formConfig: getBooksFormConfig(subcategory),
            ),
          ),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        clipBehavior: Clip.antiAlias,
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: textColor),
              const SizedBox(height: 10),
              Text(
                subcategory,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
