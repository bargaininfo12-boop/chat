import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/services/user_service.dart';
import 'package:bargain/productadd/grid_layout/image_grid.dart';
import 'package:bargain/productadd/grid_layout/custom_app_bar.dart';
import 'package:bargain/productadd/add_product/Upload Data/upload_bottom_sheet.dart';
import 'package:bargain/chat/UX Layer/chat_list_screen.dart';
import 'package:bargain/account_setting/setting_page.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import '../productadd/search_page_Activity/widgets/bottom_navbar.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  Map<String, dynamic>? _userData;

  final _userService = UserService();
  final _authService = FirebaseAuthService.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isRefreshing = true);

      final firebaseUser = widget.user;
      await _userService.initializeUser(firebaseUser);
      await _authService.saveUserFCMToken();

      setState(() {
        _userData = _userService.currentUser?.toJson();
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      setState(() => _isRefreshing = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showUploadBottomSheet();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showUploadBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor(Theme.of(context)),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(
          color: AppTheme.borderColor(Theme.of(context)),
          width: 1,
        ),
      ),
      builder: (context) => const UploadBottomSheet(),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }
    return true;
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final currentUserId = _userService.currentUser?.uid ?? widget.user.uid;

    switch (_selectedIndex) {
      case 0:
        return RefreshIndicator(
          onRefresh: _loadUserData,
          color: AppTheme.primaryColor(theme),
          backgroundColor: AppTheme.surfaceColor(theme),
          child: ImageGrid(user: widget.user),
        );
      case 2:
        return ChatListScreen(currentUserId: currentUserId);
      case 3:
        return SettingPage(
          user: widget.user,
          onBack: () => setState(() => _selectedIndex = 0),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  PreferredSizeWidget? _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return CustomAppBar(
          user: widget.user,
          onSettingsTap: () => setState(() => _selectedIndex = 3),
        );
      case 2:
      case 3:
        return null;
      default:
        return SectionAppBar(
          title: 'Bargain',
          onBack: () => setState(() => _selectedIndex = 0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor(theme),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildBody(),
            ),
            if (_isRefreshing)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(theme).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Refreshing...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(theme),
            border: Border(
              top: BorderSide(
                color: AppTheme.dividerColor(theme),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor(theme).withOpacity(0.1),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
