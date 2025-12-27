import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDesignSystem.paddingL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 2),
                  borderRadius: AppDesignSystem.borderRadiusM,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      color: colorScheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

              // Title
              Text(
                "Forgot Password?",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

              // Subtitle
              Text(
                "Don't worry! Enter your email and we'll send you a link to reset your password.",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

              // Email Input
              StandardInput(
                label: "Email Address",
                hint: "Enter your email",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),

              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

              // Send Code Button
              StandardButton(
                label: "Send Reset Link",
                onPressed: _sendPasswordReset,
                type: StandardButtonType.primary,
                fullWidth: true,
                icon: Icons.send,
                isLoading: _isLoading,
              ),

              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

              // Back to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Remember your password?",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                  StandardButton(
                    label: "Login",
                    onPressed: () => Navigator.pop(context),
                    type: StandardButtonType.text,
                    fontSize: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter your email address');
      return;
    }

    // Basic email validation
    if (!email.contains('@') || !email.contains('.')) {
      SnackbarHelper.showError(context, 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Password reset link sent! Please check your email inbox.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = 'Failed to send password reset email';
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('user-not-found') ||
            errorString.contains('not found')) {
          errorMessage =
              'No account found with this email address. Please check your email or sign up.';
        } else if (errorString.contains('invalid-email') ||
            errorString.contains('invalid')) {
          errorMessage =
              'Invalid email format. Please enter a valid email address.';
        } else if (errorString.contains('network') ||
            errorString.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('too-many-requests')) {
          errorMessage =
              'Too many requests. Please wait a few minutes and try again.';
        }

        SnackbarHelper.showError(context, errorMessage);
      }
    }
  }
}
