import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/utils/colors.dart';

/// Modern Design System for getJOBS App
/// Provides consistent spacing, typography, colors, gradients, and animations
class AppDesignSystem {
  // ==================== SPACING ====================

  /// Extra small spacing (4px)
  static const double spaceXS = AppTheme.spacingXS;

  /// Small spacing (8px)
  static const double spaceS = AppTheme.spacingS;

  /// Medium spacing (16px)
  static const double spaceM = AppTheme.spacingM;

  /// Large spacing (24px)
  static const double spaceL = AppTheme.spacingL;

  /// Extra large spacing (32px)
  static const double spaceXL = AppTheme.spacingXL;

  /// Extra extra large spacing (48px)
  static const double spaceXXL = AppTheme.spacingXXL;

  // ==================== BORDER RADIUS ====================

  /// Small radius (8px)
  static const double radiusS = AppTheme.radiusS;

  /// Medium radius (12px)
  static const double radiusM = AppTheme.radiusM;

  /// Large radius (16px)
  static const double radiusL = AppTheme.radiusL;

  /// Extra large radius (24px)
  static const double radiusXL = AppTheme.radiusXL;

  /// Circular radius
  static const double radiusCircular = AppTheme.radiusRound;

  // ==================== UI ELEMENT SIZES ====================

  /// Profile image size (120px)
  static const double profileImageSize = 120.0;

  /// Large icon size (48px)
  static const double iconSizeLarge = 48.0;

  /// Medium icon size (24px)
  static const double iconSizeMedium = 24.0;

  /// Small icon size (16px)
  static const double iconSizeSmall = 16.0;

  /// Profile image border width (4px)
  static const double profileImageBorderWidth = 4.0;

  /// Standard button height (56px)
  static const double buttonHeightStandard = 56.0;

  /// Standard line height for body text (1.5)
  static const double lineHeightBody = 1.5;

  // ==================== 2025 VIVID COLOR PALETTE ====================
  // Inspired by Frame-1.webp reference - bold, vivid, professional

  /// Primary brand color - BOTS Blue for hero cards
  static const Color primaryBlue = botsBlue;
  static const Color primaryColor = botsBlue; // Legacy alias
  static const Color brandRed = botsErrorRed; // Legacy alias

  /// Secondary brand color - Brand Yellow
  static const Color primaryOrange = botsYellow;

  /// Success green - Rich, vibrant
  static const Color success = botsSuccessGreen;

  /// Error red - Clear, not aggressive
  static const Color error = botsErrorRed;

  /// Warning amber - Attention-grabbing
  static const Color warning = botsWarningAmber;

  /// Info blue - Professional
  static const Color info = botsBlue;

  /// Background light - Near white (not pure white)
  static const Color backgroundLight = botsNearlyWhite;

  /// Background dark
  static const Color backgroundDark = botsBlack;

  /// Surface light - Pure white for cards
  static const Color surfaceLight = botsWhite;

  /// Surface dark
  static const Color surfaceDark = botsBlack;

  /// Text primary - Dark grey for readability
  static const Color textPrimary = botsTextPrimary;

  /// Text secondary - Softer grey
  static const Color textSecondary = botsTextSecondary;

  /// Text hint - Subtle
  static const Color textHint = botsTextHint;

  /// Divider color - Very subtle
  static const Color divider = botsDivider;

  // ==================== BOTS BRAND ACCENT COLORS ====================
  // Using BOTSJOBSCONNECT brand colors in Frame-1.webp style

  /// Accent 1 - BOTS Green (primary brand)
  static const Color accent1 = botsGreen;

  /// Accent 2 - BOTS Blue (secondary brand)
  static const Color accent2 = botsBlue;

  /// Accent 3 - BOTS Yellow (tertiary brand)
  static const Color accent3 = botsYellow;

  // Legacy aliases for backward compatibility
  static const Color accentPurple = botsBlue; // Use BOTS Blue instead
  static const Color accentOrange = botsYellow; // Use BOTS Yellow instead
  static const Color accentTeal = botsGreen; // Use BOTS Green instead

  // ==================== GRADIENTS ====================

  /// Primary gradient (Brand)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [botsGreen, botsBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient (Brand)
  static const LinearGradient successGradient = LinearGradient(
    colors: [botsGreen, botsGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning gradient (Brand)
  static const LinearGradient warningGradient = LinearGradient(
    colors: [botsYellow, botsYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error gradient
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Colors.red, Colors.red],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle gradient (white)
  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Colors.white, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark gradient
  static const LinearGradient darkGradient = LinearGradient(
    colors: [botsBlack, botsBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== SHADOWS ====================

  // ==================== ELEVATION (TOKENS) ====================

  static const double elevationLow = AppTheme.elevationLow;
  static const double elevationMedium = AppTheme.elevationMedium;
  static const double elevationHigh = AppTheme.elevationHigh;

  /// Light shadow (2025 Frame-1 style: very soft, natural)
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: botsShadowColor,
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  /// Medium shadow (2025 Frame-1 style: card elevation)
  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  /// Heavy shadow (2025 Frame-1 style: elevated modals)
  static List<BoxShadow> get heavyShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  /// Colored shadow (2025 vivid: tinted for accent cards)
  static List<BoxShadow> coloredShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  /// Card shadow (2025 Frame-1 style: subtle, professional)
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  // ==================== ANIMATIONS ====================

  /// Fast animation duration (200ms)
  static const Duration animationFast = AppTheme.animationFast;

  /// Normal animation duration (300ms)
  static const Duration animationNormal = AppTheme.animationNormal;

  /// Slow animation duration (500ms)
  static const Duration animationSlow = AppTheme.animationSlow;

  /// Standard animation curve
  static const Curve animationCurve = Curves.easeInOut;

  /// Bounce animation curve
  static const Curve animationBounce = Curves.elasticOut;

  /// Decelerate curve (2025 pattern: natural motion)
  static const Curve animationDecelerate = Curves.decelerate;

  /// Fast out slow in (2025 pattern: Material motion)
  static const Curve animationFastOutSlowIn = Curves.fastOutSlowIn;

  // ==================== 2025 SURFACE COLORS ====================
  // Frame-1.webp inspired: Clean white backgrounds, vivid accents

  /// Near white background - Primary app background
  static const Color nearlyWhite = botsNearlyWhite;

  /// Super light grey - For backgrounds to make white cards pop
  static const Color superLightGrey = botsSuperLightGrey;

  /// Soft background - Cards and sections
  static const Color softBackground = botsSoftBackground;

  /// Card surface - Pure white for contrast
  static const Color cardSurface = botsCardSurface;

  /// Chip/tag background - Subtle grey
  static const Color chipBackground = Color(0xFFF3F4F6);

  /// Spacer/divider color - Very subtle
  static const Color spacerColor = botsDivider;

  // ==================== BOTSJOBSCONNECT BRAND COLORS ====================
  // Primary brand colors: Yellow, Green, Blue, White, Black

  /// BOTS Yellow - Primary brand color (vibrant, optimistic)
  static const Color brandYellow = botsYellow;

  /// BOTS Green - Secondary brand color (professional, trustworthy)
  static const Color brandGreen = botsGreen;

  /// BOTS Blue - Accent brand color (bold, modern)
  static const Color brandBlue = botsBlue;

  /// BOTS White - For backgrounds and light elements
  static const Color brandWhite = botsWhite;

  /// BOTS Black - For text and dark elements
  static const Color brandBlack = botsBlack;

  /// Hero card primary - BOTS Blue for hero sections (balanced color usage)
  static const Color heroPrimary = botsBlue;

  /// Hero card secondary - BOTS Green for gradients (balanced color usage)
  static const Color heroSecondary = botsGreen;

  /// Hero accent - BOTS Yellow for highlights (balanced color usage)
  static const Color heroAccent = botsYellow;

  // ==================== GLASS MORPHISM (2025) ====================

  /// Create glass morphism decoration
  static BoxDecoration glassDecoration({
    Color? tintColor,
    double blurAmount = 10.0,
    double opacity = 0.8,
    double borderRadius = radiusL,
  }) {
    final effectiveTint = tintColor ?? const Color(0xFFD7E0F9);
    return BoxDecoration(
      color: effectiveTint.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 0.5,
      ),
    );
  }

  /// Gradient overlay for glass effect
  static LinearGradient glassGradient({
    Color? startColor,
    Color? endColor,
  }) {
    return LinearGradient(
      colors: [
        (startColor ?? Colors.white).withValues(alpha: 0.1),
        (endColor ?? Colors.white).withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ==================== TYPOGRAPHY ====================

  /// Get responsive font size based on screen width
  static double _responsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return baseSize * 1.1; // Desktop
    if (screenWidth > 600) return baseSize * 1.05; // Tablet
    return baseSize; // Mobile
  }

  /// Display large text style - Hero titles, major headings
  static TextStyle displayLarge(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.displayLarge;
    final fontSize = _responsiveFontSize(context, 57);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.1,
      letterSpacing: -0.5,
    );
  }

  /// Display medium text style - Large section headers
  static TextStyle displayMedium(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.displayMedium;
    final fontSize = _responsiveFontSize(context, 45);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.15,
      letterSpacing: -0.25,
    );
  }

  /// Display small text style - Important section headers
  static TextStyle displaySmall(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.displaySmall;
    final fontSize = _responsiveFontSize(context, 36);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.2,
      letterSpacing: -0.25,
    );
  }

  /// Headline large text style - Page titles, major content headers
  static TextStyle headlineLarge(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.headlineLarge;
    final fontSize = _responsiveFontSize(context, 32);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.25,
      letterSpacing: -0.25,
    );
  }

  /// Headline medium text style - Screen titles, card headers
  static TextStyle headlineMedium(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.headlineMedium;
    final fontSize = _responsiveFontSize(context, 28);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.3,
      letterSpacing: -0.25,
    );
  }

  /// Headline small text style - Subsection headers, important labels
  static TextStyle headlineSmall(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.headlineSmall;
    final fontSize = _responsiveFontSize(context, 24);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.35,
      letterSpacing: -0.25,
    );
  }

  /// Title large text style - Card titles, dialog titles
  static TextStyle titleLarge(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.titleLarge;
    final fontSize = _responsiveFontSize(context, 22);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.3,
      letterSpacing: 0.0,
    );
  }

  /// Title medium text style - List item titles, form section headers
  static TextStyle titleMedium(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.titleMedium;
    final fontSize = _responsiveFontSize(context, 16);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.4,
      letterSpacing: 0.15,
    );
  }

  /// Title small text style - Supporting titles, metadata
  static TextStyle titleSmall(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.titleSmall;
    final fontSize = _responsiveFontSize(context, 14);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.45,
      letterSpacing: 0.1,
    );
  }

  /// Body large text style - Primary content, descriptions
  static TextStyle bodyLarge(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge;
    final fontSize = _responsiveFontSize(context, 16);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.5,
      letterSpacing: 0.5,
    );
  }

  /// Body medium text style - Secondary content, list descriptions
  static TextStyle bodyMedium(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium;
    final fontSize = _responsiveFontSize(context, 14);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.5,
      letterSpacing: 0.25,
    );
  }

  /// Body small text style - Supporting text, captions
  static TextStyle bodySmall(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall;
    final fontSize = _responsiveFontSize(context, 12);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurfaceVariant, // Use theme color
      height: 1.5,
      letterSpacing: 0.4,
    );
  }

  /// Label large text style - Button text, important labels
  static TextStyle labelLarge(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.labelLarge;
    final fontSize = _responsiveFontSize(context, 14);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface, // Use theme color
      height: 1.2,
      letterSpacing: 0.1,
    );
  }

  /// Label medium text style - Form labels, chips
  static TextStyle labelMedium(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.labelMedium;
    final fontSize = _responsiveFontSize(context, 12);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant, // Use theme color
      height: 1.3,
      letterSpacing: 0.5,
    );
  }

  /// Label small text style - Metadata, hints
  static TextStyle labelSmall(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.labelSmall;
    final fontSize = _responsiveFontSize(context, 11);
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant
          .withValues(alpha: 0.7), // Use theme color
      height: 1.3,
      letterSpacing: 0.5,
    );
  }

  // ==================== SEMANTIC TYPOGRAPHY HELPERS ====================

  /// Screen title - Used for main page titles
  static TextStyle screenTitle(BuildContext context) {
    return headlineLarge(context).copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );
  }

  /// Section header - Used for major section divisions
  static TextStyle sectionHeader(BuildContext context) {
    return headlineMedium(context).copyWith(
      fontWeight: FontWeight.w700,
    );
  }

  /// Card title - Used for card headers
  static TextStyle cardTitle(BuildContext context) {
    return titleLarge(context).copyWith(
      fontWeight: FontWeight.w600,
    );
  }

  /// List item title - Used for list item primary text
  static TextStyle listItemTitle(BuildContext context) {
    return titleMedium(context).copyWith(
      fontWeight: FontWeight.w600,
    );
  }

  /// List item subtitle - Used for list item secondary text
  static TextStyle listItemSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    return bodySmall(context).copyWith(
      color: theme.colorScheme.onSurfaceVariant, // Use theme color
    );
  }

  /// Button text - Used for button labels
  static TextStyle buttonText(BuildContext context) {
    return labelLarge(context).copyWith(
      fontWeight: FontWeight.w600,
    );
  }

  /// Input label - Used for form field labels
  static TextStyle inputLabel(BuildContext context) {
    final theme = Theme.of(context);
    return bodySmall(context).copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant, // Use theme color
    );
  }

  /// Error text - Used for error messages
  static TextStyle errorText(BuildContext context) {
    final theme = Theme.of(context);
    return bodySmall(context).copyWith(
      color: theme.colorScheme.error, // Use theme color
      fontWeight: FontWeight.w500,
    );
  }

  /// Success text - Used for success messages
  static TextStyle successText(BuildContext context) {
    final theme = Theme.of(context);
    return bodySmall(context).copyWith(
      color: theme.colorScheme.tertiary, // Use theme color (botsGreen)
      fontWeight: FontWeight.w500,
    );
  }

  /// Caption text - Used for image captions, metadata
  static TextStyle captionText(BuildContext context) {
    final theme = Theme.of(context);
    return bodySmall(context).copyWith(
      color: theme.colorScheme.onSurfaceVariant
          .withValues(alpha: 0.7), // Use theme color
      fontWeight: FontWeight.w400,
    );
  }

  // ==================== COLOR HELPERS (Theme-based) ====================
  // These methods use colorScheme as the source of truth for all colors
  // Use these instead of accessing colorScheme directly for consistency

  /// Get surface color from theme (botsWhite by default)
  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Get onSurface color from theme (text on surface)
  static Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Get onSurfaceVariant color from theme (secondary text)
  static Color onSurfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// Get primary color from theme (botsBlue)
  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Get onPrimary color from theme (text on primary)
  static Color onPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  /// Get secondary color from theme (botsYellow)
  static Color secondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  /// Get onSecondary color from theme (text on secondary)
  static Color onSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondary;
  }

  /// Get tertiary color from theme (botsGreen)
  static Color tertiary(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  /// Get onTertiary color from theme (text on tertiary)
  static Color onTertiary(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiary;
  }

  /// Get error color from theme
  static Color errorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  /// Get onError color from theme (text on error)
  static Color onError(BuildContext context) {
    return Theme.of(context).colorScheme.onError;
  }

  /// Get errorContainer color from theme
  static Color errorContainer(BuildContext context) {
    return Theme.of(context).colorScheme.errorContainer;
  }

  /// Get onErrorContainer color from theme
  static Color onErrorContainer(BuildContext context) {
    return Theme.of(context).colorScheme.onErrorContainer;
  }

  /// Get primaryContainer color from theme
  static Color primaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.primaryContainer;
  }

  /// Get onPrimaryContainer color from theme
  static Color onPrimaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimaryContainer;
  }

  /// Get secondaryContainer color from theme
  static Color secondaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.secondaryContainer;
  }

  /// Get onSecondaryContainer color from theme
  static Color onSecondaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondaryContainer;
  }

  /// Get tertiaryContainer color from theme
  static Color tertiaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.tertiaryContainer;
  }

  /// Get onTertiaryContainer color from theme
  static Color onTertiaryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiaryContainer;
  }

  /// Get surfaceContainerHighest color from theme
  static Color surfaceContainerHighest(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  /// Get outline color from theme
  static Color outline(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  /// Get outlineVariant color from theme
  static Color outlineVariant(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  /// Get background color from theme (deprecated: use surface instead)
  @Deprecated(
      'Use surface instead. This feature was deprecated after v3.18.0-0.1.pre')
  static Color background(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Get onBackground color from theme (deprecated: use onSurface instead)
  @Deprecated(
      'Use onSurface instead. This feature was deprecated after v3.18.0-0.1.pre')
  static Color onBackground(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Get scaffold background color from theme (botsNearlyWhite by default)
  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  // ==================== HELPER METHODS ====================

  /// Create a card decoration with modern surface treatment
  /// Company Dashboard Style: White cards with radiusM, elevation 0
  static BoxDecoration cardDecoration({
    Color? color,
    Gradient? gradient,
    List<BoxShadow>? shadows,
    double? radius,
    bool subtle = false,
  }) {
    return BoxDecoration(
      color: gradient == null
          ? (color ?? surfaceLight)
          : null, // Company Dashboard: botsWhite
      gradient: gradient,
      borderRadius: BorderRadius.circular(
          radius ?? radiusM), // Company Dashboard: radiusM
      // Company Dashboard: elevation 0, subtle shadow
      boxShadow: shadows ??
          (subtle
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  )
                ]),
      // Subtle border for modern look
      border: subtle
          ? Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            )
          : null,
    );
  }

  /// Create a button decoration with modern elevation
  static BoxDecoration buttonDecoration({
    Color? color,
    Gradient? gradient,
    double? radius,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: gradient == null ? (color ?? primaryBlue) : null,
      gradient: gradient ?? primaryGradient,
      borderRadius: BorderRadius.circular(radius ?? radiusM),
      boxShadow: elevated ? mediumShadow : null,
    );
  }

  /// Create a modern input decoration with enhanced styling
  /// Company Dashboard Style: Uses theme colors and nearlyWhite fill
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    bool filled = true,
    bool modern = true,
    BuildContext? context,
  }) {
    // Get theme if context provided, otherwise use defaults
    final theme = context != null ? Theme.of(context) : null;
    final colorScheme = theme?.colorScheme;

    final baseDecoration = InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: colorScheme?.primary ?? primaryBlue,
            )
          : null,
      suffixIcon: suffixIcon,
      filled: filled,
      // Company Dashboard: nearlyWhite fill
      fillColor: modern
          ? (colorScheme != null
              ? botsNearlyWhite
              : surfaceLight.withValues(alpha: 0.8))
          : (colorScheme != null ? botsNearlyWhite : surfaceLight),
      contentPadding: EdgeInsets.symmetric(
        horizontal: spaceM,
        vertical: modern ? spaceM * 1.2 : spaceM,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(radiusM), // Company Dashboard: radiusM
        borderSide: BorderSide(
          color: colorScheme?.outlineVariant ?? divider,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: colorScheme?.outlineVariant ?? divider.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: colorScheme?.primary ?? primaryBlue,
          width: 2, // Company Dashboard: 2px focus border
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: colorScheme?.error ?? error,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: colorScheme?.error ?? error,
          width: 1.5,
        ),
      ),
      // Modern enhancements with theme colors
      labelStyle: modern
          ? TextStyle(
              color: colorScheme?.onSurfaceVariant ?? botsTextSecondary,
              fontWeight: FontWeight.w500, // Company Dashboard: w500
            )
          : null,
      hintStyle: modern
          ? TextStyle(
              color: colorScheme?.onSurfaceVariant.withValues(alpha: 0.7) ??
                  botsTextHint,
              fontSize: 14,
            )
          : null,
      floatingLabelBehavior:
          modern ? FloatingLabelBehavior.always : FloatingLabelBehavior.auto,
    );

    return baseDecoration;
  }

  /// Create spacing widget
  static Widget verticalSpace(double height) => SizedBox(height: height);

  /// Create spacing widget
  static Widget horizontalSpace(double width) => SizedBox(width: width);

  // ==================== EDGE INSETS HELPERS ====================
  // Reusable padding/margin helpers to replace hardcoded EdgeInsets

  /// Padding all sides with XS spacing (4px)
  static EdgeInsets get paddingXS => const EdgeInsets.all(spaceXS);

  /// Padding all sides with S spacing (8px)
  static EdgeInsets get paddingS => const EdgeInsets.all(spaceS);

  /// Padding all sides with M spacing (16px)
  static EdgeInsets get paddingM => const EdgeInsets.all(spaceM);

  /// Padding all sides with L spacing (24px)
  static EdgeInsets get paddingL => const EdgeInsets.all(spaceL);

  /// Padding all sides with XL spacing (32px)
  static EdgeInsets get paddingXL => const EdgeInsets.all(spaceXL);

  /// Padding all sides with XXL spacing (48px)
  static EdgeInsets get paddingXXL => const EdgeInsets.all(spaceXXL);

  /// Symmetric horizontal padding
  static EdgeInsets paddingHorizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);

  /// Symmetric vertical padding
  static EdgeInsets paddingVertical(double value) =>
      EdgeInsets.symmetric(vertical: value);

  /// Symmetric padding (horizontal and vertical)
  static EdgeInsets paddingSymmetric({double? horizontal, double? vertical}) =>
      EdgeInsets.symmetric(
          horizontal: horizontal ?? 0, vertical: vertical ?? 0);

  /// Padding with specific values for each side
  static EdgeInsets paddingOnly({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) =>
      EdgeInsets.only(
        left: left ?? 0,
        top: top ?? 0,
        right: right ?? 0,
        bottom: bottom ?? 0,
      );

  /// Padding from LTRB (left, top, right, bottom)
  static EdgeInsets paddingFromLTRB(
          double left, double top, double right, double bottom) =>
      EdgeInsets.fromLTRB(left, top, right, bottom);

  /// Common padding patterns
  static EdgeInsets get paddingScreen =>
      const EdgeInsets.all(spaceL); // Standard screen padding
  static EdgeInsets get paddingCard =>
      const EdgeInsets.all(spaceM); // Standard card padding
  static EdgeInsets get paddingDialog =>
      const EdgeInsets.all(spaceXL); // Standard dialog padding

  // ==================== BORDER RADIUS HELPERS ====================
  // Reusable BorderRadius helpers to replace hardcoded values

  /// BorderRadius with S radius (8px)
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);

  /// BorderRadius with M radius (12px)
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);

  /// BorderRadius with L radius (16px)
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);

  /// BorderRadius with XL radius (24px)
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);

  /// BorderRadius circular (fully rounded)
  static BorderRadius get borderRadiusCircular =>
      BorderRadius.circular(radiusCircular);

  /// BorderRadius with custom radius
  static BorderRadius borderRadius(double radius) =>
      BorderRadius.circular(radius);

  /// BorderRadius only (specific corners)
  static BorderRadius borderRadiusOnly({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) =>
      BorderRadius.only(
        topLeft: Radius.circular(topLeft ?? 0),
        topRight: Radius.circular(topRight ?? 0),
        bottomLeft: Radius.circular(bottomLeft ?? 0),
        bottomRight: Radius.circular(bottomRight ?? 0),
      );

  /// Create a modern divider with subtle styling
  static Widget dividerWidget({
    double? height,
    double? thickness,
    double? indent,
    double? endIndent,
    bool subtle = true,
  }) {
    return Divider(
      height: height ?? spaceL,
      thickness: thickness ?? (subtle ? 0.5 : 1.0),
      indent: indent,
      endIndent: endIndent,
      color: subtle ? divider.withValues(alpha: 0.5) : divider,
    );
  }

  // ==================== 2025 ANIMATION HELPERS ====================

  /// Create a slide-up fade animation (2025 pattern from intro animations)
  static Widget slideUpFadeIn({
    required Widget child,
    required Animation<double> animation,
    double slideDistance = 30.0,
  }) {
    return FadeTransition(
      opacity: animation,
      child: Transform.translate(
        offset: Offset(0.0, slideDistance * (1.0 - animation.value)),
        child: child,
      ),
    );
  }

  /// Standard stagger delay for list items (2025 pattern)
  static Duration staggerDelay(int index, {int baseMs = 50}) {
    return Duration(milliseconds: baseMs * index);
  }

  /// Get interval for staggered animations
  static Animation<double> staggerInterval(
    AnimationController controller,
    int index,
    int totalItems, {
    double overlapFactor = 0.4,
  }) {
    final double start = (index / totalItems) * overlapFactor;
    final double end = start + (1.0 - overlapFactor);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
          curve: animationFastOutSlowIn),
    );
  }

  // ==================== 2025 CARD VARIANTS ====================

  /// Info card decoration (2025 pattern: tinted background)
  static BoxDecoration infoCardDecoration({
    required Color accentColor,
    double opacity = 0.1,
    double radius = radiusL,
  }) {
    return BoxDecoration(
      color: accentColor.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Action card decoration (2025 pattern: gradient with shadow)
  static BoxDecoration actionCardDecoration({
    required Gradient gradient,
    double radius = radiusL,
    bool elevated = true,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: elevated ? mediumShadow : null,
    );
  }

  /// Feature card with icon accent (2025 pattern)
  static Widget featureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(spaceL),
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(radiusL),
          boxShadow: lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(spaceS),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(radiusM),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: spaceM),
            Text(
              title,
              style: titleMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: spaceXS),
              Text(
                subtitle,
                style: bodySmall(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Progress indicator card (2025 pattern: circular progress with stats)
  static Widget progressCard({
    required BuildContext context,
    required String title,
    required double progress,
    required String value,
    required Color accentColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(spaceL),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(radiusL),
        boxShadow: lightShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: labelMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: titleLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: bodySmall(context).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: labelSmall(context).copyWith(
                      color: accentColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MODERN COMPONENT HELPERS ====================

  /// Create a modern chip with consistent styling
  static Widget modernChip({
    required String label,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return FilterChip(
      label: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Text(
            label,
            style: TextStyle(
              color: textColor ??
                  (selected ? Colors.white : theme.colorScheme.onSurface),
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
      avatar: icon != null ? Icon(icon, size: 16) : null,
      selected: selected,
      onSelected: onTap != null ? (selected) => onTap() : null,
      backgroundColor: backgroundColor ?? surfaceLight,
      selectedColor: primaryBlue,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
    );
  }

  /// Create a modern metric card for dashboards
  static Widget metricCard({
    required BuildContext context,
    required String title,
    required String value,
    IconData? icon,
    Color? accentColor,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final effectiveAccentColor = accentColor ?? primaryBlue;

    return modernCard(
      context: context,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(radiusS),
                  ),
                  child: Icon(icon, color: effectiveAccentColor, size: 20),
                ),
                horizontalSpace(0.75),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: titleLarge(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: effectiveAccentColor,
                      ),
                    ),
                    Text(
                      title,
                      style: bodySmall(context).copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            verticalSpace(0.5),
            Text(
              subtitle,
              style: bodySmall(context).copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Modern card helper (convenience method)
  static Widget modernCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double? elevation,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Gradient? gradient,
    VoidCallback? onTap,
    bool showShadow = true,
    bool subtle = false,
  }) {
    return Container(
      decoration: cardDecoration(
        color: backgroundColor,
        gradient: gradient,
        radius: borderRadius?.topLeft.x ?? radiusM,
        subtle: subtle,
        shadows: showShadow
            ? (elevation != null && elevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: elevation * 2,
                      offset: Offset(0, elevation),
                    )
                  ]
                : lightShadow)
            : null,
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: borderRadius ?? BorderRadius.circular(radiusM),
              child: child,
            )
          : child,
    );
  }

  // ==================== 2025 VIVID CARDS (Frame-1 Inspired) ====================

  /// Hero card with BOTS brand gradient (Frame-1 style, BOTS colors)
  /// Used for balance cards, welcome headers, etc.
  /// Default: Blue to Green gradient (balanced color usage)
  static Widget heroCard({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    Gradient? gradient,
    EdgeInsets? padding,
    VoidCallback? onTap,
    Color? primaryColor, // Optional: override primary color
    BorderRadius? borderRadius, // Optional: override border radius
  }) {
    final effectivePrimary = primaryColor ?? heroPrimary; // Default: Blue
    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [effectivePrimary, heroSecondary], // Blue to Green (balanced)
        );

    return Container(
      padding: padding ?? const EdgeInsets.all(spaceL),
      decoration: BoxDecoration(
        gradient: backgroundColor == null ? effectiveGradient : null,
        color: backgroundColor,
        borderRadius: borderRadius ??
            BorderRadius.zero, // No rounding by default - square corners
        boxShadow: coloredShadow(effectivePrimary), // Balanced shadow color
      ),
      child:
          onTap != null ? GestureDetector(onTap: onTap, child: child) : child,
    );
  }

  /// Vivid category card (Frame-1 style - BOTS brand colored tiles)
  /// Used for exam cards, course cards, etc.
  static Widget vividCategoryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    // Ensure color is a BOTS brand color or use default
    final effectiveColor = color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(spaceM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              effectiveColor,
              effectiveColor.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(radiusL),
          boxShadow: coloredShadow(effectiveColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon with white circle background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const Spacer(),
            // Text content
            Text(
              title,
              style: titleMedium(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: bodySmall(context).copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Circular icon with colored background (Frame-1 style)
  static Widget circularIcon({
    required IconData icon,
    required Color color,
    double size = 44,
    double iconSize = 22,
    bool filled = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: filled ? Colors.white : color,
        size: iconSize,
      ),
    );
  }

  /// Portfolio item row (Frame-1 style - horizontal scrolling items)
  static Widget portfolioItem({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(spaceM),
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(radiusM),
          border: Border.all(color: botsBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            circularIcon(icon: icon, color: iconColor),
            const SizedBox(height: spaceS),
            Text(
              title,
              style: labelMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: titleMedium(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: labelSmall(context).copyWith(
                  color: iconColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Clean list item (Frame-1 style - crypto list items)
  static Widget listItemCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: spaceM,
          vertical: spaceM,
        ),
        decoration: BoxDecoration(
          color: cardSurface,
          border: Border(
            bottom: BorderSide(color: botsDivider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: titleSmall(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: bodySmall(context).copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
