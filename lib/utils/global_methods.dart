import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';

class GlobalMethod {
  static void showErrorDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String buttonText,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          elevation: AppTheme.elevationLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          icon: Icon(icon, color: iconColor, size: 28),
          title: Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            body,
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }
}

class GlobalMethodTwo {
  static void showErrorDialog(
      {required String error, required BuildContext ctx}) {
    showDialog(
        context: ctx,
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return AlertDialog(
            icon: Icon(
              Icons.error_outline,
              color: colorScheme.error,
            ),
            title: Text(
              'Error occurred',
              style: theme.textTheme.titleLarge,
            ),
            content: Text(
              error,
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
  }
}
