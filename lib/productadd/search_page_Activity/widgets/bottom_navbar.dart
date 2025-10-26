import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';


class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    this.selectedIndex = 0,
    required this.onItemTapped,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.shortDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      onTap: (index) {
        _animationController.forward().then((_) => _animationController.reverse());
        widget.onItemTapped(index);
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.surfaceColor(theme),
      selectedItemColor: AppTheme.primaryColor(theme),
      unselectedItemColor: AppTheme.textSecondary(theme),
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor(theme),
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppTheme.textSecondary(theme),
      ),
      elevation: 0,
      items: [
        BottomNavigationBarItem(
          icon: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.selectedIndex == 0 ? _scaleAnimation.value : 1.0,
                child: Icon(
                  widget.selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 26,
                  color: widget.selectedIndex == 0
                      ? AppTheme.primaryColor(theme)
                      : AppTheme.textSecondary(theme),
                ),
              );
            },
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.selectedIndex == 1 ? _scaleAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(theme).withOpacity(0.1),
                    borderRadius: AppTheme.smallRadius,
                    border: Border.all(
                      color: AppTheme.primaryColor(theme).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 24,
                    color: AppTheme.primaryColor(theme),
                  ),
                ),
              );
            },
          ),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.selectedIndex == 2 ? _scaleAnimation.value : 1.0,
                child: Icon(
                  widget.selectedIndex == 2 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  size: 26,
                  color: widget.selectedIndex == 2
                      ? AppTheme.primaryColor(theme)
                      : AppTheme.textSecondary(theme),
                ),
              );
            },
          ),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.selectedIndex == 3 ? _scaleAnimation.value : 1.0,
                child: Icon(
                  widget.selectedIndex == 3 ? Icons.settings : Icons.settings_outlined,
                  size: 26,
                  color: widget.selectedIndex == 3
                      ? AppTheme.primaryColor(theme)
                      : AppTheme.textSecondary(theme),
                ),
              );
            },
          ),
          label: 'Settings',
        ),
      ],
    );
  }
}
