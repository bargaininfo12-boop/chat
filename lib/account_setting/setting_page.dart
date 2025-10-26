import 'package:bargain/account_setting/langauge/language_dialog.dart';
import 'package:bargain/account_setting/legal%20&%20support/help_support_page.dart';
import 'package:bargain/account_setting/legal%20&%20support/invite_friends_page.dart';
import 'package:bargain/account_setting/legal%20&%20support/privacy_policy_page.dart';
import 'package:bargain/account_setting/legal%20&%20support/terms_of_service_page.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/A_User_Data/profile_picture_widget.dart';
import 'package:bargain/Location/location_screen.dart';
import 'package:bargain/MyAdsPage/liked_tab.dart';
import 'package:bargain/MyAdsPage/my_ads_tab.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/services/session_manager.dart';
import 'package:bargain/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bargain/main.dart';

class SettingPage extends StatefulWidget {
  final User user;
  final VoidCallback onBack;

  const SettingPage({super.key, required this.user, required this.onBack});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _userService = UserService();
  String _userName = '';
  String _userEmail = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: AppTheme.longDuration);
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isRefreshing = true);

      String name = widget.user.displayName ?? "User";
      String email = widget.user.email ?? "No email";

      final cached = _userService.currentUser;
      if (cached != null) {
        name = cached.name ?? name;
        email = cached.email ?? email;
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _userEmail = email;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading user data: $e");
      if (mounted) setState(() => _isRefreshing = false);
    }
  }


  Future<void> _refreshFromServerIfNeeded({bool force = false}) async {
    final me = widget.user;
    if (me == null) return;

    final cached = _userService.currentUser;
    if (!force && cached != null && cached.lastUpdated != null) {
      final age = DateTime.now().difference(cached.lastUpdated!);
      if (age < const Duration(minutes: 5)) {
        debugPrint('Skipping refresh; cache age ${age.inSeconds}s');
        return;
      }
    }

    // perform refresh (this will do one Firestore read)
    try {
      final ok = await _userService.refreshUserData();
      if (ok && mounted) {
        final refreshed = _userService.currentUser;
        if (refreshed != null) {
          setState(() {
            _userName = refreshed.name ?? widget.user.displayName ?? "User";
            _userEmail = refreshed.email ?? widget.user.email ?? "No email";
          });
        }
      } else if (_userService.currentUser == null) {
        // only create/initialize if doc missing and forced by logic inside initializeUser
        await _userService.initializeUser(widget.user);
        final re = _userService.currentUser;
        if (re != null && mounted) {
          setState(() {
            _userName = re.name ?? widget.user.displayName ?? "User";
            _userEmail = re.email ?? widget.user.email ?? "No email";
          });
        }
      }
    } catch (e) {
      debugPrint('refreshFromServerIfNeeded: $e');
    }
  }


  String _getMemberSinceText() {
    final creation = widget.user.metadata.creationTime;
    if (creation == null) return "Member since signup";
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Member since ${months[creation.month - 1]} ${creation.year}';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: "Settings",
        onBack: widget.onBack,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadUserData,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: AppTheme.mediumPadding,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 24),
                  _buildSection('Account Settings', [
                    _buildSettingCard(
                      icon: Icons.sell_outlined,
                      title: 'My Ads',
                      subtitle: 'Manage your listings',
                      onTap: () => _navigateToPage(const MyAdsTab()),
                    ),
                    _buildSettingCard(
                      icon: Icons.favorite_border,
                      title: 'Liked Items',
                      subtitle: 'Your saved favorites',
                      onTap: () => _navigateToPage(const LikedTab()),
                    ),
                    _buildSettingCard(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      subtitle: 'Update delivery location',
                      onTap: () => _navigateToPage(const LocationScreen()),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Preferences', [
                    _buildSettingCard(
                      icon: Icons.color_lens_outlined,
                      title: 'Appearance',
                      subtitle: 'Theme and display settings',
                      onTap: _showThemeDialog,
                    ),
                    _buildSettingCard(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Change app language',
                      onTap: () => showLanguageDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Support & Legal', [
                    _buildSettingCard(
                      icon: Icons.group_add_outlined,
                      title: 'Invite Friends',
                      subtitle: 'Share the app with friends',
                      onTap: () => _navigateToPage(const InviteFriendsPage()),
                    ),
                    _buildSettingCard(
                      icon: Icons.support_agent,
                      title: 'Help & Support',
                      subtitle: 'Contact support or report issues',
                      onTap: () => _navigateToPage(const HelpSupportPage()),
                    ),
                    _buildSettingCard(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      onTap: () =>
                          _navigateToPage(const PrivacyPolicyPage()),
                    ),
                    _buildSettingCard(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms and conditions',
                      onTap: () =>
                          _navigateToPage(const TermsOfServicePage()),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Account Actions', [
                    _buildSettingCard(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      onTap: () => SessionManager.logout(context),
                      isDestructive: true,
                    ),
                    _buildSettingCard(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your data',
                      onTap: () => SessionManager.deleteAccount(context),
                      isDestructive: true,
                      isDanger: true,
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildAppInfo(),
                ],
              ),
            ),
            if (_isRefreshing)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(theme),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text("Refreshing...",
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final theme = Theme.of(context);
    final radius = MediaQuery.of(context).size.width * 0.14;

    return Container(
      padding: AppTheme.mediumPadding,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(theme),
        borderRadius: AppTheme.largeRadius,
        border: Border.all(color: AppTheme.borderColor(theme), width: 1),
        boxShadow: AppTheme.softShadow(theme),
      ),
      child: Column(
        children: [
          ProfilePictureWidget(
            user: widget.user,
            showEditIcon: true,
            radius: radius,
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(theme),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary(theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getMemberSinceText(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(theme),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(theme),
            borderRadius: AppTheme.largeRadius,
            border: Border.all(
              color: AppTheme.borderColor(theme),
              width: 1,
            ),
            boxShadow: AppTheme.softShadow(theme),
          ),
          child: Column(
            children: List.generate(children.length, (index) {
              return Column(
                children: [
                  children[index],
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppTheme.borderColor(theme).withOpacity(0.3),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);

    Color iconColor = AppTheme.primaryColor(theme);
    Color titleColor = AppTheme.textPrimary(theme);

    if (isDanger) {
      iconColor = Colors.red;
      titleColor = Colors.red;
    } else if (isDestructive) {
      iconColor = AppTheme.errorColor(theme);
      titleColor = AppTheme.textPrimary(theme);
    }

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: titleColor,
          fontWeight: isDanger ? FontWeight.w500 : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary(theme),
        ),
      )
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  Widget _buildAppInfo() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text("Bargain App",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Version 1.0.0",
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.textSecondary(theme))),
        const SizedBox(height: 4),
        Text("© 2025 Bargain. All rights reserved.",
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.textSecondary(theme))),
      ],
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Consumer<ThemeNotifier>(
          builder: (context, notifier, _) {
            return Container(
              padding: AppTheme.mediumPadding,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(Theme.of(context)),
                borderRadius: AppTheme.largeRadius,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Choose Theme',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildThemeOption(
                      'Light', Icons.light_mode, ThemeMode.light, notifier, context),
                  _buildThemeOption(
                      'Dark', Icons.dark_mode, ThemeMode.dark, notifier, context),
                  _buildThemeOption('System', Icons.settings,
                      ThemeMode.system, notifier, context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption(String label, IconData icon, ThemeMode mode,
      ThemeNotifier notifier, BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = notifier.themeMode == mode;
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? AppTheme.primaryColor(theme)
              : AppTheme.textSecondary(theme)),
      title: Text(label,
          style: TextStyle(
              color: isSelected
                  ? AppTheme.primaryColor(theme)
                  : AppTheme.textPrimary(theme))),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryColor(theme))
          : null,
      onTap: () {
        notifier.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
