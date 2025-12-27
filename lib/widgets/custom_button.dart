import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String? buttonText;
  final Color? buttonColor;
  final Color? textColor;
  final VoidCallback? onPressed;
  const CustomButton(
      {super.key,
      this.buttonText,
      this.buttonColor,
      this.onPressed,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingXL,
        AppTheme.spacingS,
        AppTheme.spacingXL,
        AppTheme.spacingS,
      ),
      child: InkWell(
        onTap: onPressed,
        child: Container(
            height: 60,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                color: buttonColor ?? colorScheme.primary,
                border: Border.all(width: 1, color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppTheme.radiusL)),
            child: Center(
                child: Text(
              buttonText!,
              style: TextStyle(
                color: textColor ?? colorScheme.onPrimary,
                fontSize: 20,
              ),
            ))),
      ),
    );
  }
}
