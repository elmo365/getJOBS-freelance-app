import 'package:flutter/material.dart';
import 'package:freelance_app/models/hint_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';

/// Reusable hint banner widget
/// Shows contextual hints to help users discover features
class HintBanner extends StatefulWidget {
  final HintModel hint;
  final VoidCallback? onDismiss;
  final bool showDismissButton;

  const HintBanner({
    super.key,
    required this.hint,
    this.onDismiss,
    this.showDismissButton = true,
  });

  @override
  State<HintBanner> createState() => _HintBannerState();
}

class _HintBannerState extends State<HintBanner> {
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss if duration is set
    if (widget.hint.autoDismissDuration != null) {
      Future.delayed(widget.hint.autoDismissDuration!, () {
        if (mounted && !_isDismissed) {
          _dismiss();
        }
      });
    }
  }

  void _dismiss() {
    setState(() => _isDismissed = true);
    widget.onDismiss?.call();
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use light backgrounds with good opacity for contrast
    switch (widget.hint.type) {
      case HintType.info:
        return colorScheme.primaryContainer.withValues(alpha: 0.9); // Light blue background
      case HintType.tip:
        return AppDesignSystem.brandYellow.withValues(alpha: 0.2); // Light yellow
      case HintType.feature:
        return colorScheme.tertiaryContainer.withValues(alpha: 0.9); // Light green
      case HintType.monetization:
        return botsGreen.withValues(alpha: 0.2); // Light green tint
      case HintType.warning:
        return colorScheme.errorContainer.withValues(alpha: 0.9); // Light red
      case HintType.ai:
        return Colors.purple.withValues(alpha: 0.15); // Light purple
    }
  }

  Color _getTextColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Ensure dark text on light backgrounds for readability
    switch (widget.hint.type) {
      case HintType.info:
        return colorScheme.onPrimaryContainer; // Dark text on light blue
      case HintType.tip:
        return colorScheme.onSurface; // Dark text on light yellow
      case HintType.feature:
        return colorScheme.onTertiaryContainer; // Dark text on light green
      case HintType.monetization:
        return colorScheme.onSurface; // Dark text on light green
      case HintType.warning:
        return colorScheme.onErrorContainer; // Dark text on light red
      case HintType.ai:
        return colorScheme.onSurface; // Dark text on light purple
    }
  }

  Color _getIconColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.hint.type) {
      case HintType.info:
        return colorScheme.primary;
      case HintType.tip:
        return Color.alphaBlend(
          AppDesignSystem.brandYellow,
          colorScheme.onSurface,
        ); // Blend for contrast
      case HintType.feature:
        return colorScheme.tertiary;
      case HintType.monetization:
        return Color.alphaBlend(
          botsGreen,
          colorScheme.onSurface,
        ); // Blend for contrast
      case HintType.warning:
        return colorScheme.error;
      case HintType.ai:
        return Colors.purple.shade700;
    }
  }

  IconData _getIcon() {
    switch (widget.hint.type) {
      case HintType.info:
        return Icons.info_outline;
      case HintType.tip:
        return Icons.lightbulb_outline;
      case HintType.feature:
        return Icons.auto_awesome_outlined;
      case HintType.monetization:
        return Icons.account_balance_wallet_outlined;
      case HintType.warning:
        return Icons.warning_outlined;
      case HintType.ai:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        // Fit width to parent but constrain height to content
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 300), // Prevent excessive height
        margin: AppDesignSystem.paddingSymmetric(
          horizontal: AppDesignSystem.spaceM,
          vertical: AppDesignSystem.spaceS,
        ),
        padding: AppDesignSystem.paddingM,
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: AppDesignSystem.borderRadiusM,
          border: Border.all(
            color: _getIconColor(context).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getIcon(),
            color: _getIconColor(context),
            size: 24,
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Don't expand vertically
              children: [
                if (widget.hint.title.isNotEmpty) ...[
                  Text(
                    widget.hint.title,
                    style: AppDesignSystem.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: _getTextColor(context), // Use type-specific text color
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                ],
                Text(
                  widget.hint.message,
                  style: AppDesignSystem.bodyMedium(context).copyWith(
                    color: _getTextColor(context), // Use type-specific text color for contrast
                    height: 1.5,
                    fontWeight: FontWeight.w600, // Increased weight for readability
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.showDismissButton) ...[
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
            Semantics(
              label: 'Dismiss hint',
              button: true,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: _dismiss,
                tooltip: 'Dismiss hint',
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

