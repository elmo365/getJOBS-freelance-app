import 'package:flutter/material.dart';
import 'package:freelance_app/models/application_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/screens/homescreen/components/job_details.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class ApplicationHistoryScreen extends StatefulWidget {
  const ApplicationHistoryScreen({super.key});

  @override
  State<ApplicationHistoryScreen> createState() =>
      _ApplicationHistoryScreenState();
}

class _ApplicationHistoryScreenState extends State<ApplicationHistoryScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;
  String? _userId;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userId = user.uid;
      });
      _loadApplications();
    }
  }

  Future<void> _loadApplications() async {
    if (_userId == null) return;

    if (!await checkConnectivity(context,
        message: 'Cannot load applications without internet.')) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _dbService.getApplicationsByUser(userId: _userId!);

      final allApplications = result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ApplicationModel.fromMap(data, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _applications = allApplications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading applications: $e');
      }
    }
  }

  List<ApplicationModel> get _filteredApplications {
    if (_selectedFilter == 'all') return _applications;
    return _applications.where((app) => app.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'application_history',
      child: Scaffold(
      appBar: AppAppBar(
        title: 'My Applications',
        variant: AppBarVariant.primary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
              const PopupMenuItem(
                  value: 'interview_scheduled', child: Text('Interviews')),
            ],
            child: Padding(
              padding: AppDesignSystem.paddingM,
              child: Row(
                children: [
                  Text(_getFilterLabel(_selectedFilter)),
                  const Icon(Icons.filter_list),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: LoadingWidget(message: 'Loading applications...'))
          : _filteredApplications.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No applications yet',
                    message:
                        'Start applying to jobs to see your application history here.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.builder(
                    padding: AppDesignSystem.paddingM,
                    itemCount: _filteredApplications.length,
                    itemBuilder: (context, index) {
                      final application = _filteredApplications[index];
                      return _ApplicationCard(application: application);
                    },
                  ),
                ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'interview_scheduled':
        return 'Interviews';
      default:
        return 'All';
    }
  }
}

class _ApplicationCard extends StatefulWidget {
  final ApplicationModel application;

  const _ApplicationCard({required this.application});

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  final _dbService = FirebaseDatabaseService();
  String? _jobTitle;
  String? _employerId;

  @override
  void initState() {
    super.initState();
    _loadJobTitle();
  }

  Future<void> _loadJobTitle() async {
    try {
      final jobDoc = await _dbService.getJob(widget.application.jobId);
      if (jobDoc != null) {
        final jobData = jobDoc.data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _jobTitle =
                jobData?['title'] as String? ?? jobData?['jobTitle'] as String?;
            _employerId = (jobData?['userId'] ?? jobData?['id'])?.toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading job title: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      onTap: () {
        final employerId = _employerId;
        if (employerId == null || employerId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(
              id: employerId,
              jobId: widget.application.jobId,
            ),
          ),
        );
      },
                    padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _jobTitle ?? 'Job',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Text(
                      'Applied ${timeago.format(widget.application.appliedAt)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppDesignSystem.onSurfaceVariant(context),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(widget.application.status),
            ],
          ),
          if (widget.application.aiMatchScore != null) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 16, color: AppDesignSystem.secondary(context)),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                Text(
                  'AI Match: ${widget.application.aiMatchScore}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (widget.application.reviewNotes != null) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Container(
              padding: AppDesignSystem.paddingM,
              decoration: BoxDecoration(
                color: AppDesignSystem.surfaceContainerHighest(context),
                borderRadius: AppDesignSystem.borderRadiusS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    widget.application.reviewNotes!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ApplicationStatus.approved:
        color = AppDesignSystem.tertiary(context);
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case ApplicationStatus.rejected:
        color = AppDesignSystem.errorColor(context);
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case ApplicationStatus.interviewScheduled:
        color = AppDesignSystem.secondary(context);
        label = 'Interview';
        icon = Icons.calendar_today;
        break;
      default:
        color = AppDesignSystem.onSurfaceVariant(context);
        label = 'Pending';
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusXL,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
