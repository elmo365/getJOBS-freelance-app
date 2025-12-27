import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Portfolio Card - Horizontal scrollable card for portfolio items
/// Maps to the "My Portfolio" cards in banner-image_home.png
/// White card on light grey background for high contrast
class PortfolioCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? chart; // Optional mini chart/graph
  final VoidCallback? onTap;

  const PortfolioCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.chart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: botsWhite, // White card on light grey background
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          boxShadow: AppDesignSystem.cardShadow,
          border: Border.all(
            color: botsDivider,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppDesignSystem.labelMedium(context).copyWith(
                      color: botsTextPrimary, // Black text on white
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Value
            Text(
              value,
              style: AppDesignSystem.titleLarge(context).copyWith(
                color: botsTextPrimary, // Black text on white
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              subtitle,
              style: AppDesignSystem.bodySmall(context).copyWith(
                color: botsTextSecondary, // Grey text for secondary info
              ),
            ),
            if (chart != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: chart!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

