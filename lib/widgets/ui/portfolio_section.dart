import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/cards/portfolio_card.dart';

/// Portfolio Section - Horizontal scrollable section with header
/// Maps to the "My Portfolio" section in banner-image_home.png
class PortfolioSection extends StatelessWidget {
  final String title;
  final List<PortfolioCardData> items;
  final VoidCallback? onSeeAll;

  const PortfolioSection({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Calculate responsive grid columns based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth > 600) {
      crossAxisCount = 3; // Tablet/Desktop: 3 columns
    } else {
      crossAxisCount = 2; // Mobile: 2 columns
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppDesignSystem.headlineSmall(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See all',
                    style: AppDesignSystem.bodySmall(context).copyWith(
                      color: AppDesignSystem.brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid layout - all cards visible at a glance, no scrolling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // No scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppDesignSystem.spaceM,
              mainAxisSpacing: AppDesignSystem.spaceM,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return PortfolioCard(
                title: item.title,
                value: item.value,
                subtitle: item.subtitle,
                icon: item.icon,
                iconColor: item.iconColor,
                chart: item.chart,
                onTap: item.onTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Data model for portfolio card
class PortfolioCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? chart;
  final VoidCallback? onTap;

  const PortfolioCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.chart,
    this.onTap,
  });
}

