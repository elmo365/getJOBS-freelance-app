import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Centralized AppBar component that uses AppDesignSystem
/// Ensures consistent styling and proper contrast across the app
/// All color changes are centralized in AppDesignSystem
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final AppBarVariant variant;
  final double? elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.variant = AppBarVariant.standard,
    this.elevation,
    this.centerTitle = false,
    this.bottom,
  }) : assert(title == null || titleWidget == null, 'Cannot provide both title and titleWidget');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get colors based on variant
    final backgroundColor = _getBackgroundColor(colorScheme);
    final foregroundColor = _getForegroundColor(colorScheme, backgroundColor);
    final effectiveElevation = elevation ?? _getDefaultElevation();

    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: effectiveElevation,
      scrolledUnderElevation: effectiveElevation,
      centerTitle: centerTitle,
      bottom: bottom,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: foregroundColor),
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// Get background color based on variant
  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case AppBarVariant.standard:
        // Default: white/light surface
        return colorScheme.surface;
      case AppBarVariant.primary:
        // Primary brand color (blue) with white text
        return AppDesignSystem.brandBlue;
      case AppBarVariant.secondary:
        // Secondary brand color (yellow) with black text
        return AppDesignSystem.brandYellow;
      case AppBarVariant.tertiary:
        // Tertiary brand color (green) with white text
        return AppDesignSystem.brandGreen;
      case AppBarVariant.error:
        // Error color (red) with white text
        return colorScheme.error;
      case AppBarVariant.surface:
        // Surface color
        return colorScheme.surface;
    }
  }

  /// Get foreground color based on background brightness
  /// Ensures proper contrast (WCAG AA compliant)
  Color _getForegroundColor(ColorScheme colorScheme, Color backgroundColor) {
    switch (variant) {
      case AppBarVariant.standard:
        // Standard uses theme's onSurface
        return colorScheme.onSurface;
      case AppBarVariant.primary:
        // Primary (blue) always uses white
        return AppDesignSystem.brandWhite;
      case AppBarVariant.secondary:
        // Secondary (yellow) uses black for contrast
        return AppDesignSystem.brandBlack;
      case AppBarVariant.tertiary:
        // Tertiary (green) always uses white
        return AppDesignSystem.brandWhite;
      case AppBarVariant.error:
        // Error always uses white
        return colorScheme.onError;
      case AppBarVariant.surface:
        // Surface uses onSurface
        return colorScheme.onSurface;
    }
  }

  /// Get default elevation based on variant
  double _getDefaultElevation() {
    switch (variant) {
      case AppBarVariant.standard:
      case AppBarVariant.surface:
        return 0;
      case AppBarVariant.primary:
      case AppBarVariant.secondary:
      case AppBarVariant.tertiary:
      case AppBarVariant.error:
        return 0; // Flat design, no elevation
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// AppBar variant types
enum AppBarVariant {
  /// Standard AppBar - white/light background with dark text
  standard,
  
  /// Primary AppBar - blue background with white text
  primary,
  
  /// Secondary AppBar - yellow background with black text
  secondary,
  
  /// Tertiary AppBar - green background with white text
  tertiary,
  
  /// Error AppBar - red background with white text
  error,
  
  /// Surface AppBar - uses theme surface color
  surface,
}

