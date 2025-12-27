import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/models/application_model.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/screens/homescreen/components/job_details.dart';
import 'package:freelance_app/screens/job_seekers/interview_management_job_seeker_screen.dart';

class ApplicationManagementJobSeekerScreen extends StatefulWidget {
  const ApplicationManagementJobSeekerScreen({super.key});

  @override
  State<ApplicationManagementJobSeekerScreen> createState() =>
      _ApplicationManagementJobSeekerScreenState();
}

class _ApplicationManagementJobSeekerScreenState
    extends State<ApplicationManagementJobSeekerScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  late TabController _tabController;
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await _dbService.getApplicationsByUser(userId: user.uid);
      final applications = result.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return ApplicationModel.fromMap(data, d.id);
          })
          .toList();

      // Sort by date (newest first)
      applications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load applications: $e');
      setState(() => _isLoading = false);
    }
  }

  List<ApplicationModel> _filterByStatus(String status) {
    if (status == 'all') return _applications;
    return _applications.where((a) => a.status == status).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'application_management_seeker',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Applications'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
              Tab(text: 'Interview'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildApplicationsList(_filterByStatus('pending')),
                  _buildApplicationsList(_filterByStatus('approved')),
                  _buildApplicationsList(_filterByStatus('rejected')),
                  _buildApplicationsList(_filterByStatus('interview_scheduled')),
                  _buildApplicationsList(_filterByStatus('all')),
                ],
              ),
      ),
    );
  }

  Widget _buildApplicationsList(List<ApplicationModel> applications) {
    if (applications.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.description_outlined,
          title: 'No applications',
          message: 'No applications in this category',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.separated(
        padding: AppDesignSystem.paddingL,
        itemCount: applications.length,
        separatorBuilder: (_, __) => SizedBox(height: AppDesignSystem.spaceM),
        itemBuilder: (context, index) {
          final app = applications[index];
          return _ApplicationCard(
            application: app,
            dbService: _dbService,
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatefulWidget {
  final ApplicationModel application;
  final FirebaseDatabaseService dbService;

  const _ApplicationCard({
    required this.application,
    required this.dbService,
  });

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  String? _jobTitle;
  String? _employerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  Future<void> _loadJobData() async {
    try {
      final jobDoc = await widget.dbService.getJob(widget.application.jobId);
      if (jobDoc != null) {
        final jobData = jobDoc.data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _jobTitle = jobData?['title'] as String? ?? 'Job';
            _employerId = (jobData?['userId'] ?? jobData?['id'])?.toString();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading job data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final status = widget.application.status;

    return AppCard(
      onTap: () {
        // If application has an interview scheduled, navigate to interview management
        if (widget.application.interviewId != null &&
            widget.application.interviewId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InterviewManagementJobSeekerScreen(
                highlightedApplicationId: widget.application.id,
              ),
            ),
          );
        } else if (_employerId != null && _employerId!.isNotEmpty) {
          // Otherwise navigate to job details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailsScreen(
                id: _employerId!,
                jobId: widget.application.jobId,
              ),
            ),
          );
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status, context),
          ),
        ),
        title: Text(_jobTitle ?? 'Job'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(widget.application.appliedAt),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.application.aiMatchScore != null)
              Text(
                'AI Match: ${widget.application.aiMatchScore}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppDesignSystem.secondary(context),
                ),
              ),
            if (widget.application.interviewId != null &&
                widget.application.interviewId!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: colorScheme.secondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Interview scheduled',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                _getStatusLabel(status),
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusColor(status, context),
                ),
              ),
              backgroundColor:
                  _getStatusColor(status, context).withValues(alpha: 0.1),
              side: BorderSide(
                color: _getStatusColor(status, context)
                    .withValues(alpha: 0.5),
              ),
            ),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'interview_scheduled':
        return 'Interview';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'interview_scheduled':
        return Icons.calendar_today;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'pending':
        return colorScheme.onSurfaceVariant;
      case 'approved':
        return colorScheme.tertiary;
      case 'rejected':
        return colorScheme.error;
      case 'interview_scheduled':
        return colorScheme.secondary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Today';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
