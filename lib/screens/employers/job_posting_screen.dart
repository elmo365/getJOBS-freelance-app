import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/global_variables.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/services/wallet_service.dart';
import 'package:freelance_app/models/wallet_model.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class JobPostingScreen extends StatefulWidget {
  final String? jobId;
  const JobPostingScreen({super.key, this.jobId});

  @override
  State<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<JobPostingScreen>
    with ConnectivityAware {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _positionsController = TextEditingController(text: '1');
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();
  String? _selectedCategory;
  String? _selectedJobType;
  String? _selectedExperienceLevel;
  DateTime? _deadlineDate;
  bool _isLoading = false;
  bool _isEdit = false;
  String? _editingJobId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _positionsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      _isEdit = true;
      _editingJobId = widget.jobId;
      _loadJobForEdit(widget.jobId!);
    }
  }

  Future<void> _loadJobForEdit(String jobId) async {
    try {
      final doc = await _dbService.getJob(jobId);
      if (doc == null) return;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      setState(() {
        _titleController.text = (data['title'] ?? '') as String;
        _descriptionController.text = (data['description'] ?? '') as String;
        _locationController.text = (data['location'] ?? data['address'] ?? '') as String;
        _salaryController.text = (data['salary'] ?? '') as String;
        _positionsController.text = (data['positionsAvailable']?.toString() ?? '1');
        _selectedCategory = (data['category'] ?? data['jobCategory']) as String?;
        _selectedJobType = data['jobType'] as String?;
        _selectedExperienceLevel = data['experienceLevel'] as String?;
        if (data['deadlineDate'] != null) {
          try {
            _deadlineDate = DateTime.tryParse(data['deadlineDate']);
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Failed to load job for edit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RoleGuard(
      allow: const {AppUserRole.employer},
      title: 'Employer only',
      message: 'Only employer accounts can post jobs.',
      child: HintsWrapper(
        screenId: 'job_posting',
        child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppAppBar(
          title: 'Post a Job',
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
                  'Job Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                _buildModernTextField(
                  controller: _titleController,
                  label: 'Job Title *',
                  prefixIcon: Icons.work,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter job title';
                    }
                    return null;
                  },
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    prefixIcon:
                        Icon(Icons.category, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  items: jobCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildModernTextField(
                  controller: _descriptionController,
                  label: 'Job Description *',
                  prefixIcon: Icons.description,
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter job description';
                    }
                    return null;
                  },
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildModernTextField(
                  controller: _locationController,
                  label: 'Location',
                  prefixIcon: Icons.location_on,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildModernTextField(
                  controller: _salaryController,
                  label: 'Salary Range (BWP Pula)',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return InputValidators.validateSalary(value);
                    }
                    return null;
                  },
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                DropdownButtonFormField<String>(
                  initialValue: _selectedJobType,
                  decoration: InputDecoration(
                    labelText: 'Job Type',
                    prefixIcon:
                        Icon(Icons.schedule, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  items: const [
                    DropdownMenuItem(
                        value: 'Full-time', child: Text('Full-time')),
                    DropdownMenuItem(
                        value: 'Part-time', child: Text('Part-time')),
                    DropdownMenuItem(
                        value: 'Contract', child: Text('Contract')),
                    DropdownMenuItem(
                        value: 'Internship', child: Text('Internship')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedJobType = value;
                    });
                  },
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                DropdownButtonFormField<String>(
                  initialValue: _selectedExperienceLevel,
                  decoration: InputDecoration(
                    labelText: 'Experience Level',
                    prefixIcon:
                        Icon(Icons.trending_up, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  items: const [
                    DropdownMenuItem(
                        value: 'Entry', child: Text('Entry Level')),
                    DropdownMenuItem(value: 'Mid', child: Text('Mid Level')),
                    DropdownMenuItem(
                        value: 'Senior', child: Text('Senior Level')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedExperienceLevel = value;
                    });
                  },
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildModernTextField(
                  controller: _positionsController,
                  label: 'Number of Positions',
                  prefixIcon: Icons.people,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of positions';
                    }
                    final positions = int.tryParse(value);
                    if (positions == null || positions < 1) {
                      return 'Number of positions must be at least 1';
                    }
                    return null;
                  },
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _deadlineDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Application Deadline',
                      prefixIcon: Icon(Icons.calendar_today,
                          color: colorScheme.primary),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Text(
                      _deadlineDate != null
                          ? '${_deadlineDate!.day}/${_deadlineDate!.month}/${_deadlineDate!.year}'
                          : 'Select deadline',
                      style: TextStyle(
                        color: _deadlineDate != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _postJob,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppDesignSystem.surface(context),
                          ),
                        )
                      : Icon(_isEdit ? Icons.save : Icons.post_add),
                  label: Text(
                    _isLoading ? (_isEdit ? 'Updating...' : 'Posting...') : (_isEdit ? 'Update Job' : 'Post Job'),
                    style: theme.textTheme.labelLarge,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
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

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await checkConnectivity(context,
        message:
            'Cannot post job without internet. Please connect and try again.')) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Please login to post jobs');
        }
        return;
      }

      // Check if user is a company and if they're approved
      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'User profile not found');
        }
        return;
      }
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final isCompany = userData['isCompany'] == true;
      final isApproved = userData['isApproved'] == true;
      // Track current approval status for messaging
      final approvalStatus = userData['approvalStatus'] as String? ?? 'pending';

      final employerName =
          (userData['company_name'] as String?)?.trim().isNotEmpty == true
              ? (userData['company_name'] as String).trim()
              : (userData['name'] as String?)?.trim() ?? '';
      final employerImage = (userData['user_image'] as String?) ??
          (userData['userImage'] as String?) ??
          '';
      final employerEmail = (userData['email'] as String?) ?? user.email ?? '';

      // Note: All users can post jobs, but they require admin approval
      // Companies still need to be approved to post jobs
      if (isCompany && !isApproved) {
        if (mounted) {
          String message;
          if (approvalStatus == 'pending') {
            message =
                'Your company account is pending approval. You cannot post jobs until your company is approved by an admin.';
          } else if (approvalStatus == 'rejected') {
            message =
                'Your company account was rejected. Please contact support for more information.';
          } else {
            message =
                'Your company account is not approved. Status: $approvalStatus';
          }
          SnackbarHelper.showError(context, message);
        }
        return;
      }

      // Monetization & Tiered Pricing (Ethical Balance)
      final walletService = WalletService();
      final settings = await walletService.getSettings();

      // Select Base Rate
      double baseCost = isCompany
          ? settings.companyJobPostFee
          : settings.individualJobPostFee;

      // Determine if monetization applies
      bool monetizationActive = isCompany
          ? settings.isCompanyMonetizationEnabled
          : settings.isIndividualMonetizationEnabled;

      // Apply Global Discount (Promotions)
      double discountAmount = 0.0;
      if (settings.globalDiscountPercentage > 0) {
        discountAmount = baseCost * (settings.globalDiscountPercentage / 100);
      }
      double finalCost = baseCost - discountAmount;
      if (finalCost < 0) finalCost = 0;

      if (monetizationActive && finalCost > 0) {
        // Show confirmation dialog before proceeding
        bool proceed = false;
        if (mounted) {
          proceed = await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Payment'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Posting cost: ${CurrencyFormatter.formatBWP(finalCost)}'),
                      if (discountAmount > 0)
                        Text(
                            '(Includes ${settings.globalDiscountPercentage.toStringAsFixed(0)}% Promo Discount)',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary, fontSize: 12)),
                      if (!isCompany)
                        Text('(Individual Rate Applied)',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.outlineVariant,
                                fontSize: 12)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Pay & Post'),
                    ),
                  ],
                ),
              ) ??
              false;
        }

        if (!proceed) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        try {
          await walletService.spendCredits(
            userId: user.uid,
            amount: finalCost,
            type: TransactionType.jobFee,
            description:
                'Fee for posting job: ${_titleController.text} ${discountAmount > 0 ? "(Promo)" : ""}',
          );
        } catch (e) {
          if (mounted) {
            String errorMsg = e.toString();
            if (errorMsg.contains('Insufficient')) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Insufficient Credits'),
                  content: Text(
                      'You need ${CurrencyFormatter.formatBWP(finalCost)} to post a job.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'))
                  ],
                ),
              );
            } else {
              SnackbarHelper.showError(context, 'Payment Failed: $errorMsg');
            }
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      final positionsAvailable = int.tryParse(_positionsController.text) ?? 1;

      final jobData = {
        'userId': user.uid,
        // Backwards/forwards compatibility across screens.
        'id': user.uid,
        'name': employerName,
        'employerName': employerName,
        'user_image': employerImage,
        'email': employerEmail,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory ?? '',
        'jobCategory': _selectedCategory ?? '',
        'location': _locationController.text.trim(),
        'address': _locationController.text.trim(),
        'salary': _salaryController.text.trim(),
        'jobType': _selectedJobType ?? 'Full-time',
        'experienceLevel': _selectedExperienceLevel ?? 'Entry',
        'deadlineDate': _deadlineDate?.toIso8601String(),
        'status': 'pending', // All jobs require admin approval
        'isVerified': false, // All jobs require admin verification
        'createdAt': DateTime.now().toIso8601String(),
        'isApproved': false, // All jobs require admin approval
        'approvalStatus': 'pending',
        'positionsAvailable': positionsAvailable,
        'positionsFilled': 0,
        'hiredApplicants': [],
      };

      late final String jobId;
      if (_isEdit && _editingJobId != null) {
        // Update existing job
        jobData['updatedAt'] = DateTime.now().toIso8601String();
        await _dbService.updateJob(jobId: _editingJobId!, data: jobData);
        jobId = _editingJobId!;
      } else {
        final jobDoc = await _dbService.createJob(jobData);
        jobId = jobDoc.id;
      }

      // Schedule deadline reminder if deadline is set
      if (_deadlineDate != null && _deadlineDate!.isAfter(DateTime.now())) {
        try {
          // Schedule reminder 3 days before deadline
          final reminderDate = _deadlineDate!.subtract(const Duration(days: 3));
          if (reminderDate.isAfter(DateTime.now())) {
            await FirebaseFirestore.instance.collection('scheduled_notifications').add({
              'userId': user.uid,
              'type': 'job_deadline_approaching',
              'title': 'Job Deadline Approaching ⏰',
              'body': 'Your job "${_titleController.text.trim()}" deadline is approaching in 3 days.',
              'scheduledFor': reminderDate.toIso8601String(),
              'data': {
                'jobId': jobId,
                'jobTitle': _titleController.text.trim(),
                'deadline': _deadlineDate!.toIso8601String(),
              },
              'createdAt': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Error scheduling deadline reminder: $e');
        }
      }

      // Notify employer (confirmation)
      try {
        await _notificationService.sendNotification(
          userId: user.uid,
          type: 'job_posted',
          title: 'Job Submitted for Review ✅',
          body:
              'Your job "${_titleController.text.trim()}" has been submitted and is pending admin approval. You will be notified once it\'s approved.',
          data: {'jobId': jobId, 'jobTitle': _titleController.text.trim()},
          sendEmail: true,
        );
      } catch (e) {
        debugPrint('Error sending job posting confirmation: $e');
        // Best-effort; do not block job posting
      }

      // Send notification to admin for all job postings
      try {
        // Get admin users (users with isAdmin = true)
        final admins = await _dbService.getAdminUsers(limit: 100);
        for (var adminDoc in admins.docs) {
            await _notificationService.sendNotification(
              userId: adminDoc.id,
              type: 'job_pending_approval',
              title: 'New Job Pending Approval',
              body:
                  '${isCompany ? "Company" : "User"} "$employerName" submitted a new job "${_titleController.text.trim()}" for review.',
              data: {
                'jobId': jobId,
                'employerId': user.uid,
                'jobTitle': _titleController.text.trim()
              },
              sendEmail: true,
            );
        }
      } catch (e) {
        debugPrint('Error sending admin notifications: $e');
        // Best-effort; do not block job posting
      }

      if (mounted) {
        // Show success and navigation logic...
        SnackbarHelper.showSuccess(context, 'Job Posted Successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to post job';
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('network') ||
            errorString.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('permission') ||
            errorString.contains('forbidden')) {
          errorMessage =
              'Permission denied. Please check your account permissions or contact support.';
        } else if (errorString.contains('validation') ||
            errorString.contains('invalid')) {
          errorMessage =
              'Invalid job data. Please check all fields and try again.';
        } else if (errorString.contains('not found')) {
          errorMessage = 'Database error. Please try again or contact support.';
        }

        SnackbarHelper.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: colorScheme.primary,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
      ),
    );
  }
}
