import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_design_system.dart';

/// Modern input field with validation and animations
class ModernInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const ModernInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<ModernInputField> createState() => _ModernInputFieldState();
}

class _ModernInputFieldState extends State<ModernInputField> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    _animationController = AnimationController(
      vsync: this,
      duration: AppDesignSystem.animationFast,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _validate();
      }
    });
  }

  void _validate() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller?.text);
      setState(() {
        _hasError = error != null;
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: widget.enabled ? AppDesignSystem.surfaceLight : AppDesignSystem.backgroundLight,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(
                color: _hasError
                    ? AppDesignSystem.error
                    : _isFocused
                        ? AppDesignSystem.primaryBlue
                        : AppDesignSystem.divider,
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused ? AppDesignSystem.lightShadow : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              onTap: widget.onTap,
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (_hasError) {
                  _validate();
                }
              },
              textCapitalization: widget.textCapitalization,
              style: AppDesignSystem.bodyMedium(context),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? AppDesignSystem.primaryBlue
                            : AppDesignSystem.textSecondary,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon != null ? AppDesignSystem.spaceS : AppDesignSystem.spaceM,
                  vertical: AppDesignSystem.spaceM,
                ),
                counterText: '',
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
          ),
        ),
        if (_hasError && _errorText != null) ...[
          const SizedBox(height: AppDesignSystem.spaceXS),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 14,
                color: AppDesignSystem.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _errorText!,
                  style: TextStyle(
                    color: AppDesignSystem.error,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Password input field with show/hide toggle
class ModernPasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  const ModernPasswordField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  State<ModernPasswordField> createState() => _ModernPasswordFieldState();
}

class _ModernPasswordFieldState extends State<ModernPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return ModernInputField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppDesignSystem.textSecondary,
        ),
        onPressed: () {
          setState(() => _obscureText = !_obscureText);
        },
      ),
    );
  }
}

