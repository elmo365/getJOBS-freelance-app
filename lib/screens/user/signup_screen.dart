import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/services/firebase/firebase_storage_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/utils/global_methods.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin, ConnectivityAware {
  late AnimationController _animationController;

  final _signUpFormKey = GlobalKey<FormState>();

  File? imageFile;

  // Account type selection
  bool _isCompany = false;

  // Common fields
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();

  // Company-specific fields
  final TextEditingController _companyNameController = TextEditingController();
  final FocusNode _companyNameFocusNode = FocusNode();

  final TextEditingController _registrationNumberController =
      TextEditingController();
  final FocusNode _registrationNumberFocusNode = FocusNode();

  final TextEditingController _industryController = TextEditingController();
  final FocusNode _industryFocusNode = FocusNode();

  final TextEditingController _websiteController = TextEditingController();
  final FocusNode _websiteFocusNode = FocusNode();

  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  String? imageUrl;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _companyNameFocusNode.dispose();
    _registrationNumberFocusNode.dispose();
    _industryFocusNode.dispose();
    _websiteFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppDesignSystem.nearlyWhite,
                AppDesignSystem.brandBlue.withValues(alpha: 0.06),
                AppDesignSystem.softBackground,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom Header instead of AppBar to match LoginScreen style
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spaceL, vertical: AppDesignSystem.spaceM),
                   child: Stack(
                     alignment: Alignment.center,
                     children: [
                       Align(
                         alignment: Alignment.centerLeft,
                         child: IconButton(
                           icon: Icon(Icons.arrow_back_ios_rounded, color: colorScheme.primary),
                           onPressed: () => Navigator.of(context).pop(),
                         ),
                       ),
                       Image.asset(
                         'assets/images/BOTSJOBSCONNECT logo.png',
                         height: 48,
                         fit: BoxFit.contain,
                       ),
                     ],
                   ),
                 ),
                 Expanded(
                    child: SingleChildScrollView(
                        padding: AppDesignSystem.paddingSymmetric(
                          horizontal: AppDesignSystem.spaceL,
                          vertical: AppDesignSystem.spaceM,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                            Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                            Text(
                              'Join Bots Jobs Connect today',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                            // Account Type Selection
                            _accountTypeSelector(),

                            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                            // Avatar
                            _modernAvatar(),

                            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                            // Form
                            Form(
                              key: _signUpFormKey,
                              child: Column(
                                children: [
                                  // Common fields for both types
                                  if (_isCompany) ...[
                                    _modernCompanyNameField(),
                                    AppDesignSystem.verticalSpace(20),
                                    _modernRegistrationNumberField(),
                                    AppDesignSystem.verticalSpace(20),
                                    _modernIndustryField(),
                                    AppDesignSystem.verticalSpace(20),
                                  ],
                                  _modernNameField(),
                                  AppDesignSystem.verticalSpace(20),
                                  _modernEmailField(),
                                  AppDesignSystem.verticalSpace(20),
                                  _modernPasswordField(),
                                  AppDesignSystem.verticalSpace(20),
                                  _modernPhoneField(),
                                  AppDesignSystem.verticalSpace(20),
                                  _modernAddressField(),
                                  if (_isCompany) ...[
                                    AppDesignSystem.verticalSpace(20),
                                    _modernWebsiteField(),
                                    AppDesignSystem.verticalSpace(20),
                                    _modernDescriptionField(),
                                  ],
                                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                                  // Sign Up Button
                                  StandardButton(
                                    label: _isCompany
                                        ? 'Create Company Account'
                                        : 'Create Account',
                                    type: StandardButtonType.primary,
                                    onPressed: _isLoading ? null : _submitSignUpForm,
                                    isLoading: _isLoading,
                                    fullWidth: true,
                                    icon: Icons.person_add,
                                  ),

                                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                                  _haveAccount(),
                                ],
                              ),
                            ),
                            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                          ],
                        ),
                    ),
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppDesignSystem.paddingXS,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppDesignSystem.borderRadiusM,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCompany = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isCompany ? colorScheme.primary : Colors.transparent,
                  borderRadius: AppDesignSystem.borderRadiusM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: !_isCompany
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                    Text(
                      'Job Seeker',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: !_isCompany
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCompany = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isCompany ? colorScheme.primary : Colors.transparent,
                  borderRadius: AppDesignSystem.borderRadiusM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_outlined,
                      color: _isCompany
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                    Text(
                      'Company',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isCompany
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernAvatar() {
    final colorScheme = Theme.of(context).colorScheme;
    // Different label and icon for company vs job seeker
    final isCompanyMode = _isCompany;
    final placeholderIcon = isCompanyMode ? Icons.business : Icons.person;
    final label = isCompanyMode ? 'Company Logo' : 'Profile Photo';
    
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageDialog,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 3,
                  color: colorScheme.primary,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageFile == null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            placeholderIcon,
                            size: 50,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: AppDesignSystem.paddingS,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: colorScheme.onTertiaryContainer,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: AppDesignSystem.paddingS,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: colorScheme.onTertiaryContainer,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernNameField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _nameFocusNode,
      controller: _nameController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _emailFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: _isCompany ? 'Contact Person Name' : 'Full Name',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return _isCompany ? 'Please enter contact person name' : 'Please enter your full name';
        }
        return null;
      },
    );
  }

  Widget _modernEmailField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _emailFocusNode,
      controller: _emailController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _passwordFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) => InputValidators.validateEmail(value),
    );
  }

  Widget _modernPasswordField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _passwordFocusNode,
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _phoneFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
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
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) => InputValidators.validatePassword(value),
    );
  }

  Widget _modernPhoneField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _phoneFocusNode,
      controller: _phoneController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _addressFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.phone_outlined, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter your phone number';
        }
        return null;
      },
    );
  }

  Widget _modernAddressField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _addressFocusNode,
      controller: _addressController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      onEditingComplete: () => _addressFocusNode.unfocus(),
      decoration: InputDecoration(
        labelText: 'Address',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon:
            Icon(Icons.location_on_outlined, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter your address';
        }
        return null;
      },
    );
  }

  Widget _modernCompanyNameField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _companyNameFocusNode,
      controller: _companyNameController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _registrationNumberFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Company Name',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.business, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) {
        if (_isCompany && value!.isEmpty) {
          return 'Please enter company name';
        }
        return null;
      },
    );
  }

  Widget _modernRegistrationNumberField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _registrationNumberFocusNode,
      controller: _registrationNumberController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _industryFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Company Registration Number',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.assignment_outlined, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) {
        if (_isCompany && value!.isEmpty) {
          return 'Please enter registration number';
        }
        return null;
      },
    );
  }

  Widget _modernIndustryField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _industryFocusNode,
      controller: _industryController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _nameFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Industry/Sector',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.work_outline, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) {
        if (_isCompany && value!.isEmpty) {
          return 'Please enter industry/sector';
        }
        return null;
      },
    );
  }

  Widget _modernWebsiteField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _websiteFocusNode,
      controller: _websiteController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => _descriptionFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Website (Optional)',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.language, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _modernDescriptionField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      enabled: true,
      focusNode: _descriptionFocusNode,
      controller: _descriptionController,
      style: theme.textTheme.bodyLarge,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.done,
      maxLines: 4,
      onEditingComplete: () => _descriptionFocusNode.unfocus(),
      decoration: InputDecoration(
        labelText: 'Company Description',
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon:
            Icon(Icons.description_outlined, color: colorScheme.primary),
        alignLabelWithHint: true,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: (value) {
        if (_isCompany && value!.isEmpty) {
          return 'Please enter company description';
        }
        return null;
      },
    );
  }

  void _submitSignUpForm() async {
    final isValid = _signUpFormKey.currentState!.validate();
    if (isValid) {
      // REMOVED: Profile picture is now OPTIONAL (no longer mandatory)
      setState(
        () {
          _isLoading = true;
        },
      );
      try {
        // Create user account with Appwrite
        final user = await _authService.signUp(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );

        final uid = user.uid;

        // Note: signUp() now uses createEmailPasswordSession() which automatically
        // creates a session, so we already have an active session for database operations.
        // The login() call below is kept as a verification step, but should always succeed.
        try {
          final session = await _authService.login(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text.trim(),
          );
          debugPrint('Session verified. User ID: ${session.uid}');
        } catch (loginError) {
          // This should not happen since signUp() already created a session
          // But if it does, it means password wasn't saved correctly
          debugPrint('WARNING: Login failed after signup: $loginError');
          debugPrint(
              'This indicates the password may not have been saved correctly.');
          // Don't throw here - continue with database operations using existing session
          // If database operations fail, we'll catch that error below
        }

        String? imageUrl;

        // Upload profile image if provided (OPTIONAL now!)
        if (imageFile != null) {
          try {
            // Check if file exists before uploading
            if (await imageFile!.exists()) {
              imageUrl = await _storageService.uploadProfileImage(
                filePath: imageFile!.path,
                userId: uid,
              );
            } else {
              debugPrint(
                  'Image file no longer exists at path: ${imageFile!.path}');
              // Continue without image - not critical
            }
          } catch (e) {
            debugPrint('Error uploading image: $e');
            // Continue without image - not critical
          }
        }

        // Create user document in Appwrite database with approval system
        String? optionalText(String value) {
          final trimmed = value.trim();
          return trimmed.isEmpty ? null : trimmed;
        }

        final Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'isFreelancer': !_isCompany,
          'isCompany': _isCompany,
          // Used by admin/user queries across the app
          'createdAt': FieldValue.serverTimestamp(),
          // Some parts of the app expect an account type
          'accountType': _isCompany ? 'company' : 'job_seeker',
        };

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Use 'company_logo' for companies, 'user_image' for job seekers
          userData[_isCompany ? 'company_logo' : 'user_image'] = imageUrl;
        }

        final phoneNumber = optionalText(_phoneController.text);
        if (phoneNumber != null) {
          userData['phone_number'] = phoneNumber;
        }

        final address = optionalText(_addressController.text);
        if (address != null) {
          userData['address'] = address;
        }

        // Add company-specific fields
        if (_isCompany) {
          userData.addAll({
            'isApproved': false, // Companies need approval
            'approvalStatus': 'pending', // pending, approved, rejected
          });

          final companyName = optionalText(_companyNameController.text);
          if (companyName != null) {
            userData['company_name'] = companyName;
          }

          final registrationNumber =
              optionalText(_registrationNumberController.text);
          if (registrationNumber != null) {
            userData['registration_number'] = registrationNumber;
          }

          final industry = optionalText(_industryController.text);
          if (industry != null) {
            userData['industry'] = industry;
          }

          final website = optionalText(_websiteController.text);
          if (website != null) {
            userData['website'] = website;
          }

          final description = optionalText(_descriptionController.text);
          if (description != null) {
            userData['company_description'] = description;
          }
        } else {
          // Job seekers are auto-approved
          userData.addAll({
            'isApproved': true,
            'approvalStatus': 'approved',
          });
        }

        // Create user document in database
        // Session should be established by now from auto-login
        debugPrint('Creating user document with data: $userData');
        await _dbService.createUser(userId: uid, data: userData);
        debugPrint('User document created successfully in database.');

        // Initialize company KYC document record (draft)
        if (_isCompany) {
          try {
            await FirebaseFirestore.instance
                .collection('company_kyc')
                .doc(uid)
                .set({
              'companyId': uid,
              'companyName': _companyNameController.text.trim(),
              'companyEmail': _emailController.text.trim().toLowerCase(),
              'status': 'draft', // draft, submitted, approved, rejected
              'createdAt': FieldValue.serverTimestamp(),
              'documents': {},
            }, SetOptions(merge: true));

            // Notify admins about new company registration
            try {
              final notificationService = NotificationService();
              final admins = await FirebaseFirestore.instance
                  .collection('users')
                  .where('isAdmin', isEqualTo: true)
                  .limit(25)
                  .get();
              
              for (var adminDoc in admins.docs) {
                await notificationService.sendNotification(
                  userId: adminDoc.id,
                  type: 'new_company_registered',
                  title: 'New Company Registration',
                  body: 'A new company "${_companyNameController.text.trim()}" has registered and needs verification.',
                  data: {
                    'companyId': uid,
                    'companyName': _companyNameController.text.trim(),
                    'companyEmail': _emailController.text.trim().toLowerCase(),
                  },
                  sendEmail: true,
                );
              }
              
              // Send welcome email to company
              await notificationService.sendNotification(
                userId: uid,
                type: 'company_welcome',
                title: 'Welcome to BotsJobsConnect! 🎉',
                body: 'Welcome, ${_companyNameController.text.trim()}! Your company account has been created. Next step: Complete your verification to start posting jobs.',
                data: {
                  'companyId': uid,
                  'companyName': _companyNameController.text.trim(),
                },
                sendEmail: true,
              );
            } catch (e) {
              debugPrint('Error notifying about new company: $e');
              // Don't block signup if notification fails
            }
          } catch (e) {
            debugPrint('Failed to init company_kyc doc: $e');
          }
        }

        // Navigate back
        if (!mounted) return;
        Navigator.of(context).pop();

        // Show success message based on account type
        final message = _isCompany
            ? 'Company account created! Please submit your KYC documents for approval.'
            : 'Account created successfully!';

        final icon = _isCompany ? Icons.pending_actions : Icons.check_circle;

        GlobalMethod.showErrorDialog(
          context: context,
          icon: icon,
          iconColor: _isCompany
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.primary,
          title: _isCompany ? 'Pending Admin Approval' : 'Success',
          body: message,
          buttonText: 'OK',
        );
      } catch (error) {
        // Handle errors - show more specific error messages
        String errorMessage = 'Registration failed';

        debugPrint('Registration error: $error');
        debugPrint('Error type: ${error.runtimeType}');

        final errorString = error.toString().toLowerCase();

        // Check for specific error codes first
        if (errorString.contains('409') ||
            errorString.contains('already exists') ||
            errorString.contains('duplicate')) {
          errorMessage =
              'This email is already registered. Please use a different email or try logging in.';
        } else if (errorString.contains('401') ||
            errorString.contains('unauthorized')) {
          // Check if it's about email verification
          if (errorString.contains('verification') ||
              errorString.contains('verify') ||
              errorString.contains('not verified')) {
            errorMessage =
                'Account created but email verification may be required. Please try logging in manually.';
          } else if (errorString.contains('login failed')) {
            errorMessage =
                'Account created but auto-login failed. Please try logging in with your email and password.';
          } else {
            errorMessage =
                'Authentication failed. Please try logging in manually.';
          }
        } else if (errorString.contains('403') ||
            errorString.contains('permission') ||
            errorString.contains('forbidden')) {
          errorMessage =
              'Permission denied. Unable to create user profile. Please contact support.';
        } else if (errorString.contains('404') ||
            errorString.contains('not found')) {
          errorMessage =
              'Database collection not found. Please contact support.';
        } else if (errorString.contains('password') ||
            errorString.contains('weak')) {
          errorMessage =
              'Password is too weak. Please use at least 8 characters.';
        } else if (errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('timeout')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('400') &&
            errorString.contains('email') &&
            !errorString.contains('verification')) {
          // Only show invalid email if it's specifically about email format, not verification
          errorMessage =
              'Invalid email format. Please check your email address.';
        } else {
          // Show the actual error message for better debugging
          errorMessage = error
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('Error: ', '')
              .replaceAll('AppwriteException: ', '');

          // Clean up the message
          if (errorMessage.contains('(') && errorMessage.contains(')')) {
            // Remove error codes in parentheses for cleaner display
            errorMessage = errorMessage.split('(')[0].trim();
          }

          if (errorMessage.length > 150) {
            errorMessage = '${errorMessage.substring(0, 150)}...';
          }

          // If we still have a generic message, make it more helpful
          if (errorMessage.isEmpty || errorMessage == 'Registration failed') {
            errorMessage =
                'Unable to complete registration. Please try again or contact support.';
          }
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        GlobalMethod.showErrorDialog(
          context: context,
          icon: Icons.error,
          iconColor: Theme.of(context).colorScheme.error,
          title: 'Registration Error',
          body: errorMessage,
          buttonText: 'OK',
        );
      }
    }
    setState(
      () {
        _isLoading = false;
      },
    );
  }

  Widget _haveAccount() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    Navigator.canPop(context) ? Navigator.pop(context) : null,
              text: 'Login',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Choose image source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Camera'),
                onTap: () => _getFromCamera(dialogContext),
              ),
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  Icons.image_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Gallery'),
                onTap: () => _getFromGallery(dialogContext),
              ),
            ],
          ),
        );
      },
    );
  }

  void _getFromCamera(BuildContext dialogContext) async {
    if (!mounted) return;

    try {
      // Close the image source dialog first using the dialog's context
      Navigator.pop(dialogContext);

      final XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (pickedFile != null && mounted) {
        await _cropImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to pick image from camera');
      }
    }
  }

  void _getFromGallery(BuildContext dialogContext) async {
    if (!mounted) return;

    try {
      // Close the image source dialog first using the dialog's context
      Navigator.pop(dialogContext);

      final XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        await _cropImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to pick image from gallery');
      }
    }
  }

  Future<void> _cropImage(String filePath) async {
    if (!mounted) return;

    try {
      // Ensure we have a valid context before opening cropper
      if (!mounted) return;

      final CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 1080,
        maxWidth: 1080,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      // Check mounted again after cropping (native activity might have changed state)
      if (!mounted) return;

      if (croppedImage != null) {
        // Copy cropped image to permanent directory to prevent deletion
        final appDir = await getApplicationDocumentsDirectory();
        final permanentDir =
            Directory(path.join(appDir.path, 'profile_images'));
        if (!await permanentDir.exists()) {
          await permanentDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            'profile_$timestamp${path.extension(croppedImage.path)}';
        final permanentPath = path.join(permanentDir.path, fileName);

        // Copy file to permanent location
        final croppedFile = File(croppedImage.path);
        final permanentFile = await croppedFile.copy(permanentPath);

        // Final mounted check before setState
        if (mounted) {
          setState(() {
            imageFile = permanentFile;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        SnackbarHelper.showError(
            context, 'Error processing image. Please try again.');
      }
    }
  }
}
