import 'dart:ui';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/productadd/add_product/Upload Data/CategoryManager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadBottomSheet extends StatefulWidget {
  const UploadBottomSheet({super.key});

  @override
  UploadBottomSheetState createState() => UploadBottomSheetState();
}

class UploadBottomSheetState extends State<UploadBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _headerController;
  late AnimationController _carouselController;
  late AnimationController _buttonController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerAnimation;
  late Animation<double> _scaleAnimation;

  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  static const _mainDuration = Duration(milliseconds: 600);
  static const _headerDuration = Duration(milliseconds: 800);
  static const _carouselDuration = Duration(milliseconds: 400);
  static const _buttonDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(duration: _mainDuration, vsync: this);
    _headerController = AnimationController(duration: _headerDuration, vsync: this);
    _carouselController = AnimationController(duration: _carouselDuration, vsync: this);
    _buttonController = AnimationController(duration: _buttonDuration, vsync: this);

    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _carouselController, curve: Curves.easeOutBack),
    );
  }

  void _setupListeners() {
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() => _currentIndex = _pageController.page!.round());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CategoryManager().precacheImages(context);
    });
  }

  void _startAnimationSequence() async {
    await _mainController.forward();
    await _headerController.forward();
    await _carouselController.forward();
    _buttonController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _headerController.dispose();
    _carouselController.dispose();
    _buttonController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.surfaceColor(theme).withValues(alpha: 0.96),
                  AppTheme.backgroundColor(theme).withValues(alpha: 0.98),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor(theme),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  _buildHeader(theme),
                  _buildSubtitle(theme),
                  _buildCategoryCarousel(theme),
                  _buildPageIndicator(theme),
                  _buildActionButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) => Transform.scale(
        scale: _headerAnimation.value,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor(theme).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // ✅ FIXED: Simple clear text - no gradient issues
              Text(
                'Select Category',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Text(
        'Choose the most relevant category for your product',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary(theme).withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildCategoryCarousel(ThemeData theme) {
    final screenSize = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _carouselController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          height: screenSize.height * 0.35,
          margin: EdgeInsets.symmetric(vertical: screenSize.height * 0.03),
          child: PageView.builder(
            controller: _pageController,
            itemCount: CategoryManager().categories.length,
            itemBuilder: (context, index) {
              final category = CategoryManager().categories[index];
              return _buildCategoryCard(theme, category, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      ThemeData theme, Map<String, dynamic> category, int index) {
    final isActive = index == _currentIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
            (category['color'] as Color).withValues(alpha: 0.9),
            (category['color'] as Color).withValues(alpha: 0.7),
          ]
              : [
            AppTheme.cardColor(theme),
            AppTheme.surfaceColor(theme),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? (category['color'] as Color).withValues(alpha: 0.3)
                : AppTheme.shadowColor(theme),
            blurRadius: isActive ? 18 : 8,
            offset: Offset(0, isActive ? 6 : 3),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderColor(theme).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _onCategorySelected(category),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    category['image'] as String,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ✅ FIXED: Proper text color based on card state
              Text(
                category['name'] as String,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isActive
                      ? Colors.white  // White text on colored card
                      : AppTheme.textPrimary(theme),  // Theme text on inactive card
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        CategoryManager().categories.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentIndex ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentIndex
                ? AppTheme.primaryColor(theme)
                : AppTheme.borderColor(theme).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 50 * (1 - _buttonController.value)),
        child: Opacity(
          opacity: _buttonController.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.borderColor(theme)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.textPrimary(theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(theme),
                      foregroundColor: AppTheme.textOnPrimary(theme),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _onCategorySelected(
                      CategoryManager().categories[_currentIndex],
                    ),
                    child: Text(
                      'Select Category',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.textOnPrimary(theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onCategorySelected(Map<String, dynamic> category) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => category['destination'] as Widget,
        settings: RouteSettings(arguments: category['name']),
      ),
    );
  }
}
