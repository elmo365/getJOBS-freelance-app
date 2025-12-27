import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Action Buttons Row - Two action buttons (Deposit, History)
/// Maps to the action buttons below the balance card in banner-image_home.png
/// Withdraw option removed - not available for any users
class ActionButtonsRow extends StatelessWidget {
  final VoidCallback? onDeposit;
  final VoidCallback? onHistory;

  const ActionButtonsRow({
    super.key,
    this.onDeposit,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.arrow_upward,
          label: 'Deposit',
          onTap: onDeposit,
        ),
        _ActionButton(
          icon: Icons.history,
          label: 'History',
          onTap: onHistory,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: botsSuperLightGrey, // Light grey background
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: botsBlue, // Blue icon for brand consistency
                    size: 24,
                    semanticLabel: label,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: botsTextPrimary, // Black text on white background
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
