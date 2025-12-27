import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidateSuggestionsScreen extends StatefulWidget {
  const CandidateSuggestionsScreen({super.key});

  @override
  State<CandidateSuggestionsScreen> createState() =>
      _CandidateSuggestionsScreenState();
}

class _CandidateSuggestionsScreenState extends State<CandidateSuggestionsScreen>
    with ConnectivityAware {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  final _aiService = GeminiAIService();

  String? _selectedJobId;
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _employerJobs = [];

  bool _isLoading = false;
  bool _isLoadingJobs = true;

  @override
  void initState() {
    super.initState();
    _loadEmployerJobs();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: const {AppUserRole.employer},
      child: HintsWrapper(
        screenId: 'candidate_suggestions',
        child: Scaffold(
        appBar: AppAppBar(
          title: 'AI Candidate Suggestions',
          variant: AppBarVariant.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  _selectedJobId == null ? _loadEmployerJobs : _loadSuggestions,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
          children: [
            Container(
              padding: AppDesignSystem.paddingM,
              color: AppDesignSystem.surfaceContainerHighest(context),
              child: _isLoadingJobs
                  ? const Center(
                          child: LoadingWidget(
                              message: 'Loading your jobs...'),
                    )
                  : _employerJobs.isEmpty
                      ? Center(
                          child: EmptyState(
                            icon: Icons.work_outline,
                            title: 'No jobs posted yet',
                            message:
                                'Post a job to get AI-powered candidate suggestions based on your requirements.',
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedJobId,
                          decoration: const InputDecoration(
                            labelText: 'Select Job Posting',
                            prefixIcon: Icon(Icons.work),
                          ),
                          items: _employerJobs.map((job) {
                            return DropdownMenuItem<String>(
                              value: job['id'] as String,
                                  child:
                                      Text(job['title'] as String? ?? 'Job'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedJobId = value);
                            _loadSuggestions();
                          },
                        ),
            ),
                _selectedJobId == null
                  ? const Center(
                        child:
                            Text('Select a job posting to see AI suggestions'),
                    )
                  : _isLoading
                      ? const Center(
                          child: LoadingWidget(
                            message:
                                'Analyzing candidates and calculating match scores...',
                          ),
                        )
                      : _suggestions.isEmpty
                          ? Center(
                              child: EmptyState(
                                icon: Icons.people_outline,
                                title: 'No matching candidates found',
                                message:
                                    'Try selecting a different job posting or adjust your job requirements to find more candidates.',
                              ),
                            )
                          : ListView.builder(
                              padding: AppDesignSystem.paddingM,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final candidate = _suggestions[index];
                                return _CandidateCard(
                                  candidate: candidate,
                                  matchScore:
                                        (candidate['matchScore'] as int?) ??
                                            0,
                                    onViewProfile: () =>
                                        _viewCandidateProfile(
                                    context,
                                    candidate,
                                  ),
                                    onContact: () =>
                                        _contactCandidate(candidate),
                                );
                              },
                            ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _loadEmployerJobs() async {
    if (!await checkConnectivity(
      context,
      message:
          'Cannot load jobs without internet. Please connect and try again.',
    )) {
      if (mounted) setState(() => _isLoadingJobs = false);
      return;
    }

    setState(() {
      _isLoadingJobs = true;
      _employerJobs = [];
      _selectedJobId = null;
      _suggestions = [];
    });

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Please log in again.');
          setState(() => _isLoadingJobs = false);
        }
        return;
      }

      final jobsSnap = await _dbService.getUserJobs(user.uid);
      // Filter to only active jobs (not closed/filled) - prevents AI suggestions from showing closed jobs (Issue #10)
      final jobs = jobsSnap.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final status = (data['status'] as String?)?.toLowerCase() ?? 'active';
            // Only include jobs that are active, not closed or filled
            return status == 'active' || status == 'pending' || status == 'approved';
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {
              'id': doc.id,
              'title': data['jobTitle'] ?? data['title'] ?? 'Job',
              'requiredSkills': data['requiredSkills'] ??
                  data['skills'] ??
                  data['requirements'] ??
                  <dynamic>[],
            };
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _employerJobs = jobs;
        _selectedJobId = jobs.isNotEmpty ? jobs.first['id'] as String : null;
        _isLoadingJobs = false;
      });

      if (_selectedJobId != null) {
        await _loadSuggestions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingJobs = false);
      SnackbarHelper.showError(context, 'Failed to load jobs: $e');
    }
  }

  Future<void> _loadSuggestions() async {
    final selectedJobId = _selectedJobId;
    if (selectedJobId == null) {
      setState(() => _suggestions = []);
      return;
    }

    if (!await checkConnectivity(
      context,
      message:
          'Cannot load suggestions without internet. Please connect and try again.',
    )) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedJob = _employerJobs.firstWhere(
        (job) => job['id'] == selectedJobId,
        orElse: () => <String, dynamic>{},
      );

      final rawRequiredSkills =
          (selectedJob['requiredSkills'] as List<dynamic>?) ??
              const <dynamic>[];
      final requiredSkills = rawRequiredSkills
          .map((s) => s.toString().trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      final cvsQuery = await FirebaseFirestore.instance
          .collection('cvs')
          .where('is_searchable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(300)
          .get();
      final allCandidates = <Map<String, dynamic>>[];

      for (final cvDoc in cvsQuery.docs) {
        final cvData = cvDoc.data();
        final userId = (cvData['userId'] ?? cvData['user_id'])?.toString();
        if (userId == null || userId.trim().isEmpty) continue;

        final personalInfo = (cvData['personalInfo'] is Map)
            ? (cvData['personalInfo'] as Map)
            : (cvData['personal_info'] is Map)
                ? (cvData['personal_info'] as Map)
                : null;

        final name = (cvData['name'] ??
                personalInfo?['fullName'] ??
                personalInfo?['full_name'] ??
                cvData['fullName'] ??
                cvData['full_name'])
            ?.toString();

        final email = (cvData['email'] ?? personalInfo?['email'])?.toString();
        final phone = (cvData['phone'] ?? personalInfo?['phone'])?.toString();

        final location = (cvData['location'] ??
                cvData['address'] ??
                personalInfo?['address'] ??
                cvData['city'] ??
                cvData['country'])
            ?.toString();

        final experienceRaw =
            (cvData['experience'] as List<dynamic>?) ?? const <dynamic>[];
        final firstRole = experienceRaw.isNotEmpty && experienceRaw.first is Map
            ? experienceRaw.first as Map
            : null;

        final title = (cvData['title'] ??
                cvData['jobTitle'] ??
                firstRole?['position'] ??
                firstRole?['role'])
            ?.toString();

        final experienceYears = (cvData['experienceYears'] ??
                cvData['yearsExperience'] ??
                cvData['experience_years'])
            ?.toString();

        final experience =
            (experienceYears != null && experienceYears.trim().isNotEmpty)
                ? experienceYears
                : (experienceRaw.isNotEmpty)
                    ? '${experienceRaw.length} roles'
                    : null;

        final skillsRaw =
            (cvData['skills'] as List<dynamic>?) ?? const <dynamic>[];
        final candidateSkillsLower = skillsRaw
            .map((s) => s.toString().trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet();

        final matched = requiredSkills
            .where((req) => candidateSkillsLower.contains(req))
            .toList();

        final matchScore = _calculateMatchScore(
          requiredSkills: requiredSkills,
          matchedSkillsCount: matched.length,
        );

        allCandidates.add({
          'userId': userId,
          'name': name ?? 'Candidate',
          'title': title ?? 'Job Seeker',
          'experience': experience ?? 'N/A',
          'location': location ?? 'N/A',
          'email': email ?? '',
          'phone': phone ?? '',
          'skills': skillsRaw.map((s) => s.toString()).toList(),
          'matchScore': matchScore,
          'matchedSkills': matched,
        });
      }

      allCandidates.sort(
        (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int),
      );

      // AI rerank (server-side) for better suggestions.
      final candidatesForAI = allCandidates.take(50).toList(growable: false);
      List<Map<String, dynamic>> finalTop;
      
      try {
        final aiRankings = await _aiService.recommendCandidatesForJob(
          job: {
            'title': selectedJob['title']?.toString() ?? 'Job',
            'requiredSkills': requiredSkills,
          },
          candidates: candidatesForAI
              .map((c) => {
                    'userId': c['userId'],
                    'name': c['name'],
                    'title': c['title'],
                    'experience': c['experience'],
                    'location': c['location'],
                    'skills': c['skills'],
                    'matchScore': c['matchScore'],
                  })
              .toList(growable: false),
          maxResults: 10,
        );

          if (aiRankings.isNotEmpty) {
          final byId = <String, Map<String, dynamic>>{
            for (final r in aiRankings)
              if ((r['userId']?.toString() ?? '').isNotEmpty)
                r['userId'].toString(): r,
          };

          final reranked = candidatesForAI.map((c) {
            final id = c['userId']?.toString() ?? '';
            final r = byId[id];
            if (r == null) return c;
            final aiScore = (r['matchScore'] is num)
                ? (r['matchScore'] as num).round().clamp(0, 100)
                : (int.tryParse(r['matchScore']?.toString() ?? '') ?? 0)
                    .clamp(0, 100);
            return {
              ...c,
              'matchScore': aiScore,
              'aiReason': r['reason']?.toString() ?? '',
            };
          }).toList(growable: false);

          reranked.sort((a, b) {
            final aScore = (a['matchScore'] as int?) ?? 0;
            final bScore = (b['matchScore'] as int?) ?? 0;
            return bScore.compareTo(aScore);
          });

          finalTop = reranked.take(10).toList();
          
          // Notify employer if high-quality matches found (fire and forget)
          if (finalTop.isNotEmpty) {
            final topMatch = finalTop.first;
            final topScore = (topMatch['matchScore'] as int?) ?? 0;
            if (topScore >= 75) {
              try {
                final notificationService = NotificationService();
                final user = _authService.getCurrentUser();
                if (user != null) {
                  await notificationService.sendNotification(
                    userId: user.uid,
                    type: 'candidate_match',
                    title: 'New High-Quality Candidate Match! 🎯',
                    body: 'We found $finalTop.length strong candidate${finalTop.length > 1 ? 's' : ''} for "${selectedJob['title']}". Top match: $topScore%.',
                    data: {
                      'jobId': selectedJobId,
                      'jobTitle': selectedJob['title']?.toString() ?? 'Job',
                      'matchCount': finalTop.length,
                      'topMatchScore': topScore,
                    },
                  );
                }
              } catch (e) {
                debugPrint('Error sending candidate match notification: $e');
                // Don't block suggestions loading
              }
            }
          }
        } else {
          // AI returned empty - no candidates match
          finalTop = [];
        }
      } catch (e) {
        debugPrint('AI candidate recommendation failed: $e');
        // AI failed - return empty list, no fallback
        finalTop = [];
      }

      // Attach user profile images and ratings for finalTop candidates (batch by up to 10 per request)
      if (finalTop.isNotEmpty) {
        final ids = finalTop.map((c) => c['userId']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        final userDocs = <String, Map<String, dynamic>>{};
        final ratingsDocs = <String, Map<String, dynamic>>{};

        // Firestore whereIn supports up to 10; batch if necessary
        for (var i = 0; i < ids.length; i += 10) {
          final batch = ids.sublist(i, (i + 10).clamp(0, ids.length));
          
          // Fetch user docs for profile image
          final userQS = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          for (final d in userQS.docs) {
            userDocs[d.id] = d.data() as Map<String, dynamic>? ?? {};
          }

          // Fetch ratings docs (query by ratedUserId)
          final ratingQS = await FirebaseFirestore.instance
              .collection('ratings')
              .where('ratedUserId', whereIn: batch)
              .where('isApproved', isEqualTo: true)
              .get();
          for (final d in ratingQS.docs) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            final ratedId = data['ratedUserId']?.toString() ?? '';
            if (ratedId.isNotEmpty) {
              ratingsDocs[ratedId] = data;
            }
          }
        }

        for (var i = 0; i < finalTop.length; i++) {
          final id = finalTop[i]['userId']?.toString() ?? '';
          final u = userDocs[id];
          final r = ratingsDocs[id];
          
          finalTop[i] = {
            ...finalTop[i],
            'user_image': (u?['user_image'] as String?) ?? (u?['userImage'] as String?) ?? '',
            'avgRating': r?['avgRating'] as double? ?? 5.0,
            'ratingCount': r?['ratingCount'] as int? ?? 0,
          };
        }
      }

      if (!mounted) return;
      setState(() {
        _suggestions = finalTop;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Failed to load suggestions: $e');
    }
  }

  int _calculateMatchScore({
    required List<String> requiredSkills,
    required int matchedSkillsCount,
  }) {
    if (requiredSkills.isEmpty) return 0;
    final score = ((matchedSkillsCount / requiredSkills.length) * 100).round();
    return score.clamp(0, 100);
  }

  void _viewCandidateProfile(
    BuildContext context,
    Map<String, dynamic> candidate,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final matchScore = (candidate['matchScore'] as int?) ?? 0;
    final matchColor = _matchColor(colorScheme, matchScore);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(candidate['name']?.toString() ?? 'Candidate Profile'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: matchColor),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                  Text(
                    'Match Score: $matchScore%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: matchColor,
                    ),
                  ),
                ],
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              if ((candidate['aiReason']?.toString() ?? '').trim().isNotEmpty)
                _DialogRow(
                  label: 'AI Reason',
                  value: candidate['aiReason']?.toString(),
                ),
              _DialogRow(label: 'Title', value: candidate['title']?.toString()),
              _DialogRow(
                label: 'Experience',
                value: candidate['experience']?.toString(),
              ),
              _DialogRow(
                label: 'Location',
                value: candidate['location']?.toString(),
              ),
              if ((candidate['email']?.toString() ?? '').isNotEmpty)
                _DialogRow(
                    label: 'Email', value: candidate['email']?.toString()),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                'Skills',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ((candidate['skills'] as List<dynamic>?) ??
                        const <dynamic>[])
                    .take(10)
                    .map(
                      (skill) => Chip(
                        label: Text(skill.toString()),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          StandardButton(
            label: 'Close',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _contactCandidate(Map<String, dynamic> candidate) async {
    if (!mounted) return;

    final email = candidate['email'] as String? ?? '';
    if (email.isEmpty) {
      SnackbarHelper.showError(context, 'Candidate email not available');
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=Job Opportunity&body=Hello, I saw your profile and would like to discuss a potential opportunity.',
    );

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!mounted) return;

      if (canLaunch) {
        await launchUrl(uri);
      } else {
        SnackbarHelper.showError(context, 'Could not open email client');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
            context, 'Failed to open email: ${e.toString()}');
      }
    }
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final int matchScore;
  final VoidCallback onViewProfile;
  final VoidCallback onContact;

  const _CandidateCard({
    required this.candidate,
    required this.matchScore,
    required this.onViewProfile,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final matchColor = _matchColor(colorScheme, matchScore);

    final name = candidate['name'] as String?;
    final title = candidate['title'] as String?;
    final initial = (name == null || name.trim().isEmpty)
        ? '?'
        : name.trim()[0].toUpperCase();

    return AppCard(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              candidate['user_image'] != null && (candidate['user_image'] as String).isNotEmpty
                  ? CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: NetworkImage(candidate['user_image'] as String),
                    )
                  : CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        initial,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Candidate',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((title ?? '').isNotEmpty)
                      Text(
                        title!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: matchColor.withValues(alpha: 0.12),
                  borderRadius: AppDesignSystem.borderRadiusCircular,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: matchColor),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                    Text(
                      '$matchScore%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: matchColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          if ((candidate['avgRating'] as double? ?? 5.0) > 0 || (candidate['ratingCount'] as int? ?? 0) > 0) ...[
            Row(
              children: [
                Icon(Icons.star, size: 18, color: Colors.amber),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                Text(
                  '${((candidate['avgRating'] as double? ?? 5.0) * 10).round() / 10} (${candidate['ratingCount'] ?? 0})',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          ],
          if (candidate['skills'] != null) ...[
            Text(
              'Skills Match',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (candidate['skills'] as List<dynamic>)
                  .take(6)
                  .map(
                    (skill) => Chip(
                      label: Text(skill.toString()),
                      backgroundColor:
                          AppDesignSystem.surfaceContainerHighest(context),
                    ),
                  )
                  .toList(),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          ],
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.work,
                  label: 'Experience',
                  value: (candidate['experience'] ?? 'N/A').toString(),
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: (candidate['location'] ?? 'N/A').toString(),
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              Expanded(
                child: StandardButton(
                  label: 'View Profile',
                  type: StandardButtonType.outlined,
                  onPressed: onViewProfile,
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
              StandardButton(
                label: 'Contact',
                type: StandardButtonType.primary,
                onPressed: onContact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _matchColor(ColorScheme colorScheme, int score) {
  if (score >= 80) return colorScheme.primary;
  if (score >= 60) return colorScheme.tertiary;
  return colorScheme.error;
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DialogRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              (value ?? 'N/A').trim().isEmpty ? 'N/A' : value!,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
