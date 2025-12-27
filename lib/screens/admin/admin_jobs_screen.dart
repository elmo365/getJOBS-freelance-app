import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _pendingJobs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPendingJobs();
  }

  Future<void> _loadPendingJobs() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final result = await _dbService
          .getCollection('jobs')
          .where('isVerified', isEqualTo: false)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _pendingJobs = result.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pendingJobs = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: botsSuperLightGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: 'Job Approvals',
        variant: AppBarVariant.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Bar
                Padding(
                  padding: AppDesignSystem.paddingVertical(AppDesignSystem.spaceL),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon:
                          Icon(Icons.search, color: colorScheme.primary),
                      filled: true,
                      fillColor: botsWhite,
                      border: OutlineInputBorder(
                        borderRadius: AppDesignSystem.borderRadiusM,
                        borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppDesignSystem.borderRadiusM,
                        borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppDesignSystem.borderRadiusM,
                        borderSide: BorderSide(
                            color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                // Jobs List (non-scrollable inside main scroll view)
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildJobList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    final filtered = _pendingJobs.where((job) {
      if (_searchQuery.isNotEmpty) {
        final title = (job['title'] as String? ?? '').toLowerCase();
        return title.contains(_searchQuery);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.work_outline,
        title: _searchQuery.isEmpty ? 'No pending jobs' : 'No results found',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingJobs,
      child: ListView.builder(
        padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
            child: _buildJobCard(filtered[index]),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final jobId = job['id'] as String;
    final jobTitle =
        job['title'] as String? ?? job['jobTitle'] as String? ?? 'Untitled';
    final employerName = job['name'] as String? ?? 'Unknown';
    final category = job['category'] as String? ?? '';
    final location = job['location'] as String? ?? '';
    final salary = job['salary'] as String? ?? '';
    final description = job['description'] as String? ?? '';
    final contactEmail = job['email'] as String? ?? '';
    final contactPhone = job['phoneNumber'] as String? ?? '';

    return AppCard(
      margin: AppDesignSystem.paddingS,
      elevation: 6,
      variant: SurfaceVariant.elevated,
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: AppDesignSystem.paddingS,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Icon(Icons.work, color: colorScheme.onSecondaryContainer),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                      Text(
                        'Employer: $employerName',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            if (description.isNotEmpty)
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            if (description.isNotEmpty)
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Wrap(
              spacing: AppDesignSystem.spaceS,
              runSpacing: AppDesignSystem.spaceS,
              children: [
                if (category.isNotEmpty)
                  _buildChip(
                    context: context,
                    icon: Icons.category,
                    label: category,
                  ),
                if (location.isNotEmpty)
                  _buildChip(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: location,
                  ),
                if (salary.isNotEmpty)
                  _buildChip(
                    context: context,
                    icon: Icons.payments_outlined,
                    label: salary,
                  ),
              ],
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            if (contactEmail.isNotEmpty || contactPhone.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (contactEmail.isNotEmpty)
                    _buildInfoRow(
                      context: context,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: contactEmail,
                    ),
                  if (contactPhone.isNotEmpty)
                    _buildInfoRow(
                      context: context,
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: contactPhone,
                    ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectJob(jobId, jobTitle),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveJob(jobId, jobTitle),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.tertiary,
                      foregroundColor: colorScheme.onTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppDesignSystem.borderRadiusS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppDesignSystem.spaceXS),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
          Text(
            '$label: ',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveJob(String jobId, String jobTitle) async {
    if (!mounted) return;

    if (!await checkConnectivity(context,
        message: 'Cannot approve job without internet.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _dbService.updateJob(
        jobId: jobId,
        data: {
          'isVerified': true,
          'status': 'active',
          'isApproved': true,
          'approvalStatus': 'approved',
          'approvedAt': DateTime.now().toIso8601String(),
          'rejectionReason': FieldValue.delete(),
        },
      );

      // Get employer info
      final jobDoc = await _dbService.getJob(jobId);
      final jobData = jobDoc?.data() as Map<String, dynamic>?;
      final employerId = jobData?['userId'] as String?;

      if (employerId != null) {
        // Send notification
        await _notificationService.sendNotification(
          userId: employerId,
          type: 'job_approval',
          title: 'Job Approved! ✅',
          body:
              'Your job posting "$jobTitle" has been approved and is now live. Job seekers can now view and apply for this position.',
          data: {'jobId': jobId, 'jobTitle': jobTitle},
          sendEmail: true,
        );
      }

      await _loadPendingJobs();

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, '✓ "$jobTitle" approved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error approving job: $e');
      debugPrint('Error approving job: $e');
    }
  }

  Future<void> _rejectJob(String jobId, String jobTitle) async {
    if (!mounted) return;

    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this job?'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Provide feedback...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          StandardButton(
            label: 'Reject',
            type: StandardButtonType.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result != true) return;

    if (!mounted) return;
    if (!await checkConnectivity(context,
        message: 'Cannot reject job without internet.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _dbService.updateJob(
        jobId: jobId,
        data: {
          'status': 'rejected',
          'isVerified': false,
          'isApproved': false,
          'approvalStatus': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
          if (reasonController.text.isNotEmpty)
            'rejectionReason': reasonController.text,
        },
      );

      // Notify employer
      final jobDoc = await _dbService.getJob(jobId);
      final jobData = jobDoc?.data() as Map<String, dynamic>?;
      final employerId = (jobData?['userId'] ?? jobData?['id'])?.toString();

      if (employerId != null && employerId.isNotEmpty) {
        await _notificationService.sendNotification(
          userId: employerId,
          type: 'job_rejected',
          title: 'Job Rejected',
          body:
              'Your job posting "$jobTitle" was rejected. Please review the reason below and edit your job posting to resubmit.',
          data: {
            'jobId': jobId,
            'jobTitle': jobTitle,
            if (reasonController.text.isNotEmpty)
              'reason': reasonController.text,
          },
          sendEmail: true,
        );
      }

      await _loadPendingJobs();

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, '✗ "$jobTitle" rejected');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error rejecting job: $e');
      debugPrint('Error rejecting job: $e');
    }
  }
}
