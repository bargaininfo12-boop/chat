// File: lib/support/privacy_policy_page.dart

import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: "Privacy Policy",
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.largePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Privacy Policy",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary(theme),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "We value your privacy and are committed to protecting your personal data. "
                    "This Privacy Policy explains how we collect, use, and safeguard your information "
                    "when you use our application.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary(theme),
                ),
              ),
              const SizedBox(height: 24),

              _buildSection(
                theme,
                "1. Information We Collect",
                "We may collect personal details such as your name, email, phone number, and usage data "
                    "to provide better services.",
              ),

              _buildSection(
                theme,
                "2. How We Use Information",
                "Your information is used to improve user experience, personalize content, send notifications, "
                    "and enhance app security.",
              ),

              _buildSection(
                theme,
                "3. Sharing of Information",
                "We do not sell your personal data. Information may only be shared with trusted partners "
                    "to provide essential app features.",
              ),

              _buildSection(
                theme,
                "4. Data Security",
                "We use industry-standard security measures to protect your personal data from unauthorized access.",
              ),

              _buildSection(
                theme,
                "5. Your Rights",
                "You can update or delete your account information anytime by contacting our support team.",
              ),

              const SizedBox(height: 24),
              Text(
                "If you have any questions about this Privacy Policy, please contact us via the Help & Support section.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary(theme),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
