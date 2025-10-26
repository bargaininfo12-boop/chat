import 'dart:math';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bargain/app_theme/app_theme.dart';

class InviteFriendsPage extends StatefulWidget {
  const InviteFriendsPage({super.key});

  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage> {
  late final String _referralCode;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _referralCode = _generate6DigitCode();
  }

  /// Generate unique 6-digit code
  String _generate6DigitCode() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  Future<void> _shareInvite() async {
    HapticFeedback.lightImpact();
    setState(() => _isSharing = true);

    final shareText = 'Join me on Bargain! Use my invite code: $_referralCode';

    try {
      await Share.share(shareText, subject: 'Join me on Bargain!');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: 'Invite Friends',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.mediumPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 Top Tagline Card
              Container(
                padding: AppTheme.mediumPadding,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(theme),
                  borderRadius: AppTheme.largeRadius,
                  border: Border.all(color: AppTheme.borderColor(theme)),
                  boxShadow: AppTheme.softShadow(theme),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(theme).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 28,
                        color: AppTheme.primaryColor(theme),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite friends & earn rewards',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(theme),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Share your code or QR. Friends sign up with your code and you both may get perks.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary(theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 QR + Code + Share
              Expanded(
                child: Container(
                  padding: AppTheme.largePadding,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(theme),
                    borderRadius: AppTheme.largeRadius,
                    border: Border.all(color: AppTheme.borderColor(theme)),
                    boxShadow: AppTheme.softShadow(theme),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      QrImageView(
                        data: _referralCode,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _referralCode,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor(theme),
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Share Invite Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareInvite,
                  icon: _isSharing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.share),
                  label: Text(
                    _isSharing ? 'Sharing...' : 'Share Invite',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(theme),
                    foregroundColor: AppTheme.textOnPrimary(theme),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.mediumRadius,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Your friends can scan the QR or enter your 6-digit code to join.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary(theme),
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
