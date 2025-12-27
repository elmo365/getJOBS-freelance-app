import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_app/screens/homescreen/home_screen.dart';
import 'package:freelance_app/screens/user/forgot_password.dart';
import 'package:freelance_app/screens/user/signup_screen.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/reusable_widgets.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';

/// Modern 2025 Login Screen
/// Features: Gradient background, glass-morphic form container, animated feedback
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _isLoading = false;
  bool _isOnline = true;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();

    // 2025 pattern: Entrance animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    ));

    _animationController.forward();
  }

  void _checkConnectivity() {
    ConnectivityService().connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Homescreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = 'Login failed. ';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('password')) {
        errorMessage += 'Please check your password and try again.';
      } else if (errorString.contains('email')) {
        errorMessage += 'Please check your email address.';
      } else if (errorString.contains('network') ||
          errorString.contains('connection')) {
        errorMessage += 'Please check your internet connection.';
      } else {
        errorMessage +=
            'Please check your credentials and try again. If the problem persists, contact support.';
      }

      SnackbarHelper.showError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: size.height,
        width: double.infinity,
        // 2025 pattern: Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesignSystem.nearlyWhite,
              AppDesignSystem.brandBlue.withValues(alpha: 0.06), // BOTS Blue (balanced)
              AppDesignSystem.softBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: _isLoading,
            message: 'Signing in...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDesignSystem.spaceL),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppDesignSystem.spaceXL),

                        // Modern Logo Container
                        Center(
                          child: Container(
                            padding: AppDesignSystem.paddingL,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: AppDesignSystem.mediumShadow,
                              border: Border.all(
                                color: colorScheme.surface.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.work_outline_rounded,
                              size: 56,
                              color: AppDesignSystem.brandBlue, // BOTS Blue (balanced)
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDesignSystem.spaceXL),

                        // Welcome Text with modern typography
                        Text(
                          'Welcome Back!',
                          style:
                              AppDesignSystem.headlineLarge(context).copyWith(
                            color: AppDesignSystem.brandBlue, // BOTS Blue (balanced)
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppDesignSystem.spaceS),

                        Text(
                          'Sign in to continue your job search',
                          style: AppDesignSystem.bodyLarge(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppDesignSystem.spaceXL),

                        // 2025 pattern: Glass-morphic form container
                        Container(
                          padding: AppDesignSystem.paddingL,
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.9),
                            borderRadius: AppDesignSystem.borderRadiusXL,
                            boxShadow: AppDesignSystem.lightShadow,
                            border: Border.all(
                              color: colorScheme.surface.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Offline Warning
                              if (!_isOnline)
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppDesignSystem.spaceM,
                                  ),
                                  margin: const EdgeInsets.only(
                                    bottom: AppDesignSystem.spaceM,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.error,
                                    borderRadius: BorderRadius.circular(
                                      AppDesignSystem.radiusM,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.wifi_off_rounded,
                                        color: colorScheme.onError,
                                      ),
                                      const SizedBox(
                                        width: AppDesignSystem.spaceS,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'You are offline. Please connect to sign in.',
                                          style:
                                              AppDesignSystem.bodySmall(context)
                                                  .copyWith(
                                            color: colorScheme.onError,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Email Field with modern styling
                              _buildModernTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'Enter your email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  return InputValidators.validateEmail(value);
                                },
                              ),

                              const SizedBox(height: AppDesignSystem.spaceM),

                              // Password Field
                              _buildModernTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                validator: (value) {
                                  return InputValidators.validatePassword(value);
                                },
                              ),

                              const SizedBox(height: AppDesignSystem.spaceS),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: MicroInteractions.scaleOnTap(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPassword(),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppDesignSystem.spaceS,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppDesignSystem.labelLarge(context)
                                          .copyWith(
                                        color: AppDesignSystem.brandBlue, // BOTS Blue (balanced)
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppDesignSystem.spaceL),

                              // 2025 pattern: Gradient login button
                              MicroInteractions.scaleOnTap(
                                onTap: _isOnline ? _handleLogin : () {},
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: _isOnline
                                        ? LinearGradient(
                                            colors: [
                                              AppDesignSystem.brandBlue, // BOTS Blue (primary)
                                              AppDesignSystem.brandGreen, // BOTS Green (secondary)
                                            ],
                                          )
                                        : null,
                                    color: _isOnline
                                        ? null
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppDesignSystem.radiusL,
                                    ),
                                    boxShadow: _isOnline
                                        ? AppDesignSystem.coloredShadow(
                                            AppDesignSystem.brandBlue, // BOTS Blue (balanced)
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.login_rounded,
                                        color: _isOnline
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.38),
                                        size: 20,
                                      ),
                                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                                      Text(
                                        'Sign In',
                                        style:
                                            AppDesignSystem.buttonText(context)
                                                .copyWith(
                                          color: _isOnline
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface
                                                  .withValues(alpha: 0.38),
                                          fontSize: 18,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppDesignSystem.spaceXL),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style:
                                  AppDesignSystem.bodyMedium(context).copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            MicroInteractions.scaleOnTap(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Register Now',
                                style: AppDesignSystem.labelLarge(context)
                                    .copyWith(
                                  color: AppDesignSystem.brandBlue, // BOTS Blue (balanced)
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Modern 2025 text field with enhanced styling
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: AppDesignSystem.bodyLarge(context),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          prefixIcon,
          color: AppDesignSystem.brandBlue.withValues(alpha: 0.7), // BOTS Blue (balanced)
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppDesignSystem.softBackground.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spaceM,
          vertical: AppDesignSystem.spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          borderSide: BorderSide(
            color: colorScheme.primary, // BOTS Blue
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        labelStyle: AppDesignSystem.bodyMedium(context).copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: AppDesignSystem.bodyMedium(context).copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }
}
