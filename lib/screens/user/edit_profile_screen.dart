import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_storage_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/reusable_widgets.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

/// Fully functional Edit Profile Screen with image upload
class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> currentData;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.currentData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with ConnectivityAware {
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  final _storageService = FirebaseStorageService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _companyNameController;
  late TextEditingController _registrationNumberController;
  late TextEditingController _industryController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  File? _newImageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isCompany = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize basic fields
    _nameController = TextEditingController(text: widget.currentData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.currentData['phone_number'] ?? '');
    _addressController = TextEditingController(text: widget.currentData['address'] ?? '');
    _currentImageUrl = widget.currentData['userImage'] ?? widget.currentData['user_image'] ?? '';
    _isCompany = widget.currentData['isCompany'] ?? false;

    // Initialize company fields
    if (_isCompany) {
      _companyNameController = TextEditingController(text: widget.currentData['company_name'] ?? '');
      _registrationNumberController = TextEditingController(text: widget.currentData['registration_number'] ?? '');
      _industryController = TextEditingController(text: widget.currentData['industry'] ?? '');
      _websiteController = TextEditingController(text: widget.currentData['website'] ?? '');
      _descriptionController = TextEditingController(text: widget.currentData['company_description'] ?? '');
    } else {
      _companyNameController = TextEditingController();
      _registrationNumberController = TextEditingController();
      _industryController = TextEditingController();
      _websiteController = TextEditingController();
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: colorScheme.primary),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: colorScheme.secondary),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    if (!mounted) return;
    
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null || !mounted) return;
      
      await _cropImage(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to pick image');
      }
    }
  }

  Future<void> _cropImage(String filePath) async {
    if (!mounted) return;
    
    try {
      // Ensure we have a valid context before opening cropper
      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;
      
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 1080,
        maxWidth: 1080,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: colorScheme.primary,
            toolbarWidgetColor: colorScheme.onPrimary,
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
        // Save to permanent location
        final appDir = await getApplicationDocumentsDirectory();
        final permanentDir = Directory(path.join(appDir.path, 'profile_images'));
        if (!await permanentDir.exists()) {
          await permanentDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'profile_$timestamp${path.extension(croppedImage.path)}';
        final permanentPath = path.join(permanentDir.path, fileName);

        final croppedFile = File(croppedImage.path);
        final permanentFile = await croppedFile.copy(permanentPath);

        // Final mounted check before setState
        if (mounted) {
          setState(() {
            _newImageFile = permanentFile;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Error processing image. Please try again.');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!await checkConnectivity(context, message: 'Cannot save profile without internet. Please connect and try again.')) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare update data
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      };

      // Add company-specific fields
      if (_isCompany) {
        updateData.addAll({
          'company_name': _companyNameController.text.trim(),
          'registration_number': _registrationNumberController.text.trim(),
          'industry': _industryController.text.trim(),
          'website': _websiteController.text.trim(),
          'company_description': _descriptionController.text.trim(),
        });
      }

      // Upload new image if selected
      if (_newImageFile != null && await _newImageFile!.exists()) {
        final imageUrl = await _storageService.uploadProfileImage(
          filePath: _newImageFile!.path,
          userId: widget.userId,
        );
        updateData['userImage'] = imageUrl;
        updateData['user_image'] = imageUrl; // Backward compatibility
      }

      // Update user document
      await _dbService.updateUser(
        userId: widget.userId,
        data: updateData,
      );

      // Update name in auth if changed
      if (_nameController.text.trim() != widget.currentData['name']) {
        await _authService.updateName(_nameController.text.trim());
      }

      // Send security alert if critical fields changed
      try {
        bool criticalChange = false;
        String changeDetails = '';
        
        // Check for email change (handled by auth separately)
        // Check for other sensitive changes
        if (_phoneController.text.trim() != (widget.currentData['phone_number'] ?? '')) {
          criticalChange = true;
          changeDetails += 'Phone number changed. ';
        }
        if (_addressController.text.trim() != (widget.currentData['address'] ?? '')) {
          criticalChange = true;
          changeDetails += 'Address changed. ';
        }
        if (_isCompany && _websiteController.text.trim() != (widget.currentData['website'] ?? '')) {
          criticalChange = true;
          changeDetails += 'Website changed. ';
        }
        
        if (criticalChange) {
          final notificationService = NotificationService();
          await notificationService.sendNotification(
            userId: widget.userId,
            type: 'email_changed_security',
            title: '⚠️ Important Account Changes',
            body: 'Your account information was modified: $changeDetails If you did not make these changes, please secure your account immediately.',
            data: {
              'timestamp': DateTime.now().toIso8601String(),
              'changedFields': changeDetails,
            },
            sendEmail: true,
          );
        }
      } catch (e) {
        debugPrint('Failed to send security notification: $e');
      }

      // Send profile update confirmation
      try {
        final notificationService = NotificationService();
        
        // Always send profile update notification
        await notificationService.sendNotification(
          userId: widget.userId,
          type: 'profile_updated',
          title: 'Profile Updated ✅',
          body: 'Your profile has been successfully updated.',
          data: {'timestamp': DateTime.now().toIso8601String()},
          sendEmail: true,
        );

        // Check if profile is incomplete and notify user
        final isIncomplete = _isCompany
            ? (_companyNameController.text.trim().isEmpty ||
                _registrationNumberController.text.trim().isEmpty ||
                _industryController.text.trim().isEmpty)
            : (_nameController.text.trim().isEmpty ||
                _phoneController.text.trim().isEmpty ||
                _addressController.text.trim().isEmpty);

        if (isIncomplete) {
          await notificationService.sendNotification(
            userId: widget.userId,
            type: 'profile_incomplete',
            title: 'Complete Your Profile 📝',
            body: 'Your profile is incomplete. Complete it to get better job matches and recommendations.',
            data: {'missingFields': isIncomplete ? 'some' : 'none'},
          );
        } else {
          // Profile is complete - notify success
          await notificationService.sendNotification(
            userId: widget.userId,
            type: 'profile_updated',
            title: 'Profile Updated ✅',
            body: 'Your profile has been updated successfully.',
          );
        }
      } catch (e) {
        debugPrint('Error sending profile update notification: $e');
        // Don't block profile save if notification fails
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Profile updated successfully!');
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      debugPrint('Error saving profile: $error');
      if (mounted) {
        setState(() => _isLoading = false);
        
        String errorMessage = 'Failed to update profile';
        final errorString = error.toString().toLowerCase();

        if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('permission') || errorString.contains('forbidden')) {
          errorMessage = 'Permission denied. Please check your account permissions.';
        } else if (errorString.contains('storage')) {
          errorMessage = 'Failed to upload image. Please try a smaller image or different format.';
        } else if (errorString.contains('not found')) {
          errorMessage = 'User profile not found. Please try logging in again.';
        }

        SnackbarHelper.showError(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'edit_profile',
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      appBar: AppAppBar(
        title: 'Edit Profile',
        variant: AppBarVariant.standard,
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.check, color: colorScheme.tertiary),
              onPressed: _saveProfile,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Saving changes...')
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: AppTheme.spacingL),
                    
                    // Profile Image
                    _buildProfileImage(),
                    
                    SizedBox(height: AppTheme.spacingXL),

                    // Company-specific fields
                    if (_isCompany) ...[
                      AppTextField(
                        controller: _companyNameController,
                        label: 'Company Name',
                        hint: 'Enter company name',
                        prefixIcon: Icons.business,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      AppTextField(
                        controller: _registrationNumberController,
                        label: 'Registration Number',
                        hint: 'Enter registration number',
                        prefixIcon: Icons.assignment_outlined,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      AppTextField(
                        controller: _industryController,
                        label: 'Industry/Sector',
                        hint: 'Enter industry',
                        prefixIcon: Icons.work_outline,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: AppTheme.spacingM),
                    ],

                    // Common fields
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        if (value.length > 50) {
                          return 'Name must not exceed 50 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => InputValidators.validatePhone(value),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    
                    AppTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your address',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),

                    if (_isCompany) ...[
                      SizedBox(height: AppTheme.spacingM),
                      AppTextField(
                        controller: _websiteController,
                        label: 'Website (Optional)',
                        hint: 'Enter website URL',
                        prefixIcon: Icons.language,
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            return InputValidators.validateURL(value);
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      AppTextField(
                        controller: _descriptionController,
                        label: 'Company Description',
                        hint: 'Describe your company',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 4,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],

                    SizedBox(height: AppTheme.spacingXL),

                    // Save Button
                    StandardButton(
                      label: 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: _saveProfile,
                      type: StandardButtonType.primary,
                      fullWidth: true,
                      isLoading: _isLoading,
                    ),
                    
                    SizedBox(height: AppTheme.spacingL),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _newImageFile != null
                  ? Image.file(
                      _newImageFile!,
                      fit: BoxFit.cover,
                      width: 140,
                      height: 140,
                    )
                  : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _currentImageUrl!,
                          fit: BoxFit.cover,
                          width: 140,
                          height: 140,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(color: colorScheme.primary),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: AppDesignSystem.paddingS,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: colorScheme.onSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
