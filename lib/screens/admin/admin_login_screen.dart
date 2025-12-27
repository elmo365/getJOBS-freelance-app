import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/admin/admin_panel_screen.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _adminLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = FirebaseAuthService();
      final dbService = FirebaseDatabaseService();

      // Sign in with Appwrite
      await authService.login(
        email: email,
        password: password,
      );

      // Get current user
      final user = authService.getCurrentUser();
      if (user == null) {
        _showError('User not found');
        return;
      }

      // Check if user is admin
      final userDoc = await dbService.getUser(user.uid);
      if (userDoc == null) {
        await authService.logout();
        _showError('User not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final isAdmin = userData['isAdmin'] as bool? ?? false;

      if (!isAdmin) {
        await authService.logout();
        _showError('Access denied. Admin privileges required.');
        return;
      }

      // Navigate to admin panel
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminPanelScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      String message = 'Login failed';
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        message = 'Invalid email or password';
      } else if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else {
        message = e.message ?? 'An error occurred';
      }
      _showError(message);
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    SnackbarHelper.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return HintsWrapper(
      screenId: 'admin_login_screen',
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Critical for keyboard handling
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppDesignSystem.paddingL,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                      maxHeight: 80,
                    ),
                    child: Image.asset(
                      'assets/images/BOTSJOBSCONNECT logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                  // Admin Panel Title
                  Text(
                    'Admin Panel',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),

                  Text(
                    'Sign in to manage company approvals',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                  // Email Field
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      scrollPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Admin Email',
                        hintText: 'admin@example.com',
                        prefixIcon: Icon(Icons.admin_panel_settings,
                            color: colorScheme.primary),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                  // Password Field
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _adminLogin(),
                      scrollPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon:
                            Icon(Icons.lock, color: colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                  // Login Button
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: StandardButton(
                      label: 'Login as Admin',
                      onPressed: _adminLogin,
                      type: StandardButtonType.primary,
                      isLoading: _isLoading,
                      fullWidth: true,
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                  // Info Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: AppDesignSystem.paddingM,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppDesignSystem.borderRadiusM,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Expanded(
                          child: Text(
                            'Only authorized administrators can access this panel',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
