// File: lib/app_theme/app_theme.dart
import 'package:bargain/app_theme/light_theme.dart';
import 'package:bargain/app_theme/dark_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => LightTheme.lightTheme;
  static ThemeData get darkTheme => EnhancedDarkTheme.darkTheme;

  // ===== M3 Surface Variants =====
  static Color surfaceContainerLowest(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.surfaceContainerLowest
          : LightTheme.surfaceContainerLowest;

  static Color surfaceContainerLow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.surfaceContainerLow
          : LightTheme.surfaceContainerLow;

  static Color surfaceContainer(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.surfaceContainer
          : LightTheme.surfaceContainer;

  static Color surfaceContainerHigh(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.surfaceContainerHigh
          : LightTheme.surfaceContainerHigh;

  static Color surfaceContainerHighest(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.surfaceContainerHighest
          : LightTheme.surfaceContainerHighest;

  static Color outline(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.outline
          : LightTheme.outline;

  static Color outlineVariant(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.outlineVariant
          : LightTheme.outlineVariant;

  // ===== Message Bubble styling =====
  static Color senderBubbleColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.senderBubbleColor(theme)
          : LightTheme.senderBubbleColor(theme);

  static Color receiverBubbleColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.receiverBubbleColor(theme)
          : LightTheme.receiverBubbleColor(theme);

  static TextStyle messageTextStyle(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.messageTextBase
          : LightTheme.messageTextStyle;

  static TextStyle timeTextStyle(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.timeTextBase
          : LightTheme.timeTextStyle;

  static double get bubbleRadius => EnhancedDarkTheme.bubbleRadius;
  static double get bubblePaddingHorizontal => EnhancedDarkTheme.bubblePaddingHorizontal;
  static double get bubblePaddingVertical => EnhancedDarkTheme.bubblePaddingVertical;
  static double get bubbleMargin => EnhancedDarkTheme.bubbleMargin;

  // ===== Surfaces / Containers =====
  static Border glassBorder(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? Border.all(color: EnhancedDarkTheme.borderColor, width: 0.5)
          : Border.all(color: LightTheme.outline.withValues(alpha: 0.2), width: 1);

  static List<BoxShadow> glassInnerGlow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.softShadow
          : LightTheme.glassInnerGlow;

  static List<BoxShadow> glassShadow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.mediumShadow
          : LightTheme.glassShadow;

  static BoxDecoration backgroundDecoration(ThemeData theme) =>
      BoxDecoration(color: backgroundColor(theme));

  // ===== Brand / Accent =====
  static Color primaryAccent(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.primary
          : LightTheme.primary;

  static Color primaryContainer(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.primaryContainer
          : LightTheme.primaryContainer;

  static Color onPrimaryContainer(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.onPrimaryContainer
          : LightTheme.onPrimaryContainer;

  static Color secondaryAccent(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.secondary
          : LightTheme.secondary;

  static Color secondaryContainer(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.secondaryContainer
          : LightTheme.secondaryContainer;

  static Color tertiaryAccent(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.tertiary
          : LightTheme.tertiary;

  static Color accentColor(ThemeData theme) => primaryAccent(theme);

  // ===== Semantic =====
  static Color successColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.successColor
          : LightTheme.successColor;

  static Color warningColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.warningColor
          : LightTheme.warningColor;

  static Color errorColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.error
          : LightTheme.error;

  static Color infoColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.infoColor
          : LightTheme.infoColor;

  // ===== Core surfaces/colors =====
  static Color primaryColor(ThemeData theme) => primaryAccent(theme);

  static Color backgroundColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.background
          : LightTheme.background;

  static Color surfaceColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.surface
          : LightTheme.surface;

  static Color cardColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.cardBackground
          : LightTheme.cardBackground;

  static Color appBarBackground(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.appBarBackground
          : LightTheme.appBarBackground;

  static Color inputFieldBackground(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.inputFieldBackground
          : LightTheme.inputFieldBackground;

  static Color borderColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.borderColor
          : LightTheme.borderColor;

  static Color dividerColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.dividerColor
          : LightTheme.dividerColor;

  static Color iconColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.iconColor
          : LightTheme.iconColor;

  static Color shadowColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.shadow
          : LightTheme.shadow;

  static Color elevationShadow(ThemeData theme) => shadowColor(theme);

  // ===== Text colors =====
  static Color textPrimary(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.onSurface
          : LightTheme.onSurface;

  static Color primaryText(ThemeData theme) => textPrimary(theme);
  static Color textColor(ThemeData theme) => textPrimary(theme);

  static Color textSecondary(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.onSurfaceVariant
          : LightTheme.onSurfaceVariant;

  static Color secondaryText(ThemeData theme) => textSecondary(theme);

  static Color textDisabled(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.disabledText
          : LightTheme.disabledText;

  static Color disabledText(ThemeData theme) => textDisabled(theme);

  static Color textHint(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.hintText
          : LightTheme.hintText;

  static Color hintText(ThemeData theme) => textHint(theme);

  static Color textOnAccent(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.onPrimary
          : LightTheme.onPrimary;

  static Color textOnPrimary(ThemeData theme) => textOnAccent(theme);

  static Color textOnSecondary(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.onSecondary
          : LightTheme.onSecondary;

  // ===== Shadows =====
  static List<BoxShadow> softShadow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.softShadow
          : LightTheme.softShadow;

  static List<BoxShadow> mediumShadow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.mediumShadow
          : LightTheme.mediumShadow;

  static List<BoxShadow> hardShadow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.hardShadow
          : LightTheme.hardShadow;

  static List<BoxShadow> cardShadow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.cardShadow
          : LightTheme.cardShadow;

  static List<BoxShadow> elevatedShadow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.elevatedShadow
          : LightTheme.elevatedShadow;

  // ===== Radii & spacing =====
  static BorderRadius get smallRadius => EnhancedDarkTheme.smallRadius;
  static BorderRadius get mediumRadius => EnhancedDarkTheme.mediumRadius;
  static BorderRadius get largeRadius => EnhancedDarkTheme.largeRadius;
  static BorderRadius get extraLargeRadius => EnhancedDarkTheme.extraLargeRadius;

  static EdgeInsets get smallPadding => EnhancedDarkTheme.smallPadding;
  static EdgeInsets get mediumPadding => EnhancedDarkTheme.mediumPadding;
  static EdgeInsets get largePadding => EnhancedDarkTheme.largePadding;
  static EdgeInsets get extraLargePadding => EnhancedDarkTheme.extraLargePadding;

  static Duration get shortDuration => EnhancedDarkTheme.shortDuration;
  static Duration get mediumDuration => EnhancedDarkTheme.mediumDuration;
  static Duration get longDuration => EnhancedDarkTheme.longDuration;

  // ===== Shimmer / overlay / effects =====
  static Color shimmerBaseColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.shimmerBaseColor
          : LightTheme.shimmerBaseColor;

  static Color shimmerHighlightColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.shimmerHighlightColor
          : LightTheme.shimmerHighlightColor;

  static Color loadingOverlayColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.loadingOverlayColor
          : LightTheme.loadingOverlayColor;

  static Color rippleColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.rippleColor
          : LightTheme.rippleColor;

  static Color focusColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.focusColor
          : LightTheme.focusColor;

  static Color hoverColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.hoverColor
          : LightTheme.hoverColor;

  static Color splashColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.splashColor
          : LightTheme.splashColor;

  static Gradient primaryGradient(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.primaryGradient
          : LightTheme.primaryGradient;

  static Gradient backgroundGradient(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? EnhancedDarkTheme.backgroundGradient
          : LightTheme.backgroundGradient;

  // ===== Custom Accent Colors =====
  static Color likeRed(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? const Color(0xFFFF6B6B)  // 🔴 Dark mode - warm, soft red
          : const Color(0xFFE53935); // 🔴 Light mode - crisp material red


  // ===== Custom chat colors =====
  static Color customSenderBubbleColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? const Color(0xFF006D77)
          : const Color(0xFFCCFBF1);

  static Color customReceiverBubbleColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFF1F1F1);

  static Color customChatBackground(ThemeData theme) => backgroundColor(theme);

  static Color customMessageTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark ? Colors.white : Colors.black;

  static Color customTimeTextColor(ThemeData theme) => textSecondary(theme);

  static Color customStatusIconSent(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFFB0B3BA) : const Color(0xFF8E8E93);
  static Color customStatusIconDelivered(ThemeData theme) => customStatusIconSent(theme);
  static Color customStatusIconRead(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFF4FC3F7) : const Color(0xFF007AFF);
  static Color customStatusIconFailed(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFFFF6B6B) : const Color(0xFFFF3B30);
  static Color customStatusIconSending(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFFFFB74D) : const Color(0xFFFF9500);

  // ===== Status icon palette =====
  static Color statusIconSent(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFFE0E0E0) : const Color(0xFF424242);
  static Color statusIconDelivered(ThemeData theme) => statusIconSent(theme);
  static Color statusIconRead(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
  static Color statusIconFailed(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
  static Color statusIconSending(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);

  static Color statusIconBackground(ThemeData theme, bool isSender) {
    if (!isSender) return Colors.transparent;
    return theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.95);
  }

  static Color statusIconBorder(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.1);

  static Color getStatusIconColor(ThemeData theme, int status) {
    switch (status) {
      case -1:
        return statusIconFailed(theme);
      case 0:
        return statusIconSending(theme);
      case 1:
        return statusIconSent(theme);
      case 2:
        return statusIconDelivered(theme);
      case 3:
        return statusIconRead(theme);
      default:
        return statusIconSending(theme);
    }
  }

  static IconData getStatusIcon(int status) {
    switch (status) {
      case -1:
        return Icons.error_outline;
      case 0:
        return Icons.access_time;
      case 1:
        return Icons.done;
      case 2:
        return Icons.done_all;
      case 3:
        return Icons.done_all;
      default:
        return Icons.access_time;
    }
  }

  static String getStatusText(int status) {
    switch (status) {
      case -1:
        return 'Failed';
      case 0:
        return 'Sending';
      case 1:
        return 'Sent';
      case 2:
        return 'Delivered';
      case 3:
        return 'Read';
      default:
        return 'Unknown';
    }
  }

  // ===== Utility =====
  static bool isDarkMode(ThemeData theme) => theme.brightness == Brightness.dark;
  static bool isLightMode(ThemeData theme) => theme.brightness == Brightness.light;

  static Color adaptiveColor(ThemeData theme, Color lightColor, Color darkColor) {
    return theme.brightness == Brightness.dark ? darkColor : lightColor;
  }

  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }

  static void debugM3Colors(ThemeData theme) {
    if (!kDebugMode) return;
    debugPrint('=== M3 THEME DEBUG ===');
    debugPrint('Mode: ${isDarkMode(theme) ? 'Dark' : 'Light'}');
    debugPrint('Primary: ${theme.colorScheme.primary}');
    debugPrint('PrimaryContainer: ${theme.colorScheme.primaryContainer}');
    debugPrint('Surface: ${theme.colorScheme.surface}');
    debugPrint('SurfaceContainer: ${surfaceContainer(theme)}');
    debugPrint('====================');
  }
}
