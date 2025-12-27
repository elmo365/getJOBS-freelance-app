import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

/// Admin Setup Screen - One-time setup for designating admin users
/// Access this screen via a secret setup key to prevent unauthorized access
class AdminSetupScreen extends StatefulWidget {
  final String? setupKey;

  const AdminSetupScreen({
    super.key,
    this.setupKey,
  });

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen>
    with ConnectivityAware {
  final _formKey = GlobalKey<FormState>();
  final _setupKeyController = TextEditingController();
  final _emailController = TextEditingController();
  final _dbService = FirebaseDatabaseService();

  final List<String> _adminEmails = [];
  bool _isKeyVerified = false;
  bool _isLoading = false;
  bool _setupComplete = false;

  // Secret setup key - In production, get this from environment variables or secure config
  static const String _secretSetupKey = 'BOTSJOBS2025ADMIN';

  @override
  void initState() {
    super.initState();
    if (widget.setupKey != null && widget.setupKey == _secretSetupKey) {
      _isKeyVerified = true;
    }
    _checkIfAdminExists();
  }

  @override
  void dispose() {
    _setupKeyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAdminExists() async {
    try {
      final admins = await _dbService.searchUsers(limit: 1);
      for (var doc in admins.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data?['isAdmin'] == true) {
          setState(() => _setupComplete = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking admin: $e');
    }
  }

  void _verifySetupKey() {
    final key = _setupKeyController.text.trim();
    if (key == _secretSetupKey) {
      setState(() => _isKeyVerified = true);
      SnackbarHelper.showSuccess(
          context, 'Setup key verified! You can now add admin users.');
    } else {
      SnackbarHelper.showError(
          context, 'Invalid setup key. Please contact support.');
    }
  }

  void _addEmailToList() {
    if (_emailController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'Please enter an email address');
      return;
    }

    final email = _emailController.text.trim().toLowerCase();

    // Validate email format
    if (!email.contains('@') || !email.contains('.')) {
      SnackbarHelper.showError(context, 'Please enter a valid email address');
      return;
    }

    if (_adminEmails.contains(email)) {
      SnackbarHelper.showError(context, 'Email already added');
      return;
    }

    setState(() {
      _adminEmails.add(email);
      _emailController.clear();
    });
  }

  void _removeEmail(String email) {
    setState(() {
      _adminEmails.remove(email);
    });
  }

  Future<void> _setupAdmins() async {
    if (_adminEmails.isEmpty) {
      SnackbarHelper.showError(context, 'Please add at least one admin email');
      return;
    }

    if (!await checkConnectivity(context,
        message:
            'Cannot setup admins without internet. Please connect and try again.')) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      int successCount = 0;
      int notFoundCount = 0;

      for (String email in _adminEmails) {
        // Search for user by email
        final usersQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (usersQuery.docs.isNotEmpty) {
          final userDoc = usersQuery.docs.first;

          // Update user to admin
          await _dbService.updateUser(
            userId: userDoc.id,
            data: {
              'isAdmin': true,
              'adminSetupDate': DateTime.now().toIso8601String(),
            },
          );

          successCount++;
        } else {
          notFoundCount++;
          debugPrint('User not found: $email');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _setupComplete = true;
        });

        if (successCount > 0) {
          SnackbarHelper.showSuccess(
            context,
            '$successCount admin(s) configured successfully!${notFoundCount > 0 ? ' ($notFoundCount email(s) not found - users must sign up first)' : ''}',
          );
        } else {
          SnackbarHelper.showError(
            context,
            'No users found. Admins must create accounts first before being promoted.',
          );
        }

        // Clear the list after successful setup
        if (successCount > 0) {
          setState(() => _adminEmails.clear());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = 'Failed to setup admins';
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('network') ||
            errorString.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('permission') ||
            errorString.contains('forbidden')) {
          errorMessage =
              'Permission denied. Please check your Firebase security rules.';
        }

        SnackbarHelper.showError(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return HintsWrapper(
      screenId: 'admin_setup_screen',
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      appBar: AppAppBar(
        title: 'Admin Setup',
        variant: AppBarVariant.standard,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDesignSystem.paddingL,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: colorScheme.primary,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text(
                  'Admin Setup',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  _setupComplete
                      ? 'Admin users have been configured. You can add more admins here.'
                      : 'One-time setup to designate admin users for the platform.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                // Setup key verification (if not already verified)
                if (!_isKeyVerified) ...[
                  Container(
                    padding: AppDesignSystem.paddingM,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: AppDesignSystem.borderRadiusM,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security,
                            color: colorScheme.onSecondaryContainer),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Expanded(
                          child: Text(
                            'Enter the secret setup key to continue',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                  StandardInput(
                    label: 'Setup Key',
                    hint: 'Enter secret setup key',
                    controller: _setupKeyController,
                    prefixIcon: Icons.key,
                    isPassword: true,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  StandardButton(
                    label: 'Verify Key',
                    onPressed: _verifySetupKey,
                    type: StandardButtonType.primary,
                    icon: Icons.verified_user,
                    fullWidth: true,
                  ),
                ] else ...[
                  // Admin email input
                  Text(
                    'Add Admin Users',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    'Enter email addresses of users who should have admin privileges. Users must have accounts before being promoted to admin.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                  Row(
                    children: [
                      Expanded(
                        child: StandardInput(
                          label: 'Admin Email Address',
                          hint: 'admin@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
                        ),
                      ),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                      StandardButton(
                        label: 'Add',
                        onPressed: _addEmailToList,
                        type: StandardButtonType.secondary,
                        icon: Icons.add,
                      ),
                    ],
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                  // Admin emails list
                  if (_adminEmails.isNotEmpty) ...[
                    Text(
                      'Admin Users to Configure:',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outlineVariant),
                        borderRadius: AppDesignSystem.borderRadiusM,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _adminEmails.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final email = _adminEmails[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: Icon(Icons.person,
                                  color: colorScheme.onPrimary),
                            ),
                            title: Text(
                              email,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: colorScheme.error,
                              ),
                              onPressed: () => _removeEmail(email),
                            ),
                          );
                        },
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                    // Setup button
                    StandardButton(
                      label: 'Setup Admins (${_adminEmails.length})',
                      onPressed: _setupAdmins,
                      type: StandardButtonType.success,
                      icon: Icons.check_circle,
                      fullWidth: true,
                      isLoading: _isLoading,
                    ),
                  ],

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                  // Info card
                  Container(
                    padding: AppDesignSystem.paddingM,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppDesignSystem.borderRadiusM,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: colorScheme.primary),
                            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                            Text(
                              'Important Notes:',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _buildInfoItem(
                            'Users must create accounts before being promoted to admin'),
                        _buildInfoItem(
                            'Admin users can approve jobs, companies, and manage users'),
                        _buildInfoItem('You can add multiple admins at once'),
                        _buildInfoItem(
                            'Keep the setup key secure - it grants admin access'),
                      ],
                    ),
                  ),

                  if (_setupComplete) ...[
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                    Container(
                      padding: AppDesignSystem.paddingM,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: AppDesignSystem.borderRadiusM,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: colorScheme.onTertiaryContainer),
                          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                          Expanded(
                            child: Text(
                              'Admin setup complete! Admins can now log in.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
