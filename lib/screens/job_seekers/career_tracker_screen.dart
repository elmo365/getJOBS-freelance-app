import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class CareerTrackerScreen extends StatefulWidget {
  const CareerTrackerScreen({super.key});

  @override
  State<CareerTrackerScreen> createState() => _CareerTrackerScreenState();
}

class _CareerTrackerScreenState extends State<CareerTrackerScreen> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  int _applicationsCount = 0;
  int _interviewsCount = 0;
  int _offersCount = 0;
  bool _loading = true;
  List<int> _applicationsOverTime = [];
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      // Load applications count
      final applications = await _dbService.getApplicationsByUser(userId: user.uid);
      _applicationsCount = applications.docs.length;

      // Count interviews (applications with interview scheduled)
      int interviews = 0;
      int offers = 0;
      for (final doc in applications.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final status = (data?['status'] ?? '').toString().toLowerCase();
        if (status.contains('interview')) {
          interviews++;
        }
        if (status.contains('offer') || status.contains('accepted')) {
          offers++;
        }
      }

      // Also check interviews collection (for candidates)
      try {
        final interviewsQuery = await _dbService.getInterviewsForCandidate(candidateId: user.uid);
        _interviewsCount = interviews + interviewsQuery.docs.length;
      } catch (e) {
        _interviewsCount = interviews;
      }

      _offersCount = offers;

      // Calculate applications over time (last 6 months)
      _applicationsOverTime = _calculateApplicationsOverTime(applications.docs);

      // Load recent activities
      _recentActivities = _buildRecentActivities(applications.docs);

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading career stats: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<int> _calculateApplicationsOverTime(List<QueryDocumentSnapshot> applications) {
    final now = DateTime.now();
    final months = <int>[];
    
    for (int i = 5; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1);
      
      int count = 0;
      for (final doc in applications) {
        final data = doc.data() as Map<String, dynamic>?;
        final appliedAt = data?['appliedAt'];
        if (appliedAt == null) continue;
        
        DateTime? appliedDate;
        if (appliedAt is Timestamp) {
          appliedDate = appliedAt.toDate();
        } else if (appliedAt is String) {
          appliedDate = DateTime.tryParse(appliedAt);
        }
        
        if (appliedDate != null && 
            appliedDate.isAfter(monthStart) && 
            appliedDate.isBefore(monthEnd)) {
          count++;
        }
      }
      months.add(count);
    }
    
    return months.isEmpty ? [0, 0, 0, 0, 0, 0] : months;
  }

  List<Map<String, dynamic>> _buildRecentActivities(List<QueryDocumentSnapshot> applications) {
    final activities = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (final doc in applications.take(5)) {
      final data = doc.data() as Map<String, dynamic>?;
      final status = (data?['status'] ?? '').toString().toLowerCase();
      final jobTitle = (data?['jobTitle'] ?? 'Job').toString();
      final appliedAt = data?['appliedAt'];
      
      DateTime? appliedDate;
      if (appliedAt is Timestamp) {
        appliedDate = appliedAt.toDate();
      } else if (appliedAt is String) {
        appliedDate = DateTime.tryParse(appliedAt);
      }
      
      String timeAgo = 'Recently';
      if (appliedDate != null) {
        final difference = now.difference(appliedDate);
        if (difference.inDays > 0) {
          timeAgo = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
        } else if (difference.inHours > 0) {
          timeAgo = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
        }
      }
      
      IconData icon;
      String title;
      Color color;
      
      if (status.contains('offer') || status.contains('accepted')) {
        icon = Icons.work;
        title = 'Received offer: $jobTitle';
        color = botsYellow;
      } else if (status.contains('interview')) {
        icon = Icons.calendar_today;
        title = 'Interview scheduled: $jobTitle';
        color = botsGreen;
      } else {
        icon = Icons.send;
        title = 'Applied to $jobTitle';
        color = botsBlue;
      }
      
      activities.add({
        'icon': icon,
        'title': title,
        'subtitle': timeAgo,
        'color': color,
      });
    }
    
    return activities;
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'career_tracker',
      child: Scaffold(
      appBar: AppAppBar(
        title: 'Career Tracker',
        variant: AppBarVariant.primary, // Blue background with white text
      ),
      body: SingleChildScrollView(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            _buildApplicationsChart(),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            _buildSkillsProgress(),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            _buildRecentActivity(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_loading) {
      return Row(
        children: [
          Expanded(child: _StatCard(title: 'Applications', value: '—', icon: Icons.send, color: botsBlue)),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(child: _StatCard(title: 'Interviews', value: '—', icon: Icons.calendar_today, color: botsGreen)),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(child: _StatCard(title: 'Offers', value: '—', icon: Icons.work, color: botsYellow)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Applications',
            value: _applicationsCount.toString(),
            icon: Icons.send,
            color: botsBlue,
          ),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
        Expanded(
          child: _StatCard(
            title: 'Interviews',
            value: _interviewsCount.toString(),
            icon: Icons.calendar_today,
            color: botsGreen,
          ),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
        Expanded(
          child: _StatCard(
            title: 'Offers',
            value: _offersCount.toString(),
            icon: Icons.work,
            color: botsYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsChart() {
    final applications = _applicationsOverTime.isEmpty 
        ? [0, 0, 0, 0, 0, 0] 
        : _applicationsOverTime;
    final maxValue = applications.isEmpty 
        ? 1 
        : applications.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applications Over Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: applications.asMap().entries.map((entry) {
                  final height = (entry.value / maxValue) * 150;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: botsBlue,
                          borderRadius: AppDesignSystem.borderRadius(
                              AppDesignSystem.radiusS),
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                      Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: botsDarkGrey,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsProgress() {
    // Load skills from CV if available
    return FutureBuilder<DocumentSnapshot?>(
      future: _dbService.getCVByUserId(_authService.getCurrentUser()?.uid ?? ''),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> skills = [];
        
        if (snapshot.hasData && snapshot.data != null) {
          final cvData = snapshot.data!.data() as Map<String, dynamic>?;
          final skillsList = cvData?['skills'] as List?;
          if (skillsList != null) {
            // Calculate progress based on applications/interviews/offers
            final totalApps = _applicationsCount;
            final successRate = totalApps > 0 ? (_offersCount / totalApps).clamp(0.0, 1.0) : 0.0;
            
            for (var skill in skillsList.take(4)) {
              final skillName = skill.toString();
              // Use success rate as base, add some variation
              final progress = (successRate * 0.7 + 0.3).clamp(0.0, 1.0);
              skills.add({'name': skillName, 'progress': progress});
            }
          }
        }
        
        if (skills.isEmpty) {
          skills = [
            {'name': 'No skills data', 'progress': 0.0},
          ];
        }
        
        return Card(
          child: Padding(
            padding: AppDesignSystem.paddingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skills Development',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                ...skills.map((s) => _SkillProgressItem(
                  s['name'] as String,
                  s['progress'] as double,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_recentActivities.isEmpty) {
      return Card(
        child: Padding(
          padding: AppDesignSystem.paddingM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                'No recent activity',
                style: AppDesignSystem.bodyMedium(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            ..._recentActivities.map((activity) => _ActivityItem(
              icon: activity['icon'] as IconData,
              title: activity['title'] as String,
              subtitle: activity['subtitle'] as String,
              color: activity['color'] as Color,
            )),
          ],
        ),
      ),
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
    return Card(
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: botsDarkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillProgressItem extends StatelessWidget {
  final String skill;
  final double progress;

  const _SkillProgressItem(this.skill, this.progress);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skill),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: botsLightGrey,
            valueColor: AlwaysStoppedAnimation<Color>(botsBlue),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: AppDesignSystem.paddingS,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: botsDarkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
