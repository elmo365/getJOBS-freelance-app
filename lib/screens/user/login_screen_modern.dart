import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_app/screens/homescreen/home_screen.dart';
import 'package:freelance_app/screens/user/forgot_password.dart';
import 'package:freelance_app/screens/user/signup_screen.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/layout.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/modern_button.dart';
import 'package:freelance_app/widgets/modern_input_field.dart';

/// Modern Login Screen with offline checks and better UX
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _isLoading = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() {
    ConnectivityService().connectionStatus.listen((result) {
      if (mounted) {
        setState(() {
          _isOnline = result.toString() != 'ConnectivityResult.none';
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_isOnline) {
      SnackbarHelper.showError(
        context,
        'No internet connection. Please check your network and try again.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (FirebaseAuth.instance.currentUser != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homescreen()),
        );
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address format.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your connection.';
      }

      SnackbarHelper.showError(context, errorMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'An unexpected error occurred.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppLayout.screenScaffold(
      context: context,
      backgroundColor: colorScheme.surface,
      body: MicroInteractions.fadeInListItem(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Hero Logo Section
              MicroInteractions.fadeInListItem(
                child: Center(
                      child: Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spaceXL),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.1),
                          colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppDesignSystem.radiusCircular),
                      boxShadow: AppDesignSystem.lightShadow,
                        ),
                        child: Icon(
                          Icons.work_outline,
                      size: 72,
                          color: colorScheme.primary,
                        ),
                      ),
                ),
                index: 0,
                delayPerItem: const Duration(milliseconds: 100),
                    ),

              const SizedBox(height: AppDesignSystem.spaceXL),

              // Welcome Text with Animation
              MicroInteractions.fadeInListItem(
                child: Column(
                  children: [
                    Text(
                      'Welcome back',
                      style: AppDesignSystem.screenTitle(context).copyWith(
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesignSystem.spaceS),
                    Text(
                      'Sign in to continue your job search',
                      style: AppDesignSystem.bodyLarge(context).copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                index: 1,
                delayPerItem: const Duration(milliseconds: 100),
                    ),

              const SizedBox(height: AppDesignSystem.spaceXXL),

              // Offline Warning with Animation
                    if (!_isOnline)
                MicroInteractions.fadeInListItem(
                  child: Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spaceM),
                    margin: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                      ),
                        child: Row(
                          children: [
                        Icon(Icons.wifi_off, color: colorScheme.onError),
                            const SizedBox(width: AppDesignSystem.spaceS),
                            Expanded(
                              child: Text(
                                'You are offline. Please connect to the internet to sign in.',
                            style: AppDesignSystem.bodyMedium(context).copyWith(
                              color: colorScheme.onError,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),
                  index: 2,
                  delayPerItem: const Duration(milliseconds: 100),
                      ),

              // Form Fields with Staggered Animation
              MicroInteractions.staggeredFadeIn(
                children: [
                    // Email Field
                    ModernInputField(
                      label: 'Email Address',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                      if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDesignSystem.spaceM),

                    // Password Field
                    ModernPasswordField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDesignSystem.spaceS),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPassword(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: AppDesignSystem.bodySmall(context).copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDesignSystem.spaceL),

                    // Login Button
                    ModernButton(
                      text: 'Sign In',
                      icon: Icons.login,
                    gradient: _isOnline && !_isLoading
                        ? AppDesignSystem.primaryGradient
                        : null,
                      isLoading: _isLoading,
                    onPressed: _isOnline && !_isLoading ? _handleLogin : null,
                    ),

                  const SizedBox(height: AppDesignSystem.spaceXL),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                        style: AppDesignSystem.bodyMedium(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Register Now',
                          style: AppDesignSystem.bodyMedium(context).copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                delayPerItem: const Duration(milliseconds: 50),
                itemDuration: const Duration(milliseconds: 400),
              ),
            ],
          ),
        ),
        index: 0,
        delayPerItem: const Duration(milliseconds: 200),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }
}
