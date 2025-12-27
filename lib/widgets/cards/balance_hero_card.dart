import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Balance Hero Card - Blue background with white text
/// Maps to the top balance card in banner-image_home.png
/// High contrast: Blue background (botsBlue) with white text
class BalanceHeroCard extends StatelessWidget {
  final String title;
  final String value;
  final bool showVisibilityToggle;
  final VoidCallback? onVisibilityToggle;
  final VoidCallback? onTap;

  const BalanceHeroCard({
    super.key,
    required this.title,
    required this.value,
    this.showVisibilityToggle = true,
    this.onVisibilityToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: botsBlue, // Blue background from brand palette
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXL),
          boxShadow: AppDesignSystem.mediumShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and visibility toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppDesignSystem.bodyMedium(context).copyWith(
                    color: botsWhite, // White text on blue for high contrast
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showVisibilityToggle)
                  GestureDetector(
                    onTap: onVisibilityToggle,
                    child: Icon(
                      Icons.visibility_outlined,
                      color: botsWhite, // White icon on blue
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Value
            Text(
              value,
              style: AppDesignSystem.headlineLarge(context).copyWith(
                color: botsWhite, // White text on blue for high contrast
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

