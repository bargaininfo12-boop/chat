// Enhanced Date Header - Version 2.0
// Professional design with theme integration and animations
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bargain/app_theme/app_theme.dart'; // Your theme import

class DateHeader extends StatefulWidget {
  final DateTime date;
  final bool showAnimation;
  final EdgeInsetsGeometry? margin;
  final bool showIcon;

  const DateHeader({
    super.key,
    required this.date,
    this.showAnimation = true,
    this.margin,
    this.showIcon = false,
  });

  @override
  State<DateHeader> createState() => _DateHeaderState();
}

class _DateHeaderState extends State<DateHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    if (widget.showAnimation) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = _formatDate(widget.date);
    final isToday = _isToday(widget.date);
    final isYesterday = _isYesterday(widget.date);

    if (widget.showAnimation) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildDateContainer(theme, formattedDate, isToday, isYesterday),
            ),
          );
        },
      );
    }

    return _buildDateContainer(theme, formattedDate, isToday, isYesterday);
  }

  Widget _buildDateContainer(
      ThemeData theme,
      String formattedDate,
      bool isToday,
      bool isYesterday,
      ) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(theme, isToday, isYesterday),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBorderColor(theme, isToday, isYesterday),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor(theme).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showIcon) ...[
                Icon(
                  _getDateIcon(isToday, isYesterday),
                  size: 14,
                  color: _getTextColor(theme, isToday, isYesterday),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  color: _getTextColor(theme, isToday, isYesterday),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme, bool isToday, bool isYesterday) {
    if (isToday) {
      return AppTheme.primaryAccent(theme).withOpacity(0.1);
    } else if (isYesterday) {
      return AppTheme.secondaryAccent(theme).withOpacity(0.08);
    }
    return AppTheme.surfaceColor(theme).withOpacity(0.6);
  }

  Color _getBorderColor(ThemeData theme, bool isToday, bool isYesterday) {
    if (isToday) {
      return AppTheme.primaryAccent(theme).withOpacity(0.3);
    } else if (isYesterday) {
      return AppTheme.secondaryAccent(theme).withOpacity(0.2);
    }
    return AppTheme.borderColor(theme).withOpacity(0.3);
  }

  Color _getTextColor(ThemeData theme, bool isToday, bool isYesterday) {
    if (isToday) {
      return AppTheme.primaryAccent(theme);
    } else if (isYesterday) {
      return AppTheme.secondaryAccent(theme);
    }
    return AppTheme.textSecondary(theme);
  }

  IconData _getDateIcon(bool isToday, bool isYesterday) {
    if (isToday) {
      return Icons.today;
    } else if (isYesterday) {
      return Icons.history;
    }
    return Icons.calendar_month;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return today.isAtSameMomentAs(targetDate);
  }

  bool _isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final targetDate = DateTime(date.year, date.month, date.day);
    return yesterday.isAtSameMomentAs(targetDate);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat.EEEE().format(date); // Weekday name
    } else if (difference < 365 && now.year == date.year) {
      return DateFormat.MMMd().format(date); // Month Day
    } else {
      return DateFormat.yMMMd().format(date); // Year Month Day
    }
  }
}

// Alternative compact version for dense layouts
class CompactDateHeader extends StatelessWidget {
  final DateTime date;
  final bool showDivider;

  const CompactDateHeader({
    super.key,
    required this.date,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = _formatDate(date);
    final isToday = _isToday(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          if (showDivider)
            Expanded(
              child: Divider(
                color: AppTheme.dividerColor(theme),
                thickness: 0.5,
                endIndent: 8,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.primaryAccent(theme).withOpacity(0.1)
                  : AppTheme.surfaceColor(theme).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                color: isToday
                    ? AppTheme.primaryAccent(theme)
                    : AppTheme.textSecondary(theme),
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (showDivider)
            Expanded(
              child: Divider(
                color: AppTheme.dividerColor(theme),
                thickness: 0.5,
                indent: 8,
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return today.isAtSameMomentAs(targetDate);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat.EEEE().format(date);
    } else if (difference < 365 && now.year == date.year) {
      return DateFormat.MMMd().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}

// Usage examples:
/*
// Standard date header with animation
DateHeader(
  date: DateTime.now(),
  showAnimation: true,
  showIcon: true,
)

// Compact version with dividers
CompactDateHeader(
  date: DateTime.now(),
  showDivider: true,
)

// Custom margin
DateHeader(
  date: DateTime.now(),
  margin: EdgeInsets.symmetric(vertical: 12),
  showAnimation: false,
)
*/
