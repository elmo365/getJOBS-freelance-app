import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/page_transitions.dart';
import 'package:freelance_app/screens/notifications/notifications_screen.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/screens/homescreen/sidebar.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'job_posting_screen.dart';
import 'job_management_screen.dart';
import 'application_management_screen.dart';
import 'candidate_suggestions_screen.dart';
import 'interview_scheduling_screen.dart';
import 'interview_management_screen.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/screens/plugins_hub/plugins_hub.dart'
    show PluginsHub;
import 'company_verification_screen.dart';
import 'completed_jobs_screen.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/ui/modern_search_bar.dart';
import 'package:freelance_app/widgets/ui/portfolio_section.dart';
import 'package:freelance_app/widgets/ui/section_header.dart';
import 'package:freelance_app/widgets/ui/category_rail.dart';
import 'package:freelance_app/utils/colors.dart';

class EmployersHomeScreen extends StatefulWidget {
  const EmployersHomeScreen({super.key});

  @override
  State<EmployersHomeScreen> createState() => _EmployersHomeScreenState();
}

class _EmployersHomeScreenState extends State<EmployersHomeScreen> {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();
  int _activeJobsCount = 0;
  int _applicationsCount = 0;
  int _interviewsCount = 0;
  String? _userId;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentActivities = [];

  Stream<int> _getUnreadCount() {
    if (_userId == null) {
      return Stream.value(0);
    }
    return _notificationService.getUnreadCount(_userId!);
  }

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadStats();
  }

  Future<void> _loadUserId() async {
    final user = _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  Future<Map<String, dynamic>> _getVerificationMessage() async {
    try {
      // Try to get verification message from config or user's country
      final userDoc = await _dbService.getUser(_userId ?? '');
      final userData = userDoc?.data() as Map<String, dynamic>?;
      final country = userData?['country'] as String? ??
          userData?['location'] as String? ??
          '';

      // Return country-specific message if available
      if (country.toLowerCase().contains('botswana')) {
        return {'message': 'Upload CIPA/BURS documents to get approved.'};
      }
      return {'message': 'Upload verification documents to get approved.'};
    } catch (e) {
      return {'message': 'Upload verification documents to get approved.'};
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final userDoc = await _dbService.getUser(user.uid);
      _userData = userDoc?.data() as Map<String, dynamic>?;

      // Load active jobs count - filter for active jobs only
      final jobsQuery = await _dbService.getUserJobs(user.uid);

      // Filter for active jobs only
      final activeJobs = jobsQuery.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final status = data['status'] as String? ??
            data['jobStatus'] as String? ??
            'active';
        return status.toLowerCase() == 'active';
      }).toList();

      // Applications count (sum applicants across active employer jobs only)
      int applicationsTotal = 0;
      for (final doc in activeJobs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final applicants = data['applicants'];
        if (applicants is int) {
          applicationsTotal += applicants;
        } else if (applicants is num) {
          applicationsTotal += applicants.toInt();
        }
      }

      // Count interviews
      final interviewsQuery = await _dbService.getUserInterviews(user.uid);

      // Load recent activities (use active jobs only)
      _recentActivities =
          await _buildRecentActivities(activeJobs, interviewsQuery.docs);

      if (mounted) {
        setState(() {
          _activeJobsCount = activeJobs.length;
          _applicationsCount = applicationsTotal;
          _interviewsCount = interviewsQuery.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      // Show error to user if it's a critical issue
      if (mounted) {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission') ||
            errorString.contains('forbidden')) {
          // Critical: user may not have proper access
          // Note: Consider showing a snackbar here if needed
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RoleGuard(
      allow: const {AppUserRole.employer},
      child: HintsWrapper(
        screenId: 'employers_home',
        child: Scaffold(
          backgroundColor: botsSuperLightGrey, // Match Job Seeker Dashboard
          drawer: const SideBar(),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    // Top Section: Search & Menu - Match Job Seeker Dashboard
                    Padding(
                      padding: AppDesignSystem.paddingSymmetric(
                        horizontal: AppDesignSystem.spaceL,
                        vertical: AppDesignSystem.spaceM,
                      ),
                      child: Row(
                        children: [
                          // Menu Button
                          Container(
                            decoration: BoxDecoration(
                              color: botsWhite,
                              borderRadius: AppDesignSystem.borderRadiusM,
                              boxShadow: AppDesignSystem.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              color: botsTextPrimary,
                            ),
                          ),
                          AppDesignSystem.horizontalSpace(
                              AppDesignSystem.spaceM),
                          // Modern Search
                          Expanded(
                            child: StreamBuilder<int>(
                              stream: _getUnreadCount(),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return ModernSearchBar(
                                  hintText: 'Search jobs, candidates...',
                                  onTap: () {
                                    // Navigate to search screen
                                    Navigator.pushNamed(
                                      context,
                                      '/search',
                                      arguments: {'type': 'employer'},
                                    );
                                  },
                                  showNotification: true,
                                  notificationCount: count,
                                  onNotificationTap: () {
                                    context.pushModern(
                                      page: const NotificationsScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((_userData?['isCompany'] == true) &&
                                ((_userData?['approvalStatus'] as String?) ??
                                        'pending') !=
                                    'approved') ...[
                              AppCard(
                                variant: SurfaceVariant.elevated,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Company verification required',
                                            style: AppDesignSystem.titleMedium(
                                                    context)
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppDesignSystem.spaceXS),
                                          FutureBuilder<Map<String, dynamic>>(
                                            future: _getVerificationMessage(),
                                            builder: (context, snapshot) {
                                              final message = snapshot
                                                          .data?['message']
                                                      as String? ??
                                                  'Upload verification documents to get approved.';
                                              return Text(
                                                message,
                                                style:
                                                    AppDesignSystem.bodySmall(
                                                            context)
                                                        .copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                        width: AppDesignSystem.spaceM),
                                    FilledButton.icon(
                                      onPressed: () {
                                        context.pushModern(
                                          page:
                                              const CompanyVerificationScreen(),
                                          type: RouteType.fadeSlide,
                                        );
                                      },
                                      icon: const Icon(Icons.verified_user),
                                      label: Text(
                                        'Verify',
                                        style:
                                            AppDesignSystem.buttonText(context),
                                      ),
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppDesignSystem.radiusM),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDesignSystem.spaceL),
                            ],
                            // Stats Section - Use PortfolioSection like Job Seeker Dashboard "My Portfolio"
                            PortfolioSection(
                              title: 'Dashboard',
                              items: [
                                PortfolioCardData(
                                  title: 'Active Jobs',
                                  value: _activeJobsCount.toString(),
                                  subtitle: 'Posted jobs',
                                  icon: Icons.work,
                                  iconColor: AppDesignSystem.brandBlue,
                                  onTap: () {
                                    context.pushModern(
                                      page: const JobManagementScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                  },
                                ),
                                PortfolioCardData(
                                  title: 'Applications',
                                  value: _applicationsCount.toString(),
                                  subtitle: 'Received',
                                  icon: Icons.people,
                                  iconColor: AppDesignSystem.brandYellow,
                                  onTap: () {
                                    context.pushModern(
                                      page: const ApplicationManagementScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                  },
                                ),
                                PortfolioCardData(
                                  title: 'Interviews',
                                  value: _interviewsCount.toString(),
                                  subtitle: 'Scheduled',
                                  icon: Icons.calendar_today,
                                  iconColor: AppDesignSystem.brandGreen,
                                  onTap: () {
                                    context.pushModern(
                                      page: const InterviewManagementScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                  },
                                ),
                                PortfolioCardData(
                                  title: 'Completed Jobs',
                                  value: 'View',
                                  subtitle: 'Rate applicants',
                                  icon: Icons.check_circle,
                                  iconColor: AppDesignSystem.brandGreen,
                                  onTap: () {
                                    context.pushModern(
                                      page: const CompletedJobsScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                  },
                                ),
                              ],
                            ),

                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceXL),

                            // Quick Actions Section - Use SectionHeader + CategoryRail like Job Seeker Dashboard "Tools"
                            SectionHeader(title: 'Quick Actions'),
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceM),
                            CategoryRail(
                              items: [
                                CategoryItem(
                                  id: 'post_job',
                                  label: 'Post Job',
                                  icon: Icons.add_business,
                                  color: AppDesignSystem.brandBlue,
                                ),
                                CategoryItem(
                                  id: 'ai_suggestions',
                                  label: 'AI Suggestions',
                                  icon: Icons.auto_awesome,
                                  color: AppDesignSystem.brandGreen,
                                ),
                                CategoryItem(
                                  id: 'schedule_interview',
                                  label: 'Schedule Interview',
                                  icon: Icons.calendar_today,
                                  color: AppDesignSystem.brandBlue,
                                ),
                                CategoryItem(
                                  id: 'plugins',
                                  label: 'Plugins',
                                  icon: Icons.extension,
                                  color: AppDesignSystem.brandGreen,
                                ),
                              ],
                              onItemSelected: (id) {
                                switch (id) {
                                  case 'post_job':
                                    context.pushModern(
                                      page: const JobPostingScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                    break;
                                  case 'ai_suggestions':
                                    context.pushModern(
                                      page: const CandidateSuggestionsScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                    break;
                                  case 'schedule_interview':
                                    context.pushModern(
                                      page: const InterviewSchedulingScreen(),
                                      type: RouteType.fadeSlide,
                                    );
                                    break;
                                  case 'plugins':
                                    context.pushModern(
                                      page: const PluginsHub(),
                                      type: RouteType.fadeSlide,
                                    );
                                    break;
                                }
                              },
                            ),

                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceXL),

                            // Recent Activity Section
                            Padding(
                              padding: AppDesignSystem.paddingHorizontal(
                                  AppDesignSystem.spaceL),
                              child: _buildRecentActivity(),
                            ),

                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceXL),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Stats are now handled by PortfolioSection in build method

  Future<List<Map<String, dynamic>>> _buildRecentActivities(
    List<QueryDocumentSnapshot> jobs,
    List<QueryDocumentSnapshot> interviews,
  ) async {
    final activities = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Add recent interviews
    for (final doc in interviews.take(3)) {
      final data = doc.data() as Map<String, dynamic>?;
      final scheduledDate = data?['scheduledDate'];
      final jobTitle = data?['jobTitle'] as String? ??
          data?['job_title'] as String? ??
          data?['title'] as String? ??
          'Position';

      DateTime? scheduledDateTime;
      if (scheduledDate is Timestamp) {
        scheduledDateTime = scheduledDate.toDate();
      } else if (scheduledDate is String) {
        scheduledDateTime = DateTime.tryParse(scheduledDate);
      }

      String timeAgo = 'Recently';
      if (scheduledDateTime != null) {
        final difference = now.difference(scheduledDateTime);
        if (difference.inDays > 0) {
          timeAgo =
              '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
        } else if (difference.inHours > 0) {
          timeAgo =
              '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
        }
      }

      activities.add({
        'icon': Icons.calendar_today,
        'title': 'Interview scheduled',
        'subtitle': '$jobTitle - $timeAgo',
        'color': AppDesignSystem.brandBlue,
        'timeAgo': timeAgo,
      });
    }

    // Add recent job applications
    for (final jobDoc in jobs.take(2)) {
      final jobData = jobDoc.data() as Map<String, dynamic>?;
      final jobTitle = (jobData?['title'] ?? 'Job').toString();
      final applicants = (jobData?['applicants'] as int?) ?? 0;

      if (applicants > 0) {
        activities.add({
          'icon': Icons.person_add,
          'title': 'New application received',
          'subtitle':
              '$jobTitle ($applicants ${applicants == 1 ? 'application' : 'applications'})',
          'color': AppDesignSystem.brandYellow,
          'timeAgo': 'Recently',
        });
      }
    }

    return activities.take(5).toList();
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppDesignSystem.headlineSmall(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
        if (_recentActivities.isEmpty)
          AppCard(
            variant: SurfaceVariant.standard,
            child: Padding(
              padding: AppDesignSystem.paddingL,
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Text(
                    'No recent activity',
                    style: AppDesignSystem.bodyMedium(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    'Post your first job to see activity here',
                    style: AppDesignSystem.bodySmall(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentActivities.map((activity) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
              child: AppCard(
                variant: SurfaceVariant.standard,
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    padding: AppDesignSystem.paddingS,
                    decoration: BoxDecoration(
                      color:
                          (activity['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: AppDesignSystem.borderRadiusS,
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['color'] as Color,
                    ),
                  ),
                  title: Text(
                    activity['title'] as String,
                    style: AppDesignSystem.titleSmall(context),
                  ),
                  subtitle: Text(
                    activity['subtitle'] as String,
                    style: AppDesignSystem.bodySmall(context),
                  ),
                  trailing: Text(
                    activity['timeAgo'] as String,
                    style: AppDesignSystem.bodySmall(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
