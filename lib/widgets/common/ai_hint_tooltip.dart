import 'package:flutter/material.dart';
import 'package:freelance_app/services/hints/ai_hints_service.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// AI-powered tooltip widget for field hints
/// Shows a question mark icon that displays AI-generated hint in a tooltip
/// Similar to the API settings admin portal design
class AIHintTooltip extends StatefulWidget {
  final String fieldName;
  final String screenId;
  final AppUserRole userRole;
  final bool monetizationEnabled;
  final String? tooltip;
  final double? size;
  final IconData? icon;

  const AIHintTooltip({
    super.key,
    required this.fieldName,
    required this.screenId,
    required this.userRole,
    required this.monetizationEnabled,
    this.tooltip,
    this.size = 20,
    this.icon,
  });

  @override
  State<AIHintTooltip> createState() => _AIHintTooltipState();
}

class _AIHintTooltipState extends State<AIHintTooltip> {
  final AIHintsService _aiHintsService = AIHintsService();
  String? _cachedHint;
  bool _isLoading = false;

  Future<String?> _fetchAIHint() async {
    if (_cachedHint != null) {
      return _cachedHint;
    }

    if (_isLoading) return null;

    setState(() => _isLoading = true);

    try {
      final hints = await _aiHintsService.generateFieldHint(
        fieldName: widget.fieldName,
        screenId: widget.screenId,
        userRole: widget.userRole,
        monetizationEnabled: widget.monetizationEnabled,
      );

      if (mounted) {
        setState(() {
          _cachedHint = hints;
          _isLoading = false;
        });
      }

      return hints;
    } catch (e) {
      debugPrint('Error fetching AI hint for ${widget.fieldName}: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: widget.tooltip ?? 'Get hint',
      child: GestureDetector(
        onTap: () => _showHintDialog(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              widget.icon ?? Icons.help_outline,
              size: (widget.size ?? 20) * 0.6,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showHintDialog(BuildContext dialogContext) {
    final colorScheme = Theme.of(dialogContext).colorScheme;
    final textTheme = Theme.of(dialogContext).textTheme;

    showDialog(
      context: dialogContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: AppDesignSystem.borderRadiusL,
              ),
              backgroundColor: colorScheme.surface,
              child: SingleChildScrollView(
                child: Padding(
                  padding: AppDesignSystem.paddingL,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: colorScheme.primary,
                                size: 28,
                              ),
                              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                              Text(
                                'AI Hint',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      if (_isLoading) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ] else if (_cachedHint != null && _cachedHint!.isNotEmpty) ...[
                        Container(
                          padding: AppDesignSystem.paddingM,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: AppDesignSystem.borderRadiusM,
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            _cachedHint!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'No hint available for this field.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Got it',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _fetchAIHint();
  }
}
