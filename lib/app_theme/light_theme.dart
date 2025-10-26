// File: lib/app_theme/light_theme.dart
// Material 3 Complete Light Theme
// ✅ M3 Color System with proper surface variants
// ✅ M3 Typography Scale
// ✅ M3 Elevation with surface tints
// ✅ M3 State layers (hover, focus, pressed)
// ✅ M3 Shape system

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LightTheme {
  // ===== M3 Color Tokens =====

  // Primary palette (Indigo)
  static const Color primary = Color(0xFF0061A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD1E4FF);
  static const Color onPrimaryContainer = Color(0xFF001D36);

  // Secondary palette (Teal)
  static const Color secondary = Color(0xFF006B5D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF70F5E0);
  static const Color onSecondaryContainer = Color(0xFF00201B);

  // Tertiary palette (Purple)
  static const Color tertiary = Color(0xFF5E5A8D);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE5DEFF);
  static const Color onTertiaryContainer = Color(0xFF1A1746);

  // Error palette
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Neutral/Surface palette
  static const Color surface = Color(0xFFFCFCFF);
  static const Color surfaceDim = Color(0xFFDCDCE0);
  static const Color surfaceBright = Color(0xFFFCFCFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F6FA);
  static const Color surfaceContainer = Color(0xFFF0F0F4);
  static const Color surfaceContainerHigh = Color(0xFFEAEAEE);
  static const Color surfaceContainerHighest = Color(0xFFE5E5E9);

  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF43474E);

  // Background (M3 uses surface)
  static const Color background = surface;
  static const Color onBackground = onSurface;

  // Outline
  static const Color outline = Color(0xFF73777F);
  static const Color outlineVariant = Color(0xFFC3C6CF);

  // Inverse
  static const Color inverseSurface = Color(0xFF2F3033);
  static const Color inverseOnSurface = Color(0xFFF1F0F4);
  static const Color inversePrimary = Color(0xFF9ECAFF);

  // Shadow & Scrim
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  // Surface tint (for elevation)
  static const Color surfaceTint = primary;

  // ===== Legacy Color Aliases =====
  static const Color primaryBackground = background;
  static const Color surfaceBackground = surface;
  static const Color cardBackground = surfaceContainerHigh;
  static const Color appBarBackground = surfaceContainer;

  static const Color primaryAccent = primary;
  static const Color secondaryAccent = secondary;
  static const Color tertiaryAccent = tertiary;

  static const Color primaryText = onSurface;
  static const Color secondaryText = onSurfaceVariant;
  static const Color disabledText = Color(0xFF9B9FA8);
  static const Color hintText = onSurfaceVariant;

  static const Color dividerColor = outlineVariant;
  static const Color borderColor = outline;
  static const Color iconColor = onSurfaceVariant;
  static const Color inputFieldBackground = surfaceContainerHighest;

  static const Color errorColor = error;
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);
  static const Color infoColor = Color(0xFF1976D2);

  static const Color shadowColor = shadow;
  static const Color elevationShadow = shadow;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ===== M3 ColorScheme =====
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: shadow,
        scrim: scrim,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
        surfaceTint: surfaceTint,
      ),

      scaffoldBackgroundColor: background,

      // ===== M3 Typography Scale =====
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12, color: onSurface),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.16, color: onSurface),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.22, color: onSurface),

        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.25, color: onSurface),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.29, color: onSurface),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.33, color: onSurface),

        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0, height: 1.27, color: onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.50, color: onSurface),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43, color: onSurface),

        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.50, color: onSurface),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43, color: onSurface),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33, color: onSurfaceVariant),

        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43, color: onSurface),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.33, color: onSurface),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45, color: onSurface),
      ),

      // ===== AppBar Theme =====
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceContainer,
        foregroundColor: onSurface,
        surfaceTintColor: surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 3,
        shadowColor: shadow,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0, color: onSurface),
        iconTheme: IconThemeData(color: onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: onSurfaceVariant, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // ===== Card Theme =====
      cardTheme: CardThemeData(
        color: surfaceContainerHigh,
        surfaceTintColor: surfaceTint,
        elevation: 1,
        shadowColor: shadow,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ===== Input Decoration =====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        hoverColor: primary.withValues(alpha: 0.08),
        focusColor: primary.withValues(alpha: 0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 16),
        hintStyle: const TextStyle(color: onSurfaceVariant, fontSize: 16),
        helperStyle: const TextStyle(color: onSurfaceVariant, fontSize: 12),
        errorStyle: const TextStyle(color: error, fontSize: 12),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ===== Button Themes (M3 Style) =====
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shadowColor: shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceContainerLow,
          foregroundColor: primary,
          disabledBackgroundColor: onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: onSurface.withValues(alpha: 0.38),
          elevation: 1,
          shadowColor: shadow,
          surfaceTintColor: surfaceTint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: onSurface.withValues(alpha: 0.38),
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      ),

      // ===== FAB Theme =====
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryContainer,
        foregroundColor: onPrimaryContainer,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 3,
        disabledElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ===== Icon Theme =====
      iconTheme: const IconThemeData(color: onSurfaceVariant, size: 24),

      // ===== Divider =====
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ===== Bottom Navigation =====
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainer,
        selectedItemColor: onSecondaryContainer,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),

      // ===== Navigation Bar (M3) =====
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: surfaceTint,
        indicatorColor: secondaryContainer,
        elevation: 3,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurface);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: onSecondaryContainer, size: 24);
          }
          return const IconThemeData(color: onSurfaceVariant, size: 24);
        }),
      ),

      // ===== Tab Bar =====
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: surfaceContainerHighest,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.1),
      ),

      // ===== Dialog =====
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerHigh,
        surfaceTintColor: surfaceTint,
        elevation: 3,
        shadowColor: shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        titleTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        contentTextStyle: const TextStyle(
          color: onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
      ),

      // ===== SnackBar =====
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: inverseSurface,
        contentTextStyle: TextStyle(color: inverseOnSurface, fontSize: 14),
        actionTextColor: inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),

      // ===== Chip =====
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHighest,
        selectedColor: secondaryContainer,
        disabledColor: onSurface.withValues(alpha: 0.12),
        labelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 14),
        secondaryLabelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 12),
        brightness: Brightness.light,
        deleteIconColor: onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        side: const BorderSide(color: outline),
      ),

      // ===== Switch =====
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          if (states.contains(WidgetState.disabled)) return onSurface.withValues(alpha: 0.38);
          return outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          if (states.contains(WidgetState.disabled)) return surfaceContainerHighest.withValues(alpha: 0.12);
          return surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return outline;
        }),
      ),

      // ===== Checkbox =====
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: const BorderSide(color: onSurfaceVariant, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),

      // ===== Radio =====
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return onSurfaceVariant;
        }),
      ),

      // ===== Slider =====
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceContainerHighest,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: const TextStyle(color: onPrimary, fontSize: 14),
      ),

      // ===== Progress Indicator =====
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceContainerHighest,
        circularTrackColor: surfaceContainerHighest,
      ),

      // ===== List Tile =====
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: secondaryContainer.withValues(alpha: 0.12),
        iconColor: onSurfaceVariant,
        textColor: onSurface,
        titleTextStyle: const TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w500),
        subtitleTextStyle: const TextStyle(color: onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // ===== Drawer =====
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceContainerLow,
        surfaceTintColor: surfaceTint,
        elevation: 1,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),

      // ===== Bottom Sheet =====
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLow,
        surfaceTintColor: surfaceTint,
        modalBackgroundColor: surfaceContainerLow,
        elevation: 1,
        modalElevation: 1,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: onSurfaceVariant,
      ),

      // ===== Tooltip =====
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: inverseSurface,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        textStyle: const TextStyle(color: inverseOnSurface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ===== Chat Bubble Helpers =====
  static Color senderBubbleColor(ThemeData theme) => primaryContainer;
  static Color receiverBubbleColor(ThemeData theme) => surfaceContainerHigh;

  static const TextStyle messageTextStyle = TextStyle(
    color: onSurface,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const TextStyle timeTextStyle = TextStyle(
    color: onSurfaceVariant,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ===== Legacy Compatibility =====
  static const Color backgroundColor = background;
  static const Color surfaceColor = surface;
  static const Color cardColor = surfaceContainerHigh;
  static const Color primaryColor = primary;
  static const Color accentColor = primary;
  static const Color textPrimary = onSurface;
  static const Color textSecondaryCompat = onSurfaceVariant;
  static const Color textDisabled = disabledText;
  static const Color textHint = hintText;
  static const Color textOnAccent = onPrimary;
  static const Color textOnPrimary = onPrimary;
  static const Color textOnSecondary = onSecondary;

  // ===== Constants =====
  static const double blurSigma = 10.0;
  static const double bubbleShadowBlurRadius = 4.0;

  static Border glassBorder(ThemeData theme) => Border.all(
    color: outline.withValues(alpha: 0.2),
    width: 1,
  );

  static const List<BoxShadow> glassInnerGlow = [
    BoxShadow(
      color: Color(0x0FFFFFFF),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const BoxDecoration backgroundDecoration = BoxDecoration(
    color: background,
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> mediumShadow = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4),
  ];
  static const List<BoxShadow> hardShadow = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 8),
  ];
  static const List<BoxShadow> cardShadow = mediumShadow;
  static const List<BoxShadow> elevatedShadow = hardShadow;

  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);
  static const Color loadingOverlayColor = Color(0x80FFFFFF);

  static final Color rippleColor = primary.withValues(alpha: 0.12);
  static final Color focusColor = primary.withValues(alpha: 0.12);
  static final Color hoverColor = onSurface.withValues(alpha: 0.08);
  static final Color splashColor = primary.withValues(alpha: 0.12);

  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [background, surfaceContainerLow],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
