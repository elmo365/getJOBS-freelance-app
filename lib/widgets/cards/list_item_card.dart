import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// List Item Card - Clean list item with icon, title, value, and percentage
/// Maps to the list items in "Trade Crypto" section in banner-image_home.png
/// White card on light grey background for high contrast
class ListItemCard extends StatelessWidget {
  final String title;
  final String value;
  final String? percentageChange;
  final bool isPositive;
  final Widget leading; // Icon or image
  final VoidCallback? onTap;

  const ListItemCard({
    super.key,
    required this.title,
    required this.value,
    this.percentageChange,
    this.isPositive = true,
    required this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: botsWhite, // White card on light grey background
          border: Border(
            bottom: BorderSide(
              color: botsDivider,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Leading icon/image
            leading,
            const SizedBox(width: 16),
            // Title and value column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDesignSystem.titleSmall(context).copyWith(
                      color: botsTextPrimary, // Black text on white
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppDesignSystem.bodyMedium(context).copyWith(
                      color: botsTextSecondary, // Grey text for secondary
                    ),
                  ),
                ],
              ),
            ),
            // Percentage change
            if (percentageChange != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? botsGreen : botsError)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                ),
                child: Text(
                  percentageChange!,
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: isPositive ? botsGreen : botsError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

