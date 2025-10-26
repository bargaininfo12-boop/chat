// File: lib/account_setting/faqs_page.dart
import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';

class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, String>> faqs = [
      {
        "question": "How do I post a new ad?",
        "answer":
        "Go to the Home screen and tap the '+' button. Fill in the product details, upload images, and submit your ad."
      },
      {
        "question": "How can I edit or delete my ad?",
        "answer":
        "Go to the 'My Ads' section in your account. There you can edit, deactivate, or delete any of your posted ads."
      },
      {
        "question": "How do I contact a seller?",
        "answer":
        "Open the ad you are interested in and tap on the chat icon. You can directly message the seller from there."
      },
      {
        "question": "Is my data safe on this app?",
        "answer":
        "Yes, your data is stored securely and we never share it with third parties without your consent."
      },
      {
        "question": "Can I report inappropriate ads or users?",
        "answer":
        "Yes. Open the ad or profile and use the 'Report' option to notify us. Our team will review and take action."
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: "FAQs",
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView.separated(
        padding: AppTheme.mediumPadding,
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return _buildFaqCard(context, faq["question"]!, faq["answer"]!);
        },
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: AppTheme.mediumPadding,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        collapsedBackgroundColor: AppTheme.cardColor(theme),
        backgroundColor: AppTheme.cardColor(theme),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.mediumRadius,
          side: BorderSide(color: AppTheme.borderColor(theme)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: AppTheme.mediumRadius,
          side: BorderSide(color: AppTheme.borderColor(theme)),
        ),
        title: Text(
          question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(theme),
          ),
        ),
        iconColor: AppTheme.primaryColor(theme),
        collapsedIconColor: AppTheme.primaryColor(theme),
        children: [
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary(theme),
            ),
          ),
        ],
      ),
    );
  }
}
