import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class GigPostingScreen extends StatefulWidget {
  const GigPostingScreen({super.key});

  @override
  State<GigPostingScreen> createState() => _GigPostingScreenState();
}

class _GigPostingScreenState extends State<GigPostingScreen>
    with ConnectivityAware {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();
  final _firestore = FirebaseFirestore.instance;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Development',
    'Design',
    'Writing',
    'Marketing',
    'Business',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return HintsWrapper(
      screenId: 'gig_posting_screen',
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: 'Post a Gig',
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AppDesignSystem.paddingL,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gig Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Gig Title *',
                  prefixIcon: Icon(Icons.work, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: AppDesignSystem.borderRadiusM,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter gig title';
                  }
                  return null;
                },
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: AppDesignSystem.borderRadiusM,
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: AppDesignSystem.borderRadiusM,
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select category';
                  }
                  return null;
                },
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (BWP) *',
                  prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: AppDesignSystem.borderRadiusM,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  return InputValidators.validateCurrency(value);
                },
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              TextFormField(
                controller: _deliveryTimeController,
                decoration: InputDecoration(
                  labelText: 'Delivery Time (e.g., "3 days", "1 week") *',
                  prefixIcon: Icon(Icons.access_time, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: AppDesignSystem.borderRadiusM,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter delivery time';
                  }
                  return null;
                },
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
              FilledButton.icon(
                onPressed: _isLoading ? null : _postGig,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppDesignSystem.surface(context),
                        ),
                      )
                    : const Icon(Icons.post_add),
                label: Text(
                  _isLoading ? 'Posting...' : 'Post Gig',
                  style: theme.textTheme.labelLarge,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDesignSystem.borderRadiusM,
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

  Future<void> _postGig() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await checkConnectivity(context,
        message: 'Cannot post gig without internet. Please connect and try again.')) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Please login to post gigs');
        }
        return;
      }

      // Get user info
      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'User profile not found');
        }
        return;
      }
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final userName = (userData['name'] as String?) ?? 
                       (userData['company_name'] as String?) ?? 
                       user.email ?? 'User';
      final userImage = (userData['user_image'] as String?) ?? 
                        (userData['userImage'] as String?) ?? '';

      final gigData = {
        'userId': user.uid,
        'creatorId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory ?? '',
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'deliveryTime': _deliveryTimeController.text.trim(),
        'freelancerName': userName,
        'freelancerImage': userImage,
        'status': 'pending', // Requires admin approval
        'approvalStatus': 'pending',
        'isApproved': false,
        'isVerified': false,
        'isActive': false,
        'rating': 0.0,
        'totalOrders': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('gigs').add(gigData);

      // Notify user
      await _notificationService.sendNotification(
        userId: user.uid,
        type: 'gig_posted',
        title: 'Gig Submitted for Review ✅',
        body: 'Your gig "${_titleController.text.trim()}" has been submitted and is pending admin approval. You will be notified once it\'s approved.',
        data: {'gigTitle': _titleController.text.trim()},
        sendEmail: true,
      );

      // Notify admins
      try {
        final admins = await _dbService.getAdminUsers(limit: 100);
        for (var adminDoc in admins.docs) {
          await _notificationService.sendNotification(
            userId: adminDoc.id,
            type: 'gig_pending_approval',
            title: 'New Gig Pending Approval',
            body: 'User "$userName" submitted a new gig "${_titleController.text.trim()}" for review.',
            data: {'gigTitle': _titleController.text.trim(), 'creatorId': user.uid},
            sendEmail: true,
          );
        }
      } catch (e) {
        debugPrint('Error sending admin notifications: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showSuccess(
          context,
          'Gig submitted successfully! It will be reviewed by an admin.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error posting gig: $e');
      }
      debugPrint('Error posting gig: $e');
    }
  }
}
