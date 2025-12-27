import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Modern Responsive Layout System for 2025 UI Standards
/// Provides unified grid, responsive containers, and safe area handling
class AppLayout {
  // ==================== RESPONSIVE BREAKPOINTS ====================

  /// Mobile breakpoint (max width)
  static const double mobileMaxWidth = 600;

  /// Tablet breakpoint (max width)
  static const double tabletMaxWidth = 1200;

  /// Desktop breakpoint (min width)
  static const double desktopMinWidth = 1200;

  // ==================== RESPONSIVE UTILITIES ====================

  /// Check if current context is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Check if current context is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  /// Check if current context is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }

  /// Get responsive horizontal padding based on screen size
  static double responsiveHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return AppDesignSystem.spaceXXL;
    if (isTablet(context)) return AppDesignSystem.spaceXL;
    return AppDesignSystem.spaceL;
  }

  /// Get responsive max content width
  static double? responsiveMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 800;
    return null; // Full width on mobile
  }

  // ==================== MODERN PAGE LAYOUTS ====================

  /// Responsive page container with proper safe areas and max width constraints
  static Widget responsivePage({
    required BuildContext context,
    required Widget child,
    bool scrollable = true,
    EdgeInsets? padding,
    Color? backgroundColor,
    bool centerContent = false,
  }) {
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: responsiveHorizontalPadding(context),
          vertical: AppDesignSystem.spaceL,
        );

    Widget content = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: responsiveMaxWidth(context) ?? double.infinity,
      ),
      padding: effectivePadding,
      color: backgroundColor,
      child: centerContent ? Center(child: child) : child,
    );

    // Only wrap in SingleChildScrollView if scrollable is true
    // This prevents layout conflicts with Expanded/Flexible widgets
    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return SafeArea(
      child: content,
    );
  }

  /// Modern screen scaffold with consistent app bar and responsive body
  static Widget screenScaffold({
    required BuildContext context,
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
    Color? backgroundColor,
    bool scrollable = true,
    EdgeInsets? padding,
    bool resizeToAvoidBottomInset = true,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: responsivePage(
        context: context,
        child: body,
        scrollable: scrollable,
        padding: padding,
        backgroundColor: backgroundColor,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }

  // ==================== MODERN GRID SYSTEMS ====================

  /// Responsive grid with modern spacing and aspect ratios
  static SliverGridDelegate responsiveGrid({
    required BuildContext context,
    double minChildWidth = 280,
    double maxCrossAxisExtent = 400,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 16,
    double mainAxisSpacing = 16,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = responsiveHorizontalPadding(context) * 2;
    final availableWidth = screenWidth - padding;

    final crossAxisCount = (availableWidth / (minChildWidth + crossAxisSpacing))
        .floor()
        .clamp(1, 4);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  /// Modern list view with proper spacing and performance
  static Widget modernListView({
    required List<Widget> children,
    EdgeInsets? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    bool addSeparators = false,
    Widget? separator,
  }) {
    if (!addSeparators) {
      return ListView(
        padding: padding ?? EdgeInsets.zero,
        physics: physics ?? const BouncingScrollPhysics(),
        shrinkWrap: shrinkWrap,
        children: children,
      );
    }

    final effectiveSeparator = separator ??
        Divider(
          height: AppDesignSystem.spaceM,
          thickness: 0.5,
          color: AppDesignSystem.divider,
        );

    return ListView.separated(
      padding: padding ?? EdgeInsets.zero,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      separatorBuilder: (context, index) => effectiveSeparator,
      itemBuilder: (context, index) => children[index],
    );
  }

  // ==================== MODERN SPACING UTILITIES ====================

  /// Vertical spacing using design system
  static Widget verticalSpace(double multiplier) {
    return SizedBox(height: AppDesignSystem.spaceM * multiplier);
  }

  /// Horizontal spacing using design system
  static Widget horizontalSpace(double multiplier) {
    return SizedBox(width: AppDesignSystem.spaceM * multiplier);
  }

  /// Responsive spacing that scales with screen size
  static double responsiveSpace(BuildContext context, double baseSpace) {
    if (isDesktop(context)) return baseSpace * 1.2;
    if (isTablet(context)) return baseSpace * 1.1;
    return baseSpace;
  }

  // ==================== MODERN CARD LAYOUTS ====================

  /// Modern card container with responsive padding and elevation
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
  }) {
    final effectivePadding = padding ??
        EdgeInsets.all(responsiveSpace(context, AppDesignSystem.spaceM));

    final effectiveElevation =
        elevation ?? (showShadow ? AppDesignSystem.elevationLow : 0.0);

    final card = Card(
      elevation: effectiveElevation,
      color: gradient == null ? backgroundColor : null,
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDesignSystem.radiusM),
      ),
      shadowColor: showShadow
          ? Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1)
          : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: gradient != null
            ? BoxDecoration(
                gradient: gradient,
                borderRadius: borderRadius ??
                    BorderRadius.circular(AppDesignSystem.radiusM),
              )
            : null,
        padding: effectivePadding,
        child: child,
      ),
    );

    return onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius:
                borderRadius ?? BorderRadius.circular(AppDesignSystem.radiusM),
            child: card,
          )
        : card;
  }

  // ==================== MODERN SECTION LAYOUTS ====================

  /// Modern section with title and content
  static Widget section({
    required BuildContext context,
    required String title,
    required Widget content,
    Widget? trailing,
    EdgeInsets? padding,
    bool showDivider = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: responsiveHorizontalPadding(context),
              ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppDesignSystem.titleLarge(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        verticalSpace(0.5),
        content,
        if (showDivider) ...[
          verticalSpace(1),
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppDesignSystem.divider,
          ),
        ],
      ],
    );
  }

  // ==================== LEGACY COMPATIBILITY ====================

  /// Legacy padding constant for backward compatibility
  @Deprecated('Use AppDesignSystem.spaceM instead')
  static const double padding = AppDesignSystem.spaceM;

  /// Legacy radius constant for backward compatibility
  @Deprecated('Use AppDesignSystem.radiusM instead')
  static const double radius = AppDesignSystem.radiusM;

  /// Legacy elevation constant for backward compatibility
  @Deprecated('Use AppDesignSystem.elevationLow instead')
  static const double elevation = AppDesignSystem.elevationLow;

  static const double curvedNavBarHeight = 50.0;

  static const double iconSmall = 20.0;
  static const double iconMedium = 30.0;
  static const double iconLarge = 35.0;
}
