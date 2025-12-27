import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:freelance_app/widgets/cards/job_seeker_interview_card.dart';
import 'package:freelance_app/screens/chat/chat_screen.dart';

class InterviewManagementJobSeekerScreen extends StatefulWidget {
  final String? highlightedApplicationId;

  const InterviewManagementJobSeekerScreen({
    super.key,
    this.highlightedApplicationId,
  });

  @override
  State<InterviewManagementJobSeekerScreen> createState() =>
      _InterviewManagementJobSeekerScreenState();
}

class _InterviewManagementJobSeekerScreenState
    extends State<InterviewManagementJobSeekerScreen> {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();

  List<InterviewModel> _allInterviews = [];
  List<InterviewModel> _filteredInterviews = [];
  bool _isLoading = true;
  String _selectedFilter = 'Upcoming';

  @override
  void initState() {
    super.initState();
    _loadInterviews();
  }

  Future<void> _loadInterviews() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final query = await FirebaseFirestore.instance
          .collection('interviews')
          .where('candidate_id', isEqualTo: user.uid)
          .orderBy('scheduled_date', descending: false)
          .get();

      final interviews = query.docs
          .map((doc) => InterviewModel.fromMap(doc.data(), doc.id))
          .toList();

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
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Upcoming':
        _filteredInterviews = _allInterviews
            .where((i) =>
                i.status != 'Cancelled' &&
                i.status != 'Declined' &&
                i.scheduledDate.isAfter(now.subtract(const Duration(hours: 1))))
            .toList();
        break;
      case 'Accepted':
        _filteredInterviews =
            _allInterviews.where((i) => i.status == 'Accepted').toList();
        break;
      case 'Completed':
        _filteredInterviews =
            _allInterviews.where((i) => i.status == 'Completed').toList();
        break;
      case 'Declined':
        _filteredInterviews =
            _allInterviews.where((i) => i.status == 'Declined').toList();
        break;
      case 'All':
      default:
        _filteredInterviews = _allInterviews;
    }
  }

  Future<void> _acceptInterview(InterviewModel interview) async {
    try {
      await _dbService.updateInterview(
        interviewId: interview.interviewId,
        data: {
          'status': 'Accepted',
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      await _notificationService.sendNotification(
        userId: interview.employerId,
        type: 'interview_accepted',
        title: 'Interview Accepted',
        body:
            '${interview.candidateName} has accepted the interview for "${interview.jobTitle}".',
        data: {
          'interviewId': interview.interviewId,
          'candidateId': interview.candidateId,
        },
        sendEmail: true,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Interview accepted');
        _loadInterviews();
      }
    } catch (e) {
      debugPrint('Error accepting interview: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to accept interview');
      }
    }
  }

  Future<void> _declineInterview(InterviewModel interview) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to decline the interview for "${interview.jobTitle}"?',
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for declining (optional)',
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
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dbService.updateInterview(
        interviewId: interview.interviewId,
        data: {
          'status': 'Declined',
          'decline_reason': reasonController.text.isEmpty
              ? 'Declined by candidate'
              : reasonController.text,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      await _notificationService.sendNotification(
        userId: interview.employerId,
        type: 'interview_declined',
        title: 'Interview Declined',
        body:
            '${interview.candidateName} has declined the interview for "${interview.jobTitle}".',
        data: {
          'interviewId': interview.interviewId,
          'candidateId': interview.candidateId,
        },
        sendEmail: true,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Interview declined');
        _loadInterviews();
      }
    } catch (e) {
      debugPrint('Error declining interview: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to decline interview');
      }
    }
  }

  void _openChatWithEmployer(InterviewModel interview) {
    // Generate chatId from user IDs (sorted for consistency)
    final currentUserId = _authService.getCurrentUser()?.uid ?? '';
    final ids = [currentUserId, interview.employerId];
    ids.sort();
    final chatId = '${ids[0]}_${ids[1]}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          otherUserId: interview.employerId,
          otherUserName: interview.employerName,
        ),
      ),
    );
  }

  Future<void> _rescheduleInterview(InterviewModel interview) async {
    final rescheduleController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Reschedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact the employer to reschedule this interview for "${interview.jobTitle}".',
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: rescheduleController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Your message (optional)',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Message Employer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Open chat with optional message
      _openChatWithEmployer(interview);
      if (rescheduleController.text.isNotEmpty && mounted) {
        SnackbarHelper.showInfo(
          context,
          'Share your reschedule request in the chat',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: {AppUserRole.jobSeeker},
      child: HintsWrapper(
        screenId: 'interview_management_job_seeker',
        child: Scaffold(
          appBar: AppAppBar(
            title: 'My Interviews',
            automaticallyImplyLeading: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Filter Tabs
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDesignSystem.spaceM),
                        children: [
                          'Upcoming',
                          'All',
                          'Accepted',
                          'Completed',
                          'Declined'
                        ]
                            .map((filter) => Padding(
                                  padding: EdgeInsets.only(
                                      right: AppDesignSystem.spaceS),
                                  child: FilterChip(
                                    label: Text(filter),
                                    selected: _selectedFilter == filter,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedFilter = filter;
                                          _filterInterviews();
                                        });
                                      }
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                    // Interviews List
                    Expanded(
                      child: _filteredInterviews.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  AppDesignSystem.verticalSpace(
                                      AppDesignSystem.spaceM),
                                  Text(
                                    'No Interviews',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  AppDesignSystem.verticalSpace(
                                      AppDesignSystem.spaceS),
                                  Text(
                                    'No $_selectedFilter interviews found.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppDesignSystem.spaceM,
                                  vertical: AppDesignSystem.spaceM),
                              itemCount: _filteredInterviews.length,
                              separatorBuilder: (_, __) =>
                                  AppDesignSystem.verticalSpace(
                                      AppDesignSystem.spaceM),
                              itemBuilder: (context, index) {
                                final interview = _filteredInterviews[index];
                                final isUpcoming = interview
                                        .scheduledDate
                                        .isAfter(DateTime.now()) &&
                                    interview.status != 'Cancelled' &&
                                    interview.status != 'Declined';

                                return JobSeekerInterviewCard(
                                  interview: interview,
                                  isUpcoming: isUpcoming,
                                  onAccept: () => _acceptInterview(interview),
                                  onDecline: () => _declineInterview(interview),
                                  onReschedule: () => _rescheduleInterview(interview),
                                  onViewDetails: () {
                                    SnackbarHelper.showInfo(
                                      context,
                                      'Interview ID: ${interview.interviewId}',
                                    );
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
