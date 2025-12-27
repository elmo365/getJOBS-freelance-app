import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Tab Navigation Bar - Horizontal tabs for filtering content
/// Maps to the tabs in "Trade Crypto" section in banner-image_home.png
class TabNavigationBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const TabNavigationBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTabChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? botsBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: isSelected
                        ? botsWhite // White text on blue (high contrast)
                        : botsTextPrimary, // Black text on transparent
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

