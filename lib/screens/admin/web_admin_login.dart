import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/admin/web_admin_dashboard.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';

/// Web Admin Login - Optimized for browser access
class WebAdminLogin extends StatefulWidget {
  const WebAdminLogin({super.key});

  @override
  State<WebAdminLogin> createState() => _WebAdminLoginState();
}

class _WebAdminLoginState extends State<WebAdminLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

      // Navigate to admin dashboard
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WebAdminDashboard(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: AppDesignSystem.paddingL,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: AppDesignSystem.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? AppDesignSystem.spaceXXL : AppDesignSystem.spaceXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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

                    // Title
                    Text(
                      'Admin Dashboard',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),

                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),

                    Text(
                      'Sign in to manage company applications',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                    ),

                    AppDesignSystem.verticalSpace(20),

                    // Password Field
                    TextField(
                      controller: _passwordController,
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppDesignSystem.borderRadiusM,
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                    ),

                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                    // Login Button
                    StandardButton(
                      label: 'Admin Login',
                      type: StandardButtonType.primary,
                      onPressed: _isLoading ? null : _adminLogin,
                      isLoading: _isLoading,
                      fullWidth: true,
                    ),

                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                    // Info Card
                    Container(
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
                              'Only authorized administrators can access this dashboard',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                    // Features List
                    if (isDesktop) ...[
                      const Divider(),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      Text(
                        'Dashboard Features',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      _buildFeature(Icons.pending_actions,
                          'Review pending company applications'),
                      _buildFeature(
                          Icons.check_circle, 'Approve legitimate companies'),
                      _buildFeature(
                          Icons.cancel, 'Reject fraudulent applications'),
                      _buildFeature(
                          Icons.analytics, 'View statistics & analytics'),
                      _buildFeature(Icons.search, 'Search & filter companies'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.tertiary),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
