// File: lib/account_setting/help_support_page.dart
import 'package:bargain/account_setting/legal%20&%20support/contact_support_page.dart';
import 'package:bargain/account_setting/legal%20&%20support/faqs_page.dart';
import 'package:bargain/account_setting/legal%20&%20support/feedback_dialog.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Could not open the link"),
          backgroundColor: AppTheme.errorColor(Theme.of(context)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: "Help & Support",
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: AppTheme.mediumPadding,
        children: [
          _buildCard(
            context,
            icon: Icons.help_outline,
            title: "FAQs",
            subtitle: "Frequently asked questions",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQsPage()),
              );
            },
          ),

          const SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.support_agent,
            title: "Contact Support",
            subtitle: "Send us a message for help",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactSupportPage()),
              );
            },
          ),

          const SizedBox(height: 12),
          const SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.feedback_outlined,
            title: "Send Feedback",
            subtitle: "Tell us about your experience",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const FeedbackDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.mediumRadius,
      child: Container(
        padding: AppTheme.mediumPadding,
        decoration: BoxDecoration(
          color: AppTheme.cardColor(theme),
          borderRadius: AppTheme.mediumRadius,
          border: Border.all(color: AppTheme.borderColor(theme)),
          boxShadow: AppTheme.softShadow(theme),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppTheme.primaryColor(theme)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(theme),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary(theme),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
