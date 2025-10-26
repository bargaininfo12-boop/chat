import 'package:bargain/A_User_Data/profile_picture_widget.dart';
import 'package:bargain/productadd/search_page_Activity/searchpage/searchpage.dart';
import 'package:bargain/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bargain/app_theme/app_theme.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final User user;
  final VoidCallback onSettingsTap;

  const CustomAppBar({
    super.key,
    required this.user,
    required this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(138.0);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with TickerProviderStateMixin {
  late final AnimationController _searchAnimationController;
  late final AnimationController _titleAnimationController;

  late final Animation<double> _searchScaleAnimation;
  late final Animation<double> _titleSlideAnimation;
  late final Animation<double> _titleFadeAnimation;

  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _titleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _setupAnimations();
    _titleAnimationController.forward();
  }

  void _setupAnimations() {
    _searchScaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _titleSlideAnimation = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _titleAnimationController.dispose();
    super.dispose();
  }

  void _handleSearchTap() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SearchBarPage(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _handleProfileTap() {
    HapticFeedback.selectionClick();
    widget.onSettingsTap();
  }

  // Animated title “Bargain”
  Widget _buildMatteTitle(ThemeData theme) {
    return AnimatedBuilder(
      animation: _titleAnimationController,
      builder: (_, __) {
        return Opacity(
          opacity: _titleFadeAnimation.value,
          child: Transform.translate(
            offset: Offset(_titleSlideAnimation.value, 0),
            child: Text(
              'Bargain',
              style: TextStyle(
                color: AppTheme.textPrimary(theme),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'Roboto',
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  // Search bar with subtle press animation
  Widget _buildMatteSearchBar(ThemeData theme) {
    return AnimatedBuilder(
      animation: _searchScaleAnimation,
      builder: (_, __) {
        return GestureDetector(
          onTapDown: (_) => _searchAnimationController.forward(),
          onTapUp: (_) {
            _searchAnimationController.reverse();
            _handleSearchTap();
          },
          onTapCancel: () => _searchAnimationController.reverse(),
          child: Transform.scale(
            scale: _searchScaleAnimation.value,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.cardColor(theme),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.borderColor(theme),
                  width: 1,
                ),
                boxShadow: AppTheme.softShadow(theme),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppTheme.primaryColor(theme),
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Search products, categories...',
                      style: TextStyle(
                        color: AppTheme.textSecondary(theme),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.mic_rounded,
                      color: AppTheme.iconColor(theme),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Profile avatar (connected with UserService reactive user)
  Widget _buildMatteProfileButton(ThemeData theme) {
    final currentUser = _userService.currentUser;
    final displayUser = currentUser != null ? widget.user : widget.user;

    return GestureDetector(
      onTap: _handleProfileTap,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ProfilePictureWidget(
          user: displayUser,
          radius: 20,
          showEditIcon: false,
          onImageTap: _handleProfileTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.preferredSize.height + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        color: AppTheme.appBarBackground(theme),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor(theme),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildMatteTitle(theme)),
                    _buildMatteProfileButton(theme),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildMatteSearchBar(theme),
            ],
          ),
        ),
      ),
    );
  }
}
