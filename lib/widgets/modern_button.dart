import 'package:flutter/material.dart';
import '../utils/app_design_system.dart';

/// Modern button with gradient, loading state, and animations
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Gradient? gradient;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final bool outlined;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.outlined = false,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDesignSystem.animationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 56,
          decoration: widget.outlined
              ? BoxDecoration(
                  border: Border.all(
                    color: widget.color ?? AppDesignSystem.primaryBlue,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? AppDesignSystem.radiusM,
                  ),
                )
              : BoxDecoration(
                  gradient: isEnabled
                      ? (widget.gradient ?? AppDesignSystem.primaryGradient)
                      : null,
                  color: !isEnabled
                      ? AppDesignSystem.textHint
                      : (widget.gradient == null ? (widget.color ?? AppDesignSystem.primaryBlue) : null),
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? AppDesignSystem.radiusM,
                  ),
                  boxShadow: isEnabled ? AppDesignSystem.mediumShadow : null,
                ),
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.textColor ?? Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: widget.outlined
                                ? (widget.color ?? AppDesignSystem.primaryBlue)
                                : (widget.textColor ?? Colors.white),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: widget.outlined
                                ? (widget.color ?? AppDesignSystem.primaryBlue)
                                : (widget.textColor ?? Colors.white),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern text button
class ModernTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const ModernTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppDesignSystem.primaryBlue,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spaceM,
          vertical: AppDesignSystem.spaceS,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? AppDesignSystem.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

