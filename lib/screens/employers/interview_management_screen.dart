import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/models/interview_model.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/cards/interview_card.dart';
import 'package:intl/intl.dart';
import '../employers/interview_scheduling_screen.dart';

class InterviewManagementScreen extends StatefulWidget {
  const InterviewManagementScreen({super.key});

  @override
  State<InterviewManagementScreen> createState() =>
      _InterviewManagementScreenState();
}

class _InterviewManagementScreenState extends State<InterviewManagementScreen> {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();

  List<InterviewModel> _allInterviews = [];
  List<InterviewModel> _filteredInterviews = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadInterviews();
  }

  Future<void> _loadInterviews() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final interviewsQuery = await _dbService.getUserInterviews(user.uid);
      final interviews = interviewsQuery.docs
          .map((doc) => InterviewModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Sort by scheduled date (upcoming first)
      interviews.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

      if (mounted) {
        setState(() {
          _allInterviews = interviews;
          _filterInterviews();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading interviews: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Failed to load interviews');
      }
    }
  }

  void _filterInterviews() {
    switch (_selectedFilter) {
      case 'Upcoming':
        final now = DateTime.now();
        _filteredInterviews = _allInterviews
            .where((i) =>
                i.status != 'Cancelled' &&
                i.scheduledDate.isAfter(now) &&
                i.status != 'Completed')
            .toList();
        break;
      case 'Scheduled':
        _filteredInterviews =
            _allInterviews.where((i) => i.status == 'Scheduled').toList();
        break;
      case 'Accepted':
        _filteredInterviews =
            _allInterviews.where((i) => i.status == 'Accepted').toList();
        break;
      case 'Completed':
        _filteredInterviews =
            _allInterviews.where((i) => i.status == 'Completed').toList();
        break;
      case 'Cancelled':
        _filteredInterviews =
            _allInterviews.where((i) => i.status == 'Cancelled').toList();
        break;
      case 'All':
      default:
        _filteredInterviews = _allInterviews;
    }
  }

  Future<void> _showRescheduleDialog(InterviewModel interview) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewSchedulingScreen(
          candidateId: interview.candidateId,
          candidateName: interview.candidateName,
          jobId: interview.jobId,
          jobTitle: interview.jobTitle,
        ),
      ),
    );

    if (result == true) {
      _loadInterviews();
    }
  }

  Future<void> _cancelInterview(InterviewModel interview) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel the interview with ${interview.candidateName}?',
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Interview'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dbService.updateInterview(
        interviewId: interview.interviewId,
        data: {
          'status': 'Cancelled',
          'cancel_reason': reasonController.text.isEmpty
              ? 'Cancelled by employer'
              : reasonController.text,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Notify candidate
      await _notificationService.sendNotification(
        userId: interview.candidateId,
        type: 'interview_cancelled',
        title: 'Interview Cancelled',
        body:
            'Your interview for "${interview.jobTitle}" has been cancelled.',
        data: {
          'interviewId': interview.interviewId,
          'jobId': interview.jobId,
        },
        sendEmail: true,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Interview cancelled');
        _loadInterviews();
      }
    } catch (e) {
      debugPrint('Error cancelling interview: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to cancel interview');
      }
    }
  }

  Future<void> _showInterviewDetailsDialog(InterviewModel interview) async {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          title: Text('Interview Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interview ID
                _buildDetailRow('Interview ID', interview.interviewId),
                Divider(height: AppDesignSystem.spaceL),

                // Candidate
                _buildDetailRow('Candidate', interview.candidateName),

                // Job
                _buildDetailRow('Job', interview.jobTitle),

                // Scheduled Date and Time
                _buildDetailRow(
                  'Date & Time',
                  '${DateFormat('MMM dd, yyyy').format(interview.scheduledDate)}\n${interview.scheduledDate.hour.toString().padLeft(2, '0')}:${interview.scheduledDate.minute.toString().padLeft(2, '0')}',
                ),

                // Duration
                _buildDetailRow('Duration', '${interview.durationMinutes} minutes'),

                // Interview Type and Medium
                _buildDetailRow('Type', interview.type),
                _buildDetailRow('Medium', interview.medium),

                // Location (if applicable)
                if (interview.location != null && interview.location!.isNotEmpty)
                  _buildDetailRow('Location', interview.location!),

                // Meeting Link (if available)
                if (interview.meetingLink != null && interview.meetingLink!.isNotEmpty)
                  _buildDetailRow('Meeting Link', interview.meetingLink!),

                // Status
                Divider(height: AppDesignSystem.spaceL),
                _buildDetailRow(
                  'Status',
                  interview.status,
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(context, interview.status),
                  ),
                ),

                // Notes (if available)
                if (interview.notes != null && interview.notes!.isNotEmpty) ...[
                  Divider(height: AppDesignSystem.spaceL),
                  _buildDetailRow('Notes', interview.notes!),
                ],

                // Cancel Reason (if cancelled)
                if (interview.status == 'Cancelled' &&
                    interview.cancelReason != null &&
                    interview.cancelReason!.isNotEmpty) ...[
                  Divider(height: AppDesignSystem.spaceL),
                  _buildDetailRow(
                    'Cancellation Reason',
                    interview.cancelReason!,
                    valueStyle: TextStyle(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: AppDesignSystem.spaceM),
      ],
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return colorScheme.error;
      case 'declined':
        return Colors.orange;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: {AppUserRole.employer, AppUserRole.admin},
      child: HintsWrapper(
        screenId: 'InterviewManagement',
        child: Scaffold(
          appBar: AppAppBar(
            title: 'Interview Management',
            automaticallyImplyLeading: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spaceM,
                        vertical: AppDesignSystem.spaceS,
                      ),
                      child: Row(
                        children: [
                          'All',
                          'Upcoming',
                          'Scheduled',
                          'Accepted',
                          'Completed',
                          'Cancelled',
                        ]
                            .map((filter) => Padding(
                                  padding: EdgeInsets.only(
                                    right: AppDesignSystem.spaceS,
                                  ),
                                  child: FilterChip(
                                    label: Text(filter),
                                    selected: _selectedFilter == filter,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedFilter = filter;
                                        _filterInterviews();
                                      });
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    // Interview List
                    Expanded(
                      child: _filteredInterviews.isEmpty
                          ? Center(
                              child: Text(
                                'No interviews found',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppDesignSystem.spaceM),
                              itemCount: _filteredInterviews.length,
                              separatorBuilder: (_, __) =>
                                  AppDesignSystem.verticalSpace(
                                      AppDesignSystem.spaceM),
                              itemBuilder: (context, index) {
                                final interview =
                                    _filteredInterviews[index];
                                final isUpcoming = interview
                                        .scheduledDate
                                        .isAfter(DateTime.now()) &&
                                    interview.status != 'Cancelled';
                                final hasConflict = interview.hasConflict;

                                return InterviewCard(
                                  interview: interview,
                                  isUpcoming: isUpcoming,
                                  hasConflict: hasConflict,
                                  onReschedule: () =>
                                      _showRescheduleDialog(interview),
                                  onCancel: () =>
                                      _cancelInterview(interview),
                                  onViewDetails: () {
                                    _showInterviewDetailsDialog(interview);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
