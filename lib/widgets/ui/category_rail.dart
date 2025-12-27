import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';

/// Category Grid - Displays category items in a responsive grid
/// All items visible at a glance - no horizontal scrolling
/// Wrapped in a card with background and subtle shadows for visual grouping
class CategoryRail extends StatelessWidget {
  final List<CategoryItem> items;
  final Function(String) onItemSelected;

  const CategoryRail({
    super.key,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate responsive grid columns based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth > 600) {
      crossAxisCount = 4; // Tablet/Desktop: 4 columns
    } else {
      crossAxisCount = 3; // Mobile: 3 columns
    }

    // Wrap grid in a card with background and subtle shadows
    return AppCard(
      padding: AppDesignSystem.paddingL,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      variant: SurfaceVariant.standard,
      elevation: 4, // Subtle elevation for card effect
      child: GridView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(), // No scrolling - all visible
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppDesignSystem.spaceM,
          mainAxisSpacing: AppDesignSystem.spaceM,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Semantics(
            label: item.label,
            button: true,
            child: GestureDetector(
              onTap: () => onItemSelected(item.id),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minimum 48x48dp touch target (using 64x64 for better UX)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppDesignSystem
                          .cardSurface, // White background for better contrast
                      shape: BoxShape.circle,
                      boxShadow: AppDesignSystem.cardShadow,
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color ?? AppDesignSystem.brandBlue,
                      size: 28, // Increased from 24 for better visibility
                      semanticLabel: item.label,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryItem {
  final String id;
  final String label;
  final IconData icon;
  final Color? color;

  CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
  });
}
