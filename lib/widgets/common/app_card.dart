import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';

/// Modern Card System for 2025 UI Standards
/// Enhanced with surface blending, elevation hierarchies, and micro-interactions
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final bool showGradientBorder;
  final bool interactive;
  final SurfaceVariant variant;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.gradient,
    this.showGradientBorder = false,
    this.interactive = true,
    this.variant = SurfaceVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final BorderRadius effectiveRadius =
        borderRadius ?? BorderRadius.circular(_getRadiusForVariant(variant));

    final shape = RoundedRectangleBorder(
      borderRadius: effectiveRadius,
      side: showGradientBorder
          ? BorderSide(color: colorScheme.outlineVariant)
          : BorderSide.none,
    );

    // Enhanced surface colors based on variant
    final Color effectiveBackgroundColor = _getBackgroundColorForVariant(
      variant,
      backgroundColor,
      colorScheme,
    );

    final double effectiveElevation =
        _getElevationForVariant(variant, elevation);

    final cardChild = Container(
      padding: padding ?? _getPaddingForVariant(variant),
      decoration: gradient != null
          ? BoxDecoration(
              gradient: gradient,
              borderRadius: effectiveRadius,
            )
          : null,
      child: child,
    );

    Widget card = Card(
      margin: margin ?? _getMarginForVariant(variant),
      elevation: effectiveElevation,
      color: gradient == null ? effectiveBackgroundColor : null,
      shape: shape,
      shadowColor: _getShadowColorForVariant(variant, colorScheme.shadow),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? cardChild
          : InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius,
              splashColor: colorScheme.primary.withValues(alpha: 0.1),
              highlightColor: colorScheme.primary.withValues(alpha: 0.05),
              child: cardChild,
            ),
    );

    // Apply micro-interactions if interactive and has onTap
    if (interactive && onTap != null) {
      card = MicroInteractions.scaleCard(
        child: card,
        onTap: onTap,
        enabled: true,
      );
    }

    return card;
  }

  double _getRadiusForVariant(SurfaceVariant variant) {
    switch (variant) {
      case SurfaceVariant.flat:
        return AppDesignSystem.radiusS;
      case SurfaceVariant.elevated:
        return AppDesignSystem.radiusL;
      case SurfaceVariant.glass:
        return AppDesignSystem.radiusXL;
      case SurfaceVariant.standard:
        return AppDesignSystem.radiusM;
    }
  }

  EdgeInsets _getPaddingForVariant(SurfaceVariant variant) {
    switch (variant) {
      case SurfaceVariant.flat:
        return AppDesignSystem.paddingS;
      case SurfaceVariant.elevated:
        return AppDesignSystem.paddingM;
      case SurfaceVariant.glass:
        return AppDesignSystem.paddingL;
      case SurfaceVariant.standard:
        return AppDesignSystem.paddingM;
    }
  }

  EdgeInsets _getMarginForVariant(SurfaceVariant variant) {
    switch (variant) {
      case SurfaceVariant.flat:
        return AppDesignSystem.paddingVertical(AppDesignSystem.spaceXS);
      case SurfaceVariant.elevated:
        return AppDesignSystem.paddingVertical(AppDesignSystem.spaceS);
      case SurfaceVariant.glass:
        return AppDesignSystem.paddingVertical(AppDesignSystem.spaceS);
      case SurfaceVariant.standard:
        return EdgeInsets.zero;
    }
  }

  Color _getBackgroundColorForVariant(
    SurfaceVariant variant,
    Color? backgroundColor,
    ColorScheme colorScheme,
  ) {
    if (backgroundColor != null) return backgroundColor;

    switch (variant) {
      case SurfaceVariant.flat:
        return colorScheme.surfaceContainerLowest;
      case SurfaceVariant.elevated:
        return colorScheme.surfaceContainerHigh;
      case SurfaceVariant.glass:
        return colorScheme.surfaceContainer.withValues(alpha: 0.8);
      case SurfaceVariant.standard:
        return colorScheme.surfaceContainerLow;
    }
  }

  double _getElevationForVariant(SurfaceVariant variant, double? elevation) {
    if (elevation != null) return elevation;

    switch (variant) {
      case SurfaceVariant.flat:
        return 0;
      case SurfaceVariant.elevated:
        return 8.0; // Increased from elevationHigh for better pop
      case SurfaceVariant.glass:
        return 4.0; // Increased from elevationMedium
      case SurfaceVariant.standard:
        return 4.0; // Increased from elevationLow for better visibility
    }
  }

  Color _getShadowColorForVariant(SurfaceVariant variant, Color baseShadow) {
    switch (variant) {
      case SurfaceVariant.flat:
        return Colors.transparent;
      case SurfaceVariant.elevated:
        return baseShadow.withValues(alpha: 0.25); // Increased from 0.15 for stronger shadow
      case SurfaceVariant.glass:
        return baseShadow.withValues(alpha: 0.15); // Increased from 0.08
      case SurfaceVariant.standard:
        return baseShadow.withValues(alpha: 0.20); // Increased from 0.10 for better contrast
    }
  }
}

/// Surface variants for different card elevations and treatments
enum SurfaceVariant {
  /// Flat surface with no elevation (minimal)
  flat,

  /// Standard card with subtle elevation
  standard,

  /// Elevated card with higher shadow
  elevated,

  /// Glass-morphism effect with transparency
  glass,
}

/// Modern Action Card - Specialized card for interactive actions
class ActionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final String? title;
  final String? subtitle;
  final Color? accentColor;
  final bool enabled;

  const ActionCard({
    super.key,
    required this.child,
    required this.onTap,
    this.leadingIcon,
    this.title,
    this.subtitle,
    this.accentColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveAccentColor = accentColor ?? colorScheme.primary;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: AppCard(
        variant: SurfaceVariant.elevated,
        onTap: enabled ? onTap : null,
        interactive: true,
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                padding: AppDesignSystem.paddingS,
                decoration: BoxDecoration(
                  color: effectiveAccentColor.withValues(alpha: 0.1),
                  borderRadius: AppDesignSystem.borderRadiusM,
                ),
                child: Icon(
                  leadingIcon,
                  color: effectiveAccentColor,
                  size: 24,
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: AppDesignSystem.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  ],
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: AppDesignSystem.bodySmall(context).copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (title == null && subtitle == null) child,
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern Metric Card - For displaying KPIs and metrics
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? change;
  final bool isPositive;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.accentColor,
    this.change,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveAccentColor = accentColor ?? colorScheme.primary;

    return AppCard(
      variant: SurfaceVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: AppDesignSystem.paddingS,
                  decoration: BoxDecoration(
                    color: effectiveAccentColor.withValues(alpha: 0.1),
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Icon(
                    icon,
                    color: effectiveAccentColor,
                    size: 20,
                  ),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            value,
            style: AppDesignSystem.headlineSmall(context).copyWith(
              fontWeight: FontWeight.w800,
              color: effectiveAccentColor,
            ),
          ),
          if (change != null) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? colorScheme.tertiary : colorScheme.error,
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                Text(
                  change!,
                  style: AppDesignSystem.labelSmall(context).copyWith(
                    color:
                        isPositive ? colorScheme.tertiary : colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Modern Content Card - For displaying rich content with media
class ContentCard extends StatelessWidget {
  final Widget? media;
  final String? title;
  final String? subtitle;
  final String? description;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final bool compact;
  final BorderRadius? borderRadius;

  const ContentCard({
    super.key,
    this.media,
    this.title,
    this.subtitle,
    this.description,
    this.actions,
    this.onTap,
    this.compact = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: SurfaceVariant.standard,
      borderRadius: borderRadius,
      onTap: onTap,
      interactive: onTap != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (media != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDesignSystem.radiusM),
              ),
              child: media,
            ),
            if (!compact)
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: compact
                  ? AppDesignSystem.titleSmall(context)
                      .copyWith(fontWeight: FontWeight.w600)
                  : AppDesignSystem.titleLarge(context)
                      .copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null || description != null)
              AppDesignSystem.verticalSpace(
                  compact ? AppDesignSystem.spaceXS : AppDesignSystem.spaceS),
          ],
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: AppDesignSystem.bodyMedium(context).copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (description != null)
              AppDesignSystem.verticalSpace(
                  compact ? AppDesignSystem.spaceXS : AppDesignSystem.spaceS),
          ],
          if (description != null) ...[
            Text(
              description!,
              style: AppDesignSystem.bodySmall(context).copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            AppDesignSystem.verticalSpace(
                compact ? AppDesignSystem.spaceS : AppDesignSystem.spaceM),
            Row(
              children: actions!.map((action) {
                return Padding(
                  padding: AppDesignSystem.paddingOnly(
                      right: AppDesignSystem.spaceS),
                  child: action,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
