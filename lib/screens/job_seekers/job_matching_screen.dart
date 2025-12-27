import 'dart:async';
import 'package:flutter/material.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/models/job_model.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/ai/context_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/reusable_widgets.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/screens/job_seekers/cv_builder_screen.dart';
import 'package:freelance_app/screens/homescreen/components/job_details.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class JobMatchingScreen extends StatefulWidget {
  const JobMatchingScreen({super.key});

  @override
  State<JobMatchingScreen> createState() => _JobMatchingScreenState();
}

class _JobMatchingScreenState extends State<JobMatchingScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _aiService = GeminiAIService();
  List<JobModel> _matchedJobs = [];
  final Map<String, Map<String, dynamic>> _matchDetails =
      {}; // Store job ID -> AI details
  bool _isLoading = true;
  bool _hasCv = false; // Track if user has a CV

  @override
  void initState() {
    super.initState();
    _loadMatchedJobs();
  }

  Future<void> _loadMatchedJobs() async {
    if (!await checkConnectivity(context,
        message:
            'Cannot load job matches without internet. Please connect and try again.')) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get user's CV for matching using ContextService for consistency
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasCv = false;
          });
        }
        return;
      }

      // Use ContextService to build user profile (same as recommended jobs)
      final userProfile = await ContextService().buildUserProfileContext(user.uid);
      
      // Check if profile was built successfully
      if (userProfile.isEmpty || userProfile['error'] != null) {
        debugPrint('⚠️ Job Matching: Failed to load user profile - ${userProfile['error'] ?? 'Unknown error'}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasCv = false;
          });
        }
        return;
      }

      // Check if user has CV by checking if skills exist
      final userSkills = (userProfile['skills'] as List<dynamic>? ?? []).cast<String>();
      _hasCv = userSkills.isNotEmpty;
      
      debugPrint('✅ Job Matching: Loaded profile with ${userSkills.length} skills, ${userProfile['experienceYears'] ?? 0} years experience');

      // Extract data from profile
      final userSkillsSet = userSkills.map((s) => s.toLowerCase()).toSet();
      final userExperience = (userProfile['experienceYears'] as int? ?? 0);

      // Get active jobs
      final result = await _dbService.getActiveJobs(limit: 50);
      final allJobs = result.docs
          .map((doc) =>
              JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Heuristic prefilter to reduce prompt size.
      final scoredJobs = allJobs.map((job) {
        final score = _calculateMatchScore(
          job: job,
          userSkills: userSkillsSet,
          userExperience: userExperience,
        );
        return {'job': job, 'score': score};
      }).toList();
      scoredJobs
          .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final prefiltered = scoredJobs.take(30).toList();

      debugPrint('📊 Job Matching: Prefiltered ${prefiltered.length} jobs from ${allJobs.length} total jobs');

      List<Map<String, dynamic>> ranked = const [];
      try {
          final availableJobs = prefiltered.map((item) {
            final job = item['job'] as JobModel;
            final desc = job.description;
            final snippet = desc.length > 450 ? desc.substring(0, 450) : desc;
            
            // Build job map matching backend expectations
            // Backend line 593: jobId: String(j.jobId || j.id || '')
            // We always send jobId (document ID), so 'id' fallback is unnecessary but harmless
            return {
              'jobId': job.jobId, // Document ID - backend expects this (line 593)
              'title': job.title,
              'category': job.category,
              'location': job.location ?? '',
              'experienceLevel': job.experienceLevel ?? '',
              'jobType': job.jobType ?? '',
              'requiredSkills': List<String>.from(job.requiredSkills),
              'descriptionSnippet': snippet,
              'employerId': job.employerId, // Needed for fetching company ratings
              'userId': job.employerId, // Alternative field name for backend compatibility
            };
          }).toList();

          debugPrint('🤖 [Job Matching] Calling AI with ${availableJobs.length} jobs');
          if (availableJobs.isNotEmpty) {
            debugPrint('🤖 [Job Matching] Sample job: jobId=${availableJobs.first['jobId']}');
          }
          
          ranked = await _aiService.recommendJobsForUser(
            userId: user.uid,
            userProfile: userProfile,
            availableJobs: availableJobs,
          );
          
          debugPrint('✅ [Job Matching] AI returned ${ranked.length} ranked jobs');
          if (ranked.isNotEmpty) {
            debugPrint('✅ [Job Matching] Sample result: jobId=${ranked.first['jobId']}, score=${ranked.first['matchScore']}');
          }
      } catch (e, stackTrace) {
        debugPrint('❌ [Job Matching] AI recommendation failed: $e');
        debugPrint('❌ [Job Matching] Stack trace: $stackTrace');
        // AI failed - return empty matches, no fallback
        ranked = const [];
      }

      final byId = {
        for (final item in prefiltered)
          (item['job'] as JobModel).jobId: (item['job'] as JobModel),
      };
      
      debugPrint('🔍 [Job Matching] Created lookup map with ${byId.length} jobs');
      if (byId.isNotEmpty) {
        debugPrint('🔍 [Job Matching] Sample keys: ${byId.keys.take(3).toList()}');
      }

      final topMatches = <Map<String, dynamic>>[];
      if (ranked.isNotEmpty) {
        for (final item in ranked.take(20)) {
          // Backend always returns 'jobId' (normalized from AI response)
          final jobId = (item['jobId'] as String? ?? '').toString();
          if (jobId.isEmpty) {
            debugPrint('⚠️ [Job Matching] Skipping item with empty jobId: $item');
            continue;
          }
          final job = byId[jobId];
          if (job == null) {
            debugPrint('⚠️ [Job Matching] Job not found in byId map: $jobId');
            debugPrint('⚠️ [Job Matching] Available keys: ${byId.keys.take(5).toList()}');
            continue;
          }

          final scoreRaw = item['matchScore'];
          final score = (scoreRaw is num)
              ? scoreRaw.round()
              : int.tryParse(scoreRaw?.toString() ?? '') ?? 0;
          topMatches.add({'job': job, 'score': score.clamp(0, 100)});
        }
      }

      if (!mounted) return;
      setState(() {
        _matchedJobs =
            topMatches.map((item) => item['job'] as JobModel).toList();
        _matchDetails
          ..clear()
          ..addEntries(
            topMatches.map((item) {
              final job = item['job'] as JobModel;
              return MapEntry(job.jobId, {
                'score':
                    (item['score'] as int? ?? item['matchScore'] as int? ?? 0),
                'reason': item['reason']?.toString() ??
                    item['reasoning']?.toString() ??
                    'Matched based on your profile skills and experience.',
                'missingSkills': item['missingSkills'] as List<dynamic>? ?? [],
              });
            }),
          );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateMatchScore({
    required JobModel job,
    required Set<String> userSkills,
    required int userExperience,
  }) {
    int score = 0;

    // Skill matching (60 points)
    final jobSkills = [
      job.category.toLowerCase(),
      ...(job.description.toLowerCase().split(' ')),
    ].where((s) => s.length > 3).toSet();

    final matchingSkills = userSkills.where((skill) {
      return jobSkills.any((js) => js.contains(skill) || skill.contains(js));
    }).length;

    if (jobSkills.isNotEmpty) {
      score += ((matchingSkills / jobSkills.length) * 60).round().clamp(0, 60);
    }

    // Experience level matching (40 points)
    final exp = (job.experienceLevel ?? '').toLowerCase();
    if (exp.contains('senior')) {
      score += userExperience >= 5 ? 40 : 15;
    } else if (exp.contains('mid')) {
      score += userExperience >= 3 ? 35 : 15;
    } else if (exp.contains('entry') || exp.contains('junior')) {
      score += userExperience <= 3 ? 40 : 20;
    } else {
      // Try to infer from text if the explicit field is missing.
      final text = '${job.title} ${job.description}'.toLowerCase();
      if (text.contains('senior')) {
        score += userExperience >= 5 ? 40 : 15;
      } else if (text.contains('mid')) {
        score += userExperience >= 3 ? 35 : 15;
      } else if (text.contains('junior') || text.contains('entry')) {
        score += userExperience <= 3 ? 40 : 20;
      } else {
        score += 25;
      }
    }

    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Smart Job Matching',
        variant: AppBarVariant.primary,
        // Filter button temporarily disabled
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.filter_list),
        //     onPressed: _showFilterDialog,
        //   ),
        // ],
      ),
      body: HintsWrapper(
        screenId: 'job_matching',
        child: _isLoading
            ? const Center(
                child: LoadingWidget(
                    message:
                        'Analyzing your CV and finding perfect matches...'),
              )
            : _matchedJobs.isEmpty
                ? _buildEmptyState()
                : _buildJobList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    // If user has a CV but no matches, show different message
    if (_hasCv) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No job matches found',
        message:
            'We couldn\'t find jobs matching your profile right now. Try updating your CV with more skills or check back later for new postings.',
        action: StandardButton(
          label: 'Update Your CV',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CVBuilderScreen()),
            );
            // Reload matches after returning from CV builder
            _loadMatchedJobs();
          },
          type: StandardButtonType.secondary,
          icon: Icons.edit,
        ),
      );
    }

    // If user has no CV at all, prompt them to create one
    return EmptyState(
      icon: Icons.auto_awesome,
      title: 'Build your CV first',
      message:
          'Complete your CV to get personalized job recommendations based on your skills and experience.',
      action: StandardButton(
        label: 'Build Your CV',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CVBuilderScreen()),
          );
          // Reload matches after returning from CV builder
          _loadMatchedJobs();
        },
        type: StandardButtonType.primary,
        icon: Icons.description,
      ),
    );
  }

  Widget _buildJobList() {
    return ListView.builder(
      padding: AppDesignSystem.paddingM,
      itemCount: _matchedJobs.length,
      itemBuilder: (context, index) {
        final job = _matchedJobs[index];
        final matchInfo = _matchDetails[job.jobId] ??
            {
              'score': 0,
              'reason': 'Calculating match details...',
              'missingSkills': [],
            };
        return _JobMatchCard(
          job: job,
          matchScore: matchInfo['score'] as int,
          reason: matchInfo['reason'] as String,
          missingSkills:
              List<String>.from(matchInfo['missingSkills'] as List? ?? []),
          onViewDetails: () {
            final user = _authService.getCurrentUser();
            if (user != null) {
              unawaited(
                _aiService.logJobInteraction(
                  userId: user.uid,
                  jobId: job.jobId,
                  event: 'opened',
                  source: 'job_matching',
                  metadata: {
                    'matchScore': matchInfo['score'],
                  },
                ),
              );
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobDetailsScreen(
                  id: job.employerId,
                  jobId: job.jobId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Filter functionality temporarily disabled
  // void _showFilterDialog() {
  //   // Will be implemented with advanced filtering options
  // }
}

class _JobMatchCard extends StatelessWidget {
  final JobModel job;
  final int matchScore;
  final String reason;
  final List<String> missingSkills;
  final VoidCallback onViewDetails;

  const _JobMatchCard({
    required this.job,
    required this.matchScore,
    required this.reason,
    required this.missingSkills,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: EdgeInsets.all(AppTheme.spacingM),
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
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Text(
                      job.employerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppDesignSystem.onSurfaceVariant(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: AppDesignSystem.paddingSymmetric(
                  horizontal: AppDesignSystem.spaceS,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getMatchColor(matchScore, context)
                      .withValues(alpha: 0.1),
                  borderRadius: AppDesignSystem.borderRadiusXL,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: _getMatchColor(matchScore, context),
                    ),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                    Text(
                      '$matchScore% Match',
                      style: TextStyle(
                        color: _getMatchColor(matchScore, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

          // AI Reasoning Section
          Container(
            padding: AppDesignSystem.paddingS,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: AppDesignSystem.borderRadiusM,
              border: Border.all(
                color: colorScheme.secondaryContainer,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: colorScheme.secondary),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                    Text(
                      'AI Insight',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                if (missingSkills.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    'Skills to improve:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: missingSkills
                        .map((skill) => Container(
                              padding: AppDesignSystem.paddingSymmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.error.withValues(alpha: 0.15),
                                borderRadius: AppDesignSystem.borderRadiusS,
                                border: Border.all(
                                  color:
                                      colorScheme.error.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                skill,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontSize: 10,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Wrap(
            spacing: 8,
            children: [
              if (job.location != null)
                Chip(
                  label: Text(job.location!),
                  avatar: const Icon(Icons.location_on, size: 16),
                ),
              if (job.jobType != null)
                Chip(
                  label: Text(job.jobType!),
                ),
              Chip(
                label: Text(job.category),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (job.salary != null)
                Text(
                  CurrencyFormatter.parseSalaryString(job.salary),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppDesignSystem.tertiary(context),
                  ),
                )
              else
                const SizedBox(),
              StandardButton(
                label: 'View Details',
                onPressed: onViewDetails,
                type: StandardButtonType.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int score, BuildContext context) {
    if (score >= 80) return AppDesignSystem.tertiary(context);
    if (score >= 60) return AppDesignSystem.secondary(context);
    return AppDesignSystem.warning;
  }
}
