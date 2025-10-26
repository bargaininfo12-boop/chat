import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bargain/app_theme/app_theme.dart';

class CustomSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController locationController;
  final TextEditingController searchController;

  final List<String> locationTags;
  final List<String> keywordTags;

  final ValueChanged<String> onLocationSelected;
  final ValueChanged<String> onKeywordSelected;
  final ValueChanged<String> onLocationTagDeleted;
  final ValueChanged<String> onKeywordTagDeleted;

  final Iterable<String> Function(String) locationSuggestionsBuilder;
  final Iterable<String> Function(String) keywordSuggestionsBuilder;

  final VoidCallback? onBackPressed;
  final bool enableHapticFeedback;

  const CustomSearchAppBar({
    super.key,
    required this.locationController,
    required this.searchController,
    required this.locationTags,
    required this.keywordTags,
    required this.onLocationSelected,
    required this.onKeywordSelected,
    required this.onLocationTagDeleted,
    required this.onKeywordTagDeleted,
    required this.locationSuggestionsBuilder,
    required this.keywordSuggestionsBuilder,
    this.onBackPressed,
    this.enableHapticFeedback = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 85);

  @override
  State<CustomSearchAppBar> createState() => _CustomSearchAppBarState();
}

class _CustomSearchAppBarState extends State<CustomSearchAppBar>
    with SingleTickerProviderStateMixin {
  bool get _hasTags =>
      widget.locationTags.isNotEmpty || widget.keywordTags.isNotEmpty;

  bool _isLocationMode = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late FocusNode _locationFocusNode;
  late FocusNode _searchFocusNode;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _fadeController =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _locationFocusNode = FocusNode();
    _searchFocusNode = FocusNode();

    _locationFocusNode.addListener(_onFocusChange);
    _searchFocusNode.addListener(_onFocusChange);

    widget.locationController.addListener(_onTextChange);
    widget.searchController.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _fadeController.dispose();
    _locationFocusNode.dispose();
    _searchFocusNode.dispose();
    widget.locationController.removeListener(_onTextChange);
    widget.searchController.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (_locationFocusNode.hasFocus || _searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChange() {
    if (_locationFocusNode.hasFocus || _searchFocusNode.hasFocus) {
      _updateOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() => _overlayEntry?.markNeedsBuild();

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 28,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 72),
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final theme = Theme.of(context);
    final activeController =
    _isLocationMode ? widget.locationController : widget.searchController;
    if (activeController.text.trim().isEmpty) return const SizedBox.shrink();

    final suggestions = _isLocationMode
        ? widget.locationSuggestionsBuilder(activeController.text)
        : widget.keywordSuggestionsBuilder(activeController.text);

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(theme),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderColor(theme).withValues(alpha: 0.3),
        ),
        boxShadow: AppTheme.softShadow(theme),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final option = suggestions.elementAt(index);
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _performHaptic();
              _removeOverlay();
              if (_isLocationMode) {
                widget.onLocationSelected(option);
                setState(() => _isLocationMode = false);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) _searchFocusNode.requestFocus();
                });
              } else {
                widget.onKeywordSelected(option);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _isLocationMode
                        ? Icons.location_on_outlined
                        : Icons.search,
                    size: 18,
                    color: AppTheme.iconColor(theme).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary(theme),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _performHaptic() {
    if (widget.enableHapticFeedback) HapticFeedback.lightImpact();
  }

  void _handleBack() {
    _performHaptic();
    if (widget.onBackPressed != null) {
      widget.onBackPressed!.call();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Widget _buildBackButton(ThemeData theme) {
    return GestureDetector(
      onTap: _handleBack,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.cardColor(theme),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor(theme).withValues(alpha: 0.3),
          ),
          boxShadow: AppTheme.softShadow(theme),
        ),
        child: Center(
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.iconColor(theme), size: 18),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    final activeController =
    _isLocationMode ? widget.locationController : widget.searchController;
    final activeFocusNode =
    _isLocationMode ? _locationFocusNode : _searchFocusNode;

    return Expanded(
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          height: 46,
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(theme),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor(theme).withValues(alpha: 0.25),
            ),
            boxShadow: AppTheme.softShadow(theme),
          ),
          child: TextField(
            controller: activeController,
            focusNode: activeFocusNode,
            cursorColor: AppTheme.primaryColor(theme),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary(theme),
              fontSize: 15.5,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                _isLocationMode
                    ? Icons.location_on_rounded
                    : Icons.search_rounded,
                color: AppTheme.primaryColor(theme),
                size: 20,
              ),
              hintText: _isLocationMode
                  ? 'Enter your location...'
                  : 'Search products...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary(theme).withValues(alpha: 0.7),
                fontSize: 15,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (val) {
              if (val.trim().isEmpty) return;
              _removeOverlay();
              if (_isLocationMode) {
                widget.onLocationSelected(val);
                setState(() => _isLocationMode = false);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) _searchFocusNode.requestFocus();
                });
              } else {
                widget.onKeywordSelected(val);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag, bool isLocation, ThemeData theme) {
    final Color baseColor =
    isLocation ? AppTheme.primaryColor(theme) : AppTheme.secondaryAccent(theme);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(theme),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(theme)),
        boxShadow: AppTheme.softShadow(theme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLocation ? Icons.location_on_rounded : Icons.label_rounded,
              size: 13, color: baseColor),
          const SizedBox(width: 5),
          Text(tag,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary(theme),
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: () {
              _performHaptic();
              _removeOverlay();
              if (isLocation) {
                widget.onLocationTagDeleted(tag);
                setState(() => _isLocationMode = true);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) _locationFocusNode.requestFocus();
                });
              } else {
                widget.onKeywordTagDeleted(tag);
              }
            },
            child: Icon(Icons.close_rounded,
                size: 12, color: AppTheme.errorColor(theme)),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(ThemeData theme) {
    if (!_hasTags) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft, // ✅ Left aligned tags
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...widget.locationTags.map((t) => _buildTagChip(t, true, theme)),
            ...widget.keywordTags.map((t) => _buildTagChip(t, false, theme)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: AppTheme.appBarBackground(theme),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Search",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary(theme),
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildBackButton(theme),
                    _buildSearchField(theme),
                  ],
                ),
                _buildTags(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
