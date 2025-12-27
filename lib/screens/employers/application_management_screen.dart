import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/screens/employers/application_review_screen.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';

class ApplicationManagementScreen extends StatefulWidget {
  const ApplicationManagementScreen({super.key});

  @override
  State<ApplicationManagementScreen> createState() =>
      _ApplicationManagementScreenState();
}

class _ApplicationManagementScreenState extends State<ApplicationManagementScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  late TabController _tabController;
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      // Get all jobs for this employer
      final jobsSnapshot = await _dbService.getUserJobs(user.uid);
      final jobIds = jobsSnapshot.docs.map((doc) => doc.id).toList();

      if (jobIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Get applications for all jobs
      List<Map<String, dynamic>> allApplications = [];

      for (final jobId in jobIds) {
        try {
          final result = await _dbService.getApplicationsByJob(jobId);
          for (final doc in result.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final jobDoc = await _dbService.getJob(jobId);
            final jobTitle = (jobDoc?.data() as Map<String, dynamic>?)?['title'] ?? 'Job';

            allApplications.add({
              ...data,
              'id': doc.id,
              'jobId': jobId,
              'jobTitle': jobTitle,
              'appliedAt':
                  data['appliedAt'] ?? DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Error loading applicants for job $jobId: $e');
        }
      }

      // Sort by date (newest first)
      allApplications.sort((a, b) {
        final dateA = _parseDate(a['appliedAt']);
        final dateB = _parseDate(b['appliedAt']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _applications = allApplications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load applications: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String && dateValue.isNotEmpty) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  List<Map<String, dynamic>> _filterByStatus(String status) {
    return _applications.where((a) {
      final s = (a['status'] as String?) ?? 'pending';
      return s.toLowerCase() == status;
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: const {AppUserRole.employer},
      child: HintsWrapper(
        screenId: 'application_management',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Manage Applications'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Shortlisted'),
                Tab(text: 'Hired'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildApplicationsList(_filterByStatus('pending')),
                    _buildApplicationsList(_filterByStatus('shortlisted')),
                    _buildApplicationsList(_filterByStatus('hired')),
                    _buildApplicationsList(_filterByStatus('rejected')),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildApplicationsList(List<Map<String, dynamic>> applications) {
    if (applications.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.people_outline,
          title: 'No applications',
          message: 'No applications in this category',
        ),
      );
    }

    return ListView.separated(
      padding: AppDesignSystem.paddingL,
      itemCount: applications.length,
      separatorBuilder: (_, __) => SizedBox(height: AppDesignSystem.spaceM),
      itemBuilder: (context, index) {
        final app = applications[index];
        final applicationId = app['id'] as String? ?? '';
        final jobId = app['jobId'] as String? ?? '';
        final jobTitle = app['jobTitle'] as String? ?? 'Untitled';
        final applicantName = app['applicantName'] as String? ?? 'Unknown';
        final status = (app['status'] as String?) ?? 'pending';

        return AppCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ApplicationReviewScreen(
                  applicationId: applicationId,
                  jobId: jobId,
                  jobTitle: jobTitle,
                ),
              ),
            );
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(app['applicantImage'] ?? ''),
              child: app['applicantImage'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(applicantName),
            subtitle: Text(jobTitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
