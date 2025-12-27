import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';

class AppPagePadding extends StatelessWidget {
  final Widget child;
  final bool includeBottomSafeArea;

  const AppPagePadding({
    super.key,
    required this.child,
    this.includeBottomSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: includeBottomSafeArea,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        ),
        child: child,
      ),
    );
  }
}
