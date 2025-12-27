import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/validation/input_validators.dart';

class ModernSearchBar extends StatefulWidget {
  final String hintText;
  final VoidCallback onTap;
  final Function(String)? onSearchChanged;
  final VoidCallback? onNotificationTap;
  final bool showNotification;
  final int notificationCount;
  final TextEditingController? controller;

  const ModernSearchBar({
    super.key,
    required this.hintText,
    required this.onTap,
    this.onSearchChanged,
    this.onNotificationTap,
    this.showNotification = true,
    this.notificationCount = 0,
    this.controller,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              // Sanitize input as user types
              final sanitized = InputValidators.sanitizeSearchInput(value);
              if (sanitized != value) {
                _controller.value = _controller.value.copyWith(
                  text: sanitized,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: sanitized.length),
                  ),
                );
              }
              widget.onSearchChanged?.call(sanitized);
            },
            onTap: widget.onTap,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearchChanged?.call('');
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _focusNode.hasFocus 
                    ? colorScheme.primary 
                    : Colors.transparent,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        if (widget.showNotification) ...[
          const SizedBox(width: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: widget.onNotificationTap,
                icon: const Icon(Icons.notifications_outlined),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconSize: 28,
              ),
              if (widget.notificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      widget.notificationCount > 9 ? '9+' : widget.notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
