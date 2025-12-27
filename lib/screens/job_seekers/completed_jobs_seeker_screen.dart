import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/models/job_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/dialogs/rate_company_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

class CompletedJobsSeekerScreen extends StatefulWidget {
  const CompletedJobsSeekerScreen({super.key});

  @override
  State<CompletedJobsSeekerScreen> createState() =>
      _CompletedJobsSeekerScreenState();
}

class _CompletedJobsSeekerScreenState
    extends State<CompletedJobsSeekerScreen> {
  final _authService = FirebaseAuthService();
  late Stream<QuerySnapshot> _completedJobsStream;
  final Map<String, bool> _ratedJobs = {}; // Track which jobs user has rated: jobId -> isApproved (true = approved, false = pending)

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _loadRatedJobs();
  }

  void _loadRatedJobs() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      final ratingsSnap = await FirebaseFirestore.instance
          .collection('ratings')
          .where('raterId', isEqualTo: currentUser.uid)
          .where('raterType', isEqualTo: 'jobSeeker')
          .get();

      if (mounted) {
        setState(() {
          _ratedJobs.clear();
          for (final doc in ratingsSnap.docs) {
            final jobId = doc['jobId'] as String? ?? '';
            if (jobId.isNotEmpty) {
              final isApproved = doc['isApproved'] as bool? ?? false;
              _ratedJobs[jobId] = isApproved;
            }
          }
        });
      }
    }
  }

  void _initializeStream() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      // Get jobs where this user was hired (in hiredApplicants array)
      _completedJobsStream = FirebaseFirestore.instance
          .collection('jobs')
          .where('hiredApplicants', arrayContains: currentUser.uid)
          .where('status', isEqualTo: 'filled')
          .orderBy('completedAt', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'My Completed Jobs',
        variant: AppBarVariant.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _completedJobsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final jobs = snapshot.data?.docs
                  .map((doc) => JobModel.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id))
                  .toList() ??
              [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: AppDesignSystem.spaceL),
                  Text(
                    'No completed jobs yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Text(
                    'Jobs you\'ve been hired for will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppDesignSystem.paddingM,
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _buildJobCard(context, job);
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Text(
                      job.employerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spaceS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                ),
                child: Text(
                  'Completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Text(
            job.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                job.completedAt != null
                    ? 'Completed ${timeago.format(job.completedAt!)}'
                    : 'Recently completed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          SizedBox(
            width: double.infinity,
            child: _ratedJobs.containsKey(job.jobId)
                ? FilledButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.check_circle),
                    label: Text('✓ Rated'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDesignSystem.spaceM,
                      ),
                      backgroundColor: colorScheme.tertiary,
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () {
                      _showRateCompanyDialog(context, job);
                    },
                    icon: Icon(Icons.star),
                    label: Text('Rate Company'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDesignSystem.spaceM,
                      ),
                      backgroundColor: colorScheme.secondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showRateCompanyDialog(BuildContext context, JobModel job) {
    showDialog(
      context: context,
      builder: (context) => RateCompanyDialog(
        companyId: job.employerId,
        companyName: job.employerName,
        jobId: job.jobId,
        jobTitle: job.title,
      ),
    ).then((_) {
      // Reload rated jobs after dialog closes
      _loadRatedJobs();
    });
  }
}

