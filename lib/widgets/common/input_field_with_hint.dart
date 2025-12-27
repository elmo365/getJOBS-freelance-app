import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/ai_hint_tooltip.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Input field wrapper that includes an AI hint icon
/// Provides consistent layout with label, field, and hint button
class InputFieldWithHint extends StatelessWidget {
  final String label;
  final String fieldName; // For AI hint generation
  final String screenId; // For AI hint generation
  final AppUserRole userRole;
  final bool monetizationEnabled;
  final Widget field; // The actual input field (TextField, TextFormField, etc.)
  final bool required;
  final String? staticHint; // Optional fallback hint
  final IconData? hintIcon; // Custom hint icon

  const InputFieldWithHint({
    super.key,
    required this.label,
    required this.fieldName,
    required this.screenId,
    required this.userRole,
    required this.monetizationEnabled,
    required this.field,
    this.required = false,
    this.staticHint,
    this.hintIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator and hint icon
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (required) ...[
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                    Text(
                      '*',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // AI Hint tooltip button
            AIHintTooltip(
              fieldName: fieldName,
              screenId: screenId,
              userRole: userRole,
              monetizationEnabled: monetizationEnabled,
              tooltip: staticHint ?? 'Get AI hint for $label',
              icon: hintIcon,
              size: 24,
            ),
          ],
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
        // Input field
        field,
      ],
    );
  }
}
