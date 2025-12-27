import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'job_posting_screen.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/page_transitions.dart';

class JobManagementScreen extends StatefulWidget {
  const JobManagementScreen({super.key});

  @override
  State<JobManagementScreen> createState() => _JobManagementScreenState();
}

class _JobManagementScreenState extends State<JobManagementScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  late TabController _tabController;
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;
      final snapshot = await _dbService.getUserJobs(user.uid);
      final jobs = snapshot.docs
          .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
          .toList();
      setState(() {
        _jobs = jobs;
      });
    } catch (e) {
      debugPrint('Failed to load user jobs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterByStatus(String status) {
    return _jobs.where((j) {
      final s = (j['status'] as String?) ?? (j['jobStatus'] as String?) ?? 'active';
      return s.toLowerCase() == status;
    }).toList();
  }

  Future<void> _openEdit(String jobId) async {
    await context.pushModern(page: JobPostingScreen(jobId: jobId));
    await _loadJobs();
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
        screenId: 'job_management',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Manage Jobs'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Active'), Tab(text: 'Closed'), Tab(text: 'Cancelled')],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_filterByStatus('active')),
                    _buildList(_filterByStatus('closed')),
                    _buildList(_filterByStatus('cancelled')),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Text(
          'No jobs found',
          style: AppDesignSystem.bodyMedium(context),
        ),
      );
    }

    return ListView.separated(
      padding: AppDesignSystem.paddingL,
      itemCount: jobs.length,
      separatorBuilder: (_, __) => SizedBox(height: AppDesignSystem.spaceM),
      itemBuilder: (context, index) {
        final job = jobs[index];
        final id = job['id'] as String? ?? '';
        final title = job['title'] as String? ?? 'Untitled';
        final company = job['employerName'] as String? ?? job['name'] as String? ?? '';
        final status = (job['status'] as String?) ?? 'active';
        final positionsFilled = (job['positionsFilled'] as int?) ?? 0;
        final positionsAvailable = (job['positionsAvailable'] as int?) ?? 1;
        final isFilled = positionsFilled >= positionsAvailable;

        return AppCard(
          child: Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and edit button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppDesignSystem.titleLarge(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppDesignSystem.spaceS),
                          Text(
                            company,
                            style: AppDesignSystem.bodySmall(context).copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openEdit(id),
                      tooltip: 'Edit job',
                    ),
                  ],
                ),

                SizedBox(height: AppDesignSystem.spaceM),

                // Position progress section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Positions Filled',
                            style: AppDesignSystem.labelSmall(context),
                          ),
                          SizedBox(height: AppDesignSystem.spaceS),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: positionsAvailable > 0
                                  ? positionsFilled / positionsAvailable
                                  : 0,
                              minHeight: 8,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                isFilled
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDesignSystem.spaceM),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spaceM,
                        vertical: AppDesignSystem.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: isFilled
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFilled
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$positionsFilled/$positionsAvailable',
                        style: AppDesignSystem.labelSmall(context).copyWith(
                          color: isFilled
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppDesignSystem.spaceM),

                // Status and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spaceS,
                        vertical: AppDesignSystem.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status, context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.replaceFirstMapped(RegExp(r'^.'),
                            (Match m) => m.group(0)!.toUpperCase()),
                        style: AppDesignSystem.labelSmall(context).copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: AppDesignSystem.spaceM),
                    // Action buttons based on status
                    Row(
                      children: [
                        // Manage Positions button (active jobs only)
                        if (status.toLowerCase() == 'active')
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showPositionOptions(id, job),
                              icon: const Icon(Icons.settings, size: 18),
                              label: const Text('Manage'),
                            ),
                          ),
                        // Close Job button (active jobs only, not completed)
                        if (status.toLowerCase() == 'active')
                          SizedBox(width: AppDesignSystem.spaceS),
                        if (status.toLowerCase() == 'active')
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmAndCloseJob(id, job),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Close'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        // Completed jobs - no actions
                        if (status.toLowerCase() == 'filled' ||
                            status.toLowerCase() == 'completed')
                          Expanded(
                            child: Chip(
                              label: const Text('No actions available'),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'active':
        return Theme.of(context).colorScheme.primaryContainer;
      case 'closed':
        return Theme.of(context).colorScheme.errorContainer;
      case 'cancelled':
        return Theme.of(context).colorScheme.surfaceContainerHighest;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  void _showPositionOptions(String jobId, Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppDesignSystem.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Position Management',
              style: AppDesignSystem.titleLarge(context),
            ),
            SizedBox(height: AppDesignSystem.spaceL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openEdit(jobId);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Position Count'),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmAndCloseJob(jobId, job);
              },
              icon: const Icon(Icons.close_outlined),
              label: const Text('Close Job Posting'),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm before closing job
  /// Shows warning and asks for confirmation
  Future<void> _confirmAndCloseJob(String jobId, Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force user to choose
      builder: (context) => AlertDialog(
        title: const Text('Close Job Posting?'),
        icon: const Icon(Icons.warning_rounded),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to close this job posting.',
              style: AppDesignSystem.bodyMedium(context),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            Container(
              padding: EdgeInsets.all(AppDesignSystem.spaceM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will:',
                    style: AppDesignSystem.labelMedium(context),
                  ),
                  SizedBox(height: AppDesignSystem.spaceS),
                  Text(
                    '• Stop accepting new applications\n'
                    '• Withdraw pending applications (no rejections)\n'
                    '• Require admin approval if people were hired',
                    style: AppDesignSystem.bodySmall(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            Text(
              'Are you sure you want to continue?',
              style: AppDesignSystem.bodySmall(context).copyWith(
                fontWeight: FontWeight.w600,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Yes, Close Job'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Proceed to closure (checks for hired applicants)
      await _closeJob(jobId, job);
    }
  }

  Future<void> _closeJob(String jobId, Map<String, dynamic> job) async {
    final reasonController = TextEditingController();

    // Check if job has hired applicants
    late List<Map<String, dynamic>> hiredApplicants;
    late List<String> applicantsToNotify;
    late int totalApplications;

    try {
      hiredApplicants = await _dbService.getHiredApplicants(jobId);
      applicantsToNotify = await _dbService.getApplicantsToNotify(jobId);
      totalApplications = applicantsToNotify.length + hiredApplicants.length;
    } catch (e) {
      debugPrint('Error loading applicants: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking job applicants: $e')),
      );
      return;
    }

    // If job has hired applicants, require admin approval for safety
    if (hiredApplicants.isNotEmpty) {
      _showJobClosureWithHiredApplicantsDialog(
        jobId: jobId,
        hiredApplicants: hiredApplicants,
        applicantsToNotify: applicantsToNotify,
        totalApplications: totalApplications,
      );
      return;
    }

    // Otherwise, simple closure (no hired applicants)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Job Posting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will close the job and revoke pending applications.\n'
              'Applicants will not see this as a rejection.',
              style: AppDesignSystem.bodyMedium(context),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for closing (required)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.all(AppDesignSystem.spaceM),
              ),
              maxLines: 2,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Close Job'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for closing')),
      );
      return;
    }

    try {
      await _dbService.requestJobClosure(
        jobId: jobId,
        employerId: _authService.getCurrentUser()?.uid ?? '',
        jobTitle: job['title'] as String? ?? 'Unknown Job',
        closureReason: reasonController.text,
        hiredApplicants: [],
        applicantsToNotify: applicantsToNotify,
        totalApplications: totalApplications,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posting closed')),
        );
        _loadJobs();
      }
    } catch (e) {
      debugPrint('Error closing job: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close job: $e')),
        );
      }
    }
  }

  /// Show closure dialog when job has hired applicants
  /// Requires admin approval
  void _showJobClosureWithHiredApplicantsDialog({
    required String jobId,
    required List<Map<String, dynamic>> hiredApplicants,
    required List<String> applicantsToNotify,
    required int totalApplications,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppDesignSystem.spaceL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Has Hired Candidates',
                      style: AppDesignSystem.titleLarge(context),
                    ),
                    SizedBox(height: AppDesignSystem.spaceM),
                    Container(
                      padding: EdgeInsets.all(AppDesignSystem.spaceM),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️  This job cannot be closed directly because people have been hired.',
                            style: AppDesignSystem.bodyMedium(context),
                          ),
                          SizedBox(height: AppDesignSystem.spaceS),
                          Text(
                            'To protect hired employees from scam companies, an admin must approve closure.',
                            style: AppDesignSystem.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppDesignSystem.spaceL),
                    Text(
                      'Hired Candidates (${hiredApplicants.length})',
                      style: AppDesignSystem.labelLarge(context),
                    ),
                    SizedBox(height: AppDesignSystem.spaceM),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spaceL,
                  ),
                  child: Column(
                    children: hiredApplicants.map((applicant) {
                      return Card(
                        margin: EdgeInsets.only(
                          bottom: AppDesignSystem.spaceM,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(AppDesignSystem.spaceM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        applicant['userImage'] != null &&
                                                applicant['userImage']
                                                    .toString()
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                applicant['userImage'])
                                            : null,
                                    child: applicant['userImage'] == null ||
                                            applicant['userImage']
                                                .toString()
                                                .isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  SizedBox(width: AppDesignSystem.spaceM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          applicant['name'] ?? 'Unknown',
                                          style: AppDesignSystem.labelLarge(
                                            context,
                                          ),
                                        ),
                                        Text(
                                          applicant['email'] ?? '',
                                          style: AppDesignSystem.bodySmall(
                                            context,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppDesignSystem.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        hintText: 'Reason for closing (required)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.all(AppDesignSystem.spaceM),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: AppDesignSystem.spaceL),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: AppDesignSystem.spaceM),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: reasonController.text.isNotEmpty
                                ? () async {
                                    Navigator.pop(context);
                                    await _submitClosureRequest(
                                      jobId: jobId,
                                      reason: reasonController.text,
                                      hiredApplicants: hiredApplicants,
                                      applicantsToNotify:
                                          applicantsToNotify,
                                      totalApplications:
                                          totalApplications,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Submit to Admin'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Submit closure request to admin
  Future<void> _submitClosureRequest({
    required String jobId,
    required String reason,
    required List<Map<String, dynamic>> hiredApplicants,
    required List<String> applicantsToNotify,
    required int totalApplications,
  }) async {
    try {
      final userId = _authService.getCurrentUser()?.uid ?? '';
      final jobTitle =
          _jobs.firstWhere((j) => j['id'] == jobId)['title'] as String? ??
              'Unknown Job';

      await _dbService.requestJobClosure(
        jobId: jobId,
        employerId: userId,
        jobTitle: jobTitle,
        closureReason: reason,
        hiredApplicants: hiredApplicants,
        applicantsToNotify: applicantsToNotify,
        totalApplications: totalApplications,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Closure request submitted to admin for review\n'
              'Admin will contact hired candidates',
            ),
          ),
        );
        _loadJobs();
      }
    } catch (e) {
      debugPrint('Error submitting closure request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
