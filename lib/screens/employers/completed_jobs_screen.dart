import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/models/job_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/dialogs/rate_freelancer_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

class CompletedJobsScreen extends StatefulWidget {
  const CompletedJobsScreen({super.key});

  @override
  State<CompletedJobsScreen> createState() => _CompletedJobsScreenState();
}

class _CompletedJobsScreenState extends State<CompletedJobsScreen> {
  final _authService = FirebaseAuthService();
  late Stream<QuerySnapshot> _completedJobsStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _completedJobsStream = FirebaseFirestore.instance
          .collection('jobs')
          .where('userId', isEqualTo: currentUser.uid)
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
        title: 'Completed Jobs',
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
                    Icons.check_circle_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: AppDesignSystem.spaceL),
                  Text('No completed jobs yet'),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Text(
                      job.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spaceS,
                  vertical: AppDesignSystem.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                ),
                child: Text(
                  'Completed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                '${job.positionsFilled}/${job.positionsAvailable} positions filled',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Spacer(),
              Icon(
                Icons.calendar_today,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                job.completedAt != null
                    ? timeago.format(job.completedAt!)
                    : 'Recently',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to rate hired applicants screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RateHiredApplicantsScreen(
                      jobId: job.jobId,
                      jobTitle: job.title,
                      hiredApplicants: job.hiredApplicants,
                    ),
                  ),
                );
              },
              child: Text('Rate Hired Applicants'),
            ),
          ),
        ],
      ),
    );
  }
}

// Screen to rate hired applicants
class RateHiredApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final List<String> hiredApplicants;

  const RateHiredApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.hiredApplicants,
  });

  @override
  State<RateHiredApplicantsScreen> createState() =>
      _RateHiredApplicantsScreenState();
}

class _RateHiredApplicantsScreenState extends State<RateHiredApplicantsScreen> {
  final _authService = FirebaseAuthService();
  late Stream<QuerySnapshot> _applicantsStream;
  final Map<String, bool> _ratedApplicants = {}; // applicantId -> isApproved (true = approved, false = pending)

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _loadRatedApplicants();
  }

  void _loadRatedApplicants() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      final ratingsSnap = await FirebaseFirestore.instance
          .collection('ratings')
          .where('raterId', isEqualTo: currentUser.uid)
          .where('raterType', isEqualTo: 'company')
          .where('jobId', isEqualTo: widget.jobId)
          .get();

      if (mounted) {
        setState(() {
          _ratedApplicants.clear();
          for (final doc in ratingsSnap.docs) {
            final ratedUserId = doc['ratedUserId'] as String? ?? '';
            if (ratedUserId.isNotEmpty) {
              final isApproved = doc['isApproved'] as bool? ?? false;
              _ratedApplicants[ratedUserId] = isApproved;
            }
          }
        });
      }
    }
  }

  void _initializeStream() {
    _applicantsStream = FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: widget.hiredApplicants)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Rate Hired Applicants',
        variant: AppBarVariant.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _applicantsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final applicants = snapshot.data?.docs ?? [];

          if (applicants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: AppDesignSystem.spaceL),
                  Text('No hired applicants'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppDesignSystem.paddingM,
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicantData =
                  applicants[index].data() as Map<String, dynamic>;
              final applicantId = applicants[index].id;
              final applicantName =
                  applicantData['name'] as String? ?? 'Unknown';
              final applicantImage =
                  applicantData['user_image'] as String? ?? '';

              return _buildApplicantCard(
                context,
                applicantId,
                applicantName,
                applicantImage,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicantCard(
    BuildContext context,
    String applicantId,
    String applicantName,
    String applicantImage,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: applicantImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      applicantImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: colorScheme.primary,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: colorScheme.primary,
                  ),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicantName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                Text(
                  'Hired for: ${widget.jobTitle}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _ratedApplicants.containsKey(applicantId)
              ? Chip(
                  label: Text('✓ Rated'),
                  backgroundColor: colorScheme.tertiaryContainer,
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : FilledButton.icon(
                  onPressed: () {
                    // Show rating dialog
                    _showRatingDialog(context, applicantId, applicantName);
                  },
                  icon: Icon(Icons.star),
                  label: Text('Rate'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spaceM,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    backgroundColor: colorScheme.secondary,
                  ),
                ),
        ],
      ),
    );
  }

  void _showRatingDialog(
    BuildContext context,
    String applicantId,
    String applicantName,
  ) {
    showDialog(
      context: context,
      builder: (context) => RateFreelancerDialog(
        freelancerId: applicantId,
        freelancerName: applicantName,
        jobId: widget.jobId,
        jobTitle: widget.jobTitle,
      ),
    ).then((_) {
      // Reload rated applicants after dialog closes
      _loadRatedApplicants();
    });
  }
}
