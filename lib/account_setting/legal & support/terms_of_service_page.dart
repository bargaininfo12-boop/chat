import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: "Terms of Service",
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.largePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Terms of Service",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(theme),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Welcome to Bargain! Please read these Terms of Service carefully before using our app.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary(theme),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              theme,
              "1. Acceptance of Terms",
              "By using Bargain, you agree to these terms and conditions. "
                  "If you do not agree, please do not use the app.",
            ),
            const SizedBox(height: 16),

            _buildSection(
              theme,
              "2. User Responsibilities",
              "You are responsible for providing accurate information, "
                  "keeping your account secure, and using the app in compliance with applicable laws.",
            ),
            const SizedBox(height: 16),

            _buildSection(
              theme,
              "3. Content & Listings",
              "You are solely responsible for the content you post. "
                  "Bargain is not responsible for user-generated listings.",
            ),
            const SizedBox(height: 16),

            _buildSection(
              theme,
              "4. Limitation of Liability",
              "Bargain is not liable for any losses or damages arising from the use of the app.",
            ),
            const SizedBox(height: 16),

            _buildSection(
              theme,
              "5. Changes to Terms",
              "We may update these terms from time to time. Continued use of the app means you accept the updated terms.",
            ),
            const SizedBox(height: 24),

            Text(
              "If you have questions about these Terms, please contact support.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(theme),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary(theme),
          ),
        ),
      ],
    );
  }
}
