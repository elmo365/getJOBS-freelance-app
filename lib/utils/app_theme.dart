import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';

/// Centralized theme configuration for consistent UI
class AppTheme {
  // Spacing constants
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius constants
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 999.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Elevation constants
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  /// Get the app theme
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto', // Assuming default system font, or we can look up fonts.
      scaffoldBackgroundColor: botsSuperLightGrey, // Super light grey for card contrast
      
      // Color Scheme strictly using Brand Colors
      colorScheme: ColorScheme.fromSeed(
        seedColor: botsBlue,
        primary: botsBlue,
        onPrimary: botsWhite,
        secondary: botsYellow,
        onSecondary: botsBlack,
        tertiary: botsGreen,
        onTertiary: botsWhite,
        surface: botsSurface,
        onSurface: botsTextPrimary,
        error: botsError,
        onError: botsWhite,
        brightness: Brightness.light,
      ),

      // AppBar: Clean, White or very light, with distinct branding if needed
      appBarTheme: const AppBarTheme(
        backgroundColor: botsSurface,
        foregroundColor: botsTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: botsTextPrimary),
        titleTextStyle: TextStyle(
          color: botsTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Elevated Button: Primary Call to Action
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: botsBlue, // Primary Action Color
          foregroundColor: botsWhite,
          elevation: elevationLow,
          padding: const EdgeInsets.symmetric(
              horizontal: spacingL, vertical: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: botsBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: botsBlue,
          side: const BorderSide(color: botsBlue),
          padding: const EdgeInsets.symmetric(
              horizontal: spacingL, vertical: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: botsWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: spacingM, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: botsBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: botsBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: botsBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: botsError, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: botsError, width: 2),
        ),
        labelStyle: const TextStyle(
          color: botsTextSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: botsTextHint),
      ),

      // Card Theme: Clean, minimal shadow
      cardTheme: CardThemeData(
        color: botsSurface,
        elevation: elevationLow, // Subtle lift
        shadowColor: botsShadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide.none, // Clean look
        ),
        margin: EdgeInsets.zero,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: botsBackground,
        labelStyle: const TextStyle(color: botsTextPrimary),
        side: const BorderSide(color: botsBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
        selectedColor: botsBlue.withValues(alpha: 0.1),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: botsBlue,
        circularTrackColor: botsDivider,
      ),
      
      dividerTheme: const DividerThemeData(
        color: botsDivider,
        thickness: 1,
        space: 1,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: botsSurface,
        elevation: 2,
        shadowColor: botsShadowColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: botsBlue.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: botsBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: botsTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: botsBlue);
          }
          return const IconThemeData(color: botsTextSecondary);
        }),
      ),

      // Bottom Navigation Bar (Legacy / Material 2)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: botsSurface,
        elevation: 8,
        selectedItemColor: botsBlue,
        unselectedItemColor: botsTextSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  /// Text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: botsBlack,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: botsBlack,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: botsBlack,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: botsBlack,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: botsBlack,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: botsDarkGrey,
  );
}
