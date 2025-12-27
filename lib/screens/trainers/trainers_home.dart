import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/screens/homescreen/sidebar.dart';
import 'package:freelance_app/screens/notifications/notifications_screen.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/screens/plugins_hub/plugins_hub.dart'
    show PluginsHub;
import 'courses_screen.dart';
import 'live_sessions_screen.dart';
import 'package:freelance_app/widgets/cards/feature_card.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class TrainersHomeScreen extends StatefulWidget {
  const TrainersHomeScreen({super.key});

  @override
  State<TrainersHomeScreen> createState() => _TrainersHomeScreenState();
}

class _TrainersHomeScreenState extends State<TrainersHomeScreen> {
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();
  final _firestore = FirebaseFirestore.instance;
  String? _userId;

  bool _loading = true;
  int _coursesCount = 0;
  int _studentsCount = 0;
  double _ratingAvg = 0;
  List<Map<String, dynamic>> _recentCourses = const [];
  List<Map<String, dynamic>> _upcomingSessions = const [];

  Stream<int> _getUnreadCount() {
    if (_userId == null) {
      return Stream.value(0);
    }
    return _notificationService.getUnreadCount(_userId!);
  }

  @override
  void initState() {
    super.initState();
    final user = _authService.getCurrentUser();
    _userId = user?.uid;
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final uid = _userId;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      final coursesSnap = await _firestore
          .collection('courses')
          .where('trainerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      int studentsTotal = 0;
      double ratingSum = 0;
      int ratingCount = 0;

      final courses = coursesSnap.docs.map((d) {
        final data = d.data();
        final enrolled = data['enrolledCount'];
        if (enrolled is int) studentsTotal += enrolled;
        if (enrolled is num) studentsTotal += enrolled.toInt();

        final rating = data['ratingAvg'];
        if (rating is num) {
          ratingSum += rating.toDouble();
          ratingCount += 1;
        }

        return {
          'id': d.id,
          'title': (data['title'] ?? '').toString(),
          'students': (data['enrolledCount'] ?? 0),
          'createdAt': data['createdAt'],
          'status': (data['status'] ?? '').toString(),
        };
      }).toList(growable: false);

      final now = Timestamp.fromDate(DateTime.now());
      final sessionsSnap = await _firestore
          .collection('live_sessions')
          .where('trainerId', isEqualTo: uid)
          .where('startsAt', isGreaterThanOrEqualTo: now)
          .orderBy('startsAt', descending: false)
          .limit(5)
          .get();

      final sessions = sessionsSnap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'title': (data['title'] ?? '').toString(),
          'startsAt': data['startsAt'],
          'participants': (data['participantsCount'] ?? 0),
        };
      }).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _coursesCount = courses.length;
        _studentsCount = studentsTotal;
        _ratingAvg = ratingCount == 0 ? 0 : (ratingSum / ratingCount);
        _recentCourses = courses.take(3).toList(growable: false);
        _upcomingSessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Trainer dashboard load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return RoleGuard(
      allow: const {AppUserRole.trainer},
      child: HintsWrapper(
        screenId: 'trainers_home',
        child: Scaffold(
        drawer: const SideBar(),
        appBar: AppAppBar(
          title: 'Trainer Dashboard',
          variant: AppBarVariant.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboard,
              tooltip: 'Refresh',
            ),
            StreamBuilder<int>(
              stream: _getUnreadCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  label: count > 0 ? Text(count.toString()) : null,
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: LoadingWidget(message: 'Loading your dashboard...'),
              )
            : SingleChildScrollView(
                padding: AppDesignSystem.paddingM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Row(
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.video_library,
                            title: 'My Courses',
                            subtitle: 'Manage content',
                            accentColor: colorScheme.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CoursesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.live_tv,
                            title: 'Live Sessions',
                            subtitle: 'Go live',
                            accentColor: colorScheme.tertiary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LiveSessionsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Row(
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.extension,
                            title: 'Plugins',
                            subtitle: 'Extend features',
                            accentColor: colorScheme.secondary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PluginsHub(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                    _buildRecentActivity(),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Courses',
            value: _coursesCount.toString(),
            icon: Icons.video_library,
            color: colorScheme.primary,
          ),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
        Expanded(
          child: _StatCard(
            title: 'Students',
            value: _studentsCount.toString(),
            icon: Icons.people,
            color: colorScheme.tertiary,
          ),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
        Expanded(
          child: _StatCard(
            title: 'Rating',
            value: _ratingAvg == 0 ? '—' : _ratingAvg.toStringAsFixed(1),
            icon: Icons.star,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasCourses = _recentCourses.isNotEmpty;
    final hasSessions = _upcomingSessions.isNotEmpty;

    if (!hasCourses && !hasSessions) {
      return EmptyState(
        icon: Icons.school_outlined,
        title: 'No trainer activity yet',
        message:
            'Create your first course or schedule a live session to start building your audience.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
        if (hasCourses) ...[
          Text(
            'Recent Courses',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          ..._recentCourses.map((c) {
            final title = (c['title']?.toString() ?? '').trim();
            final students = c['students'];
            final studentsText = (students is num)
                ? students.toInt()
                : (int.tryParse(students?.toString() ?? '') ?? 0);
            return Padding(
              padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
              child: AppCard(
                padding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoursesScreen(),
                    ),
                  );
                },
                child: ListTile(
                  leading: Icon(
                    Icons.video_library_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    title.isEmpty ? 'Course' : title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '$studentsText students enrolled',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }),
        ],
        if (hasSessions) ...[
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            'Upcoming Sessions',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          ..._upcomingSessions.map((s) {
            final title = (s['title']?.toString() ?? '').trim();
            final startsAt = s['startsAt'];
            final date = (startsAt is Timestamp)
                ? startsAt.toDate()
                : DateTime.tryParse(startsAt?.toString() ?? '');
            final when = date == null
                ? 'Scheduled'
                : '${date.day}/${date.month}/${date.year}';

            return Padding(
              padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
              child: AppCard(
                padding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiveSessionsScreen(),
                    ),
                  );
                },
                child: ListTile(
                  leading: Icon(
                    Icons.live_tv,
                    color: colorScheme.tertiary,
                  ),
                  title: Text(
                    title.isEmpty ? 'Live session' : title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    when,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800, color: color),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
          Text(
            title,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
