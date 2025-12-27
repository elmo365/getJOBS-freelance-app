import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';

/// Reusable button component with consistent styling and microinteractions
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final content = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(buttonStyle.textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: buttonStyle.textColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: buttonStyle.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          );

    return Semantics(
      label: widget.label,
      button: true,
      enabled: widget.onPressed != null && !widget.isLoading,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _handleTapDown : null,
        onTapUp: widget.onPressed != null ? _handleTapUp : null,
        onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.width,
            height: widget.height ?? 50,
            decoration: BoxDecoration(
              color: buttonStyle.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.onPressed != null
                  ? [
                      BoxShadow(
                        color:
                            buttonStyle.backgroundColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }

  _ButtonStyle _getButtonStyle() {
    switch (widget.type) {
      case ButtonType.primary:
        return _ButtonStyle(
          backgroundColor: botsBlue,
          textColor: botsWhite,
        );
      case ButtonType.secondary:
        return _ButtonStyle(
          backgroundColor: botsYellow,
          textColor: botsBlack,
        );
      case ButtonType.success:
        return _ButtonStyle(
          backgroundColor: botsGreen,
          textColor: botsWhite,
        );
      case ButtonType.outline:
        return _ButtonStyle(
          backgroundColor: Colors.transparent,
          textColor: botsBlue,
        );
      case ButtonType.danger:
        return _ButtonStyle(
          backgroundColor:
              botsError, // Use AppDesignSystem error color instead of hardcoded Colors.red
          textColor: botsWhite,
        );
    }
  }
}

enum ButtonType { primary, secondary, success, outline, danger }

class _ButtonStyle {
  final Color backgroundColor;
  final Color textColor;

  _ButtonStyle({
    required this.backgroundColor,
    required this.textColor,
  });
}
