import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';

/// Fully standardized button component for the entire app
/// 
/// Design Standards:
/// - Minimum 48x48px touch target (WCAG 2.1 Level AAA)
/// - High contrast ratios: 4.5:1 for normal text, 7:1 for large
/// - Consistent padding: 16-24px horizontal, 12-16px vertical
/// - 12px border radius for modern look
/// - Proper loading and disabled states
/// - Smooth animations and hover effects
/// 
/// Usage:
/// ```dart
/// StandardButton(
///   label: 'Save Changes',
///   onPressed: () => save(),
///   type: StandardButtonType.primary,
///   icon: Icons.save,
/// )
/// ```
class StandardButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final StandardButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const StandardButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = StandardButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.width,
    this.height,
    this.padding,
    this.fontSize,
  });

  @override
  State<StandardButton> createState() => _StandardButtonState();
}

class _StandardButtonState extends State<StandardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styleConfig = _getStyleConfig();
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    
    // Ensure accessibility minimum dimensions
    final double buttonHeight = widget.height ?? 52.0; // Min 48px + safe area
    final double? buttonWidth = widget.fullWidth ? double.infinity : widget.width;

    return Semantics(
      label: widget.label,
      button: true,
      enabled: !isDisabled,
      child: GestureDetector(
        onTapDown: (_) => !isDisabled ? _controller.forward() : null,
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: _buildButton(styleConfig, isDisabled),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(_ButtonStyleConfig config, bool isDisabled) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case StandardButtonType.outlined:
        return OutlinedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: config.foregroundColor,
            side: BorderSide(
              color: isDisabled 
                  ? colorScheme.onSurface.withValues(alpha: 0.28)
                  : config.borderColor ?? config.backgroundColor,
              width: 2,
            ),
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            elevation: 0,
          ),
          child: _buildButtonContent(config, isDisabled),
        );
      
      case StandardButtonType.text:
        return TextButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: config.foregroundColor,
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
          ),
          child: _buildButtonContent(config, isDisabled),
        );
      
      default: // Elevated (filled) buttons
        return ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: config.backgroundColor,
            foregroundColor: config.foregroundColor,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.45),
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: _buildButtonContent(config, isDisabled),
        );
    }
  }

  Widget _buildButtonContent(_ButtonStyleConfig config, bool isDisabled) {
    if (widget.isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.type == StandardButtonType.outlined || widget.type == StandardButtonType.text
                ? config.backgroundColor 
                : config.foregroundColor,
          ),
        ),
      );
    }

    final textWidget = Text(
      widget.label,
      style: TextStyle(
        fontSize: widget.fontSize ?? 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 10),
          Flexible(child: textWidget),
        ],
      );
    }

    return textWidget;
  }

  _ButtonStyleConfig _getStyleConfig() {
    final colorScheme = Theme.of(context).colorScheme;

    switch (widget.type) {
      case StandardButtonType.primary:
        return _ButtonStyleConfig(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        );
      
      case StandardButtonType.secondary:
        return _ButtonStyleConfig(
          // Tonal secondary to avoid harsh, blocky buttons.
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
        );
      
      case StandardButtonType.success:
        return _ButtonStyleConfig(
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
        );
      
      case StandardButtonType.danger:
        return _ButtonStyleConfig(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        );
      
      case StandardButtonType.outlined:
        return _ButtonStyleConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.primary,
          borderColor: colorScheme.outline,
        );
      
      case StandardButtonType.text:
        return _ButtonStyleConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.primary,
        );
    }
  }
}

/// Button type variants for different use cases
enum StandardButtonType {
  /// Primary action button (Blue, high emphasis)
  primary,
  
  /// Secondary action button (Yellow, medium emphasis)
  secondary,
  
  /// Success/confirmation button (Green)
  success,
  
  /// Danger/destructive button (Red)
  danger,
  
  /// Outlined button (transparent bg, colored border)
  outlined,
  
  /// Text button (transparent, minimal emphasis)
  text,
}

/// Internal style configuration
class _ButtonStyleConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  _ButtonStyleConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });
}
