import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/hints/ai_hints_service.dart';
import 'package:freelance_app/services/hints/hints_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';

class AdminHintsScreen extends StatefulWidget {
  const AdminHintsScreen({super.key});

  @override
  State<AdminHintsScreen> createState() => _AdminHintsScreenState();
}

class _AdminHintsScreenState extends State<AdminHintsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: botsSuperLightGrey,
      appBar: AppAppBar(
        title: 'AI Hints Control',
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        padding: AppDesignSystem.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-Powered Hints System',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Text(
              'Control AI-generated tooltips and hints shown throughout the app. When enabled, AI will generate contextual hints based on user actions and screen context. Hints are accessed via question mark icons on form fields and actions.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            AppCard(
              variant: SurfaceVariant.elevated,
              child: FutureBuilder<bool>(
                future: HintsService().areAIHintsEnabled(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final aiHintsEnabled = snapshot.data ?? false;
                  return SwitchListTile(
                    title: Text(
                      'Enable AI Hints',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      aiHintsEnabled
                          ? 'AI is actively generating smart, contextual hints for users across the app. Users will see question mark icons on form fields to access these hints.'
                          : 'AI hints are disabled. Users will not see AI-generated hints in the app.',
                      style: textTheme.bodySmall,
                    ),
                    value: aiHintsEnabled,
                    onChanged: (value) async {
                      try {
                        await HintsService().setAIHintsEnabled(value);
                        HintsService().clearCache();
                        AIHintsService().clearCache();
                        if (!context.mounted) return;
                        setState(() {});
                        if (!context.mounted) return;
                        SnackbarHelper.showSuccess(
                          context,
                          value
                              ? 'AI hints enabled. Users will see AI-generated hints with question mark icons.'
                              : 'AI hints disabled. No AI hints will be shown to users.',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        SnackbarHelper.showError(
                          context,
                          'Failed to update AI hints setting: $e',
                        );
                      }
                    },
                  );
                },
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            AppCard(
              variant: SurfaceVariant.standard,
              child: Padding(
                padding: AppDesignSystem.paddingM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Hints Work',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHintInfo(
                          '• Question Mark Icons',
                          'Small question mark icons appear next to form fields and actions throughout the app',
                          colorScheme,
                          textTheme,
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _buildHintInfo(
                          '• AI-Generated Tooltips',
                          'When users click the icon, AI generates helpful, contextual tips based on the field and user role',
                          colorScheme,
                          textTheme,
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _buildHintInfo(
                          '• Smart Caching',
                          'Hints are cached for performance. Similar fields receive consistent suggestions',
                          colorScheme,
                          textTheme,
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _buildHintInfo(
                          '• Admin Control Only',
                          'Only administrators can enable/disable AI hints. Individual users cannot toggle hints.',
                          colorScheme,
                          textTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintInfo(
    String title,
    String description,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
        Text(
          description,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
