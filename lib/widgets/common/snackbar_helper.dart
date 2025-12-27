import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';

/// Helper class for showing consistent snackbars with animations
class SnackbarHelper {
  static void showSuccess(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackbar(
      context,
      message,
      Icons.check_circle,
      colorScheme.tertiary,
    );
  }

  static void showError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackbar(
      context,
      message,
      Icons.error,
      colorScheme.error,
    );
  }

  static void showInfo(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackbar(
      context,
      message,
      Icons.info,
      colorScheme.primary,
    );
  }

  static void showWarning(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    _showSnackbar(
      context,
      message,
      Icons.warning,
      colorScheme.secondary,
    );
  }

  static void _showSnackbar(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: onColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: onColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        closeIconColor: onColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingM),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

