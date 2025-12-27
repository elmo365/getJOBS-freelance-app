import 'package:flutter/material.dart';
import 'package:freelance_app/models/job_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/ui/category_rail.dart';
import 'package:freelance_app/widgets/ui/section_header.dart';
import 'package:freelance_app/widgets/cards/balance_hero_card.dart';
import 'package:freelance_app/widgets/ui/action_buttons_row.dart';
import 'package:freelance_app/widgets/ui/portfolio_section.dart';
import 'package:freelance_app/widgets/ui/tab_navigation_bar.dart';
import 'package:freelance_app/widgets/cards/list_item_card.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'cv_builder_screen.dart';
import 'job_matching_screen.dart';
import 'video_resume_screen.dart';
import 'career_tracker_screen.dart';
import 'mentorship_corner_screen.dart';
import 'application_management_screen.dart';
import 'career_roadmap_screen.dart';
import 'completed_jobs_seeker_screen.dart';
import 'package:freelance_app/screens/search/search_screen.dart';
import 'package:freelance_app/screens/homescreen/sidebar.dart';
import 'package:freelance_app/screens/homescreen/components/job_details.dart';
import 'package:freelance_app/screens/notifications/notifications_screen.dart';
import 'package:freelance_app/screens/plugins_hub/plugins_hub.dart'
    show PluginsHub;
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/ai/context_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/monetization_visibility_service.dart';
import 'package:freelance_app/screens/wallet/user_wallet_screen.dart';
import 'package:freelance_app/services/wallet_service.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';

class JobSeekersHomeScreen extends StatefulWidget {
  const JobSeekersHomeScreen({super.key});

  @override
  State<JobSeekersHomeScreen> createState() => _JobSeekersHomeScreenState();
}

class _JobSeekersHomeScreenState extends State<JobSeekersHomeScreen> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  final _aiService = GeminiAIService();
  final _walletService = WalletService();
  final _monetizationService = MonetizationVisibilityService();
  final _notificationService = NotificationService();
  String? _userId;
  late Future<List<_RecommendedJob>> _recommendedJobsFuture;
  int _applicationsCount = 0;
  int _selectedTabIndex = 0; // For tab navigation
  bool _isWalletVisible = false;
  double _walletBalance = 0.0;
  bool _hasCV = false;
  int _recommendationCount = 0;

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
    _recommendedJobsFuture = _loadRecommendedJobs();
    _loadStats();
    _checkMonetizationVisibility();
    _checkCVStatus();
  }

  Future<void> _checkCVStatus() async {
    if (_userId == null) return;
    try {
      final userDoc = await _dbService.getUser(_userId!);
      final userData = userDoc?.data() as Map<String, dynamic>?;
      final hasCV = userData?['cv_url'] != null ||
          userData?['cvUrl'] != null ||
          userData?['has_cv'] == true;
      if (mounted) {
        setState(() {
          _hasCV = hasCV == true;
        });
      }
    } catch (e) {
      debugPrint('Error checking CV status: $e');
    }
  }

  Future<void> _checkMonetizationVisibility() async {
    final isVisible = await _monetizationService.isWalletVisible();
    if (isVisible && _userId != null) {
      try {
        final wallet = await _walletService.getWallet(_userId!);
        if (mounted) {
          setState(() {
            _isWalletVisible = true;
            _walletBalance = wallet.balance;
          });
        }
      } catch (e) {
        debugPrint('Error loading wallet: $e');
        if (mounted) {
          setState(() {
            _isWalletVisible = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isWalletVisible = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    if (_userId == null) return;

    try {
      // Load applications count
      final applications =
          await _dbService.getApplicationsByUser(userId: _userId!);
      _applicationsCount = applications.docs.length;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<List<_RecommendedJob>> _loadRecommendedJobs() async {
    final jobsSnapshot = await _dbService.getActiveJobs(limit: 50);
    final allJobs = jobsSnapshot.docs
        .map((doc) => _JobDoc(
              id: doc.id,
              data: (doc.data() as Map<String, dynamic>?) ?? const {},
            ))
        .toList();

    if (_userId == null) {
      // Return empty list if user not logged in - AI requires user context
      return [];
    }

    try {
      // Use ContextService to build the profile
      final userProfile =
          await ContextService().buildUserProfileContext(_userId!);

      // If profile is empty/failed, AI cannot work without profile
      if (userProfile.isEmpty || userProfile['error'] != null) {
        debugPrint(
            'Cannot generate AI recommendations: User profile unavailable');
        return [];
      }

      final prefiltered = _prefilterJobs(
        userSkills:
            (userProfile['skills'] as List<dynamic>? ?? []).cast<String>(),
        jobs: allJobs,
        limit: 25,
      );

      if (prefiltered.isEmpty) {
        return [];
      }

      final aiJobs = prefiltered.map((job) => _jobToAiMap(job)).toList();
      debugPrint('📤 [Recommended Jobs] Sending ${aiJobs.length} jobs to AI');
      debugPrint(
          '📤 [Recommended Jobs] Sample job: ${aiJobs.isNotEmpty ? aiJobs.first['jobId'] : 'none'}');

      final ranked = await _aiService.recommendJobsForUser(
        userId: _userId!,
        userProfile: userProfile,
        availableJobs: aiJobs,
      );

      debugPrint(
          '📥 [Recommended Jobs] AI returned ${ranked.length} ranked jobs');
      if (ranked.isNotEmpty) {
        debugPrint(
            '📥 [Recommended Jobs] Sample result: jobId=${ranked.first['jobId']}, score=${ranked.first['matchScore']}');
      }

      if (ranked.isEmpty) {
        debugPrint('⚠️ [Recommended Jobs] No ranked jobs returned from AI');
        return [];
      }

      final byId = {for (final j in prefiltered) j.id: j};
      debugPrint(
          '🔍 [Recommended Jobs] Created lookup map with ${byId.length} jobs');
      debugPrint(
          '🔍 [Recommended Jobs] Sample keys: ${byId.keys.take(3).toList()}');

      final results = <_RecommendedJob>[];
      for (final item in ranked.take(5)) {
        // Backend always returns 'jobId' (normalized from AI response)
        final jobId = (item['jobId'] as String? ?? '').toString();
        if (jobId.isEmpty) {
          debugPrint(
              '⚠️ [Recommended Jobs] Skipping item with empty jobId: $item');
          continue;
        }
        final doc = byId[jobId];
        if (doc == null) {
          debugPrint('⚠️ [Recommended Jobs] Job not found in byId map: $jobId');
          debugPrint(
              '⚠️ [Recommended Jobs] Available keys: ${byId.keys.take(5).toList()}');
          continue;
        }

        final scoreRaw = item['matchScore'];
        final score = (scoreRaw is num)
            ? scoreRaw.round()
            : int.tryParse(scoreRaw?.toString() ?? '') ?? 0;

        results.add(
          _RecommendedJob(
            job: JobModel.fromMap(doc.data, doc.id),
            contactEmail: (doc.data['email'] as String?) ?? '',
            matchScore: score.clamp(0, 100),
            reason: (item['reason'] ?? '').toString(),
          ),
        );
      }

      // Update recommendation count
      if (mounted) {
        setState(() {
          _recommendationCount = results.length;
        });
      }

      return results;
    } catch (e) {
      debugPrint('Error in AI recommendation pipeline: $e');
      // Return empty list - AI failed, no fallback
      return [];
    }
  }

  // NOTE: _buildUserProfile removed in favor of ContextService

  List<_JobDoc> _prefilterJobs({
    required List<String> userSkills,
    required List<_JobDoc> jobs,
    required int limit,
  }) {
    if (userSkills.isEmpty) {
      return jobs.take(limit).toList();
    }

    final skillSet = userSkills
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final scored = jobs.map((job) {
      final text = [
        (job.data['title'] ?? '').toString(),
        (job.data['description'] ?? job.data['desc'] ?? '').toString(),
        (job.data['category'] ?? job.data['jobCategory'] ?? '').toString(),
      ].join(' ').toLowerCase();

      final hits = skillSet.where(text.contains).length;
      return {'job': job, 'hits': hits};
    }).toList();

    scored.sort((a, b) => (b['hits'] as int).compareTo(a['hits'] as int));
    return scored
        .take(limit)
        .map((e) => e['job'] as _JobDoc)
        .toList(growable: false);
  }

  Map<String, dynamic> _jobToAiMap(_JobDoc job) {
    final data = job.data;
    final description = (data['description'] ?? data['desc'] ?? '').toString();
    final snippet =
        description.length > 450 ? description.substring(0, 450) : description;

    // Ensure jobId is always the document ID (consistent with JobModel)
    final jobId = job.id;
    final employerId = (data['userId'] ?? data['employerId'] ?? '').toString();

    // Build job map matching backend expectations exactly
    // Backend line 593: jobId: String(j.jobId || j.id || '')
    // We always send jobId (document ID), so 'id' fallback is unnecessary but harmless
    final jobMap = {
      'jobId': jobId, // Document ID - backend expects this (line 593)
      'title': (data['title'] ?? '').toString(),
      'category': (data['category'] ?? data['jobCategory'] ?? '').toString(),
      'location': (data['location'] ?? data['address'] ?? '').toString(),
      'experienceLevel':
          (data['experienceLevel'] ?? data['experience_level'] ?? '')
              .toString(),
      'jobType': (data['jobType'] ?? data['job_type'] ?? '').toString(),
      'requiredSkills': (data['requiredSkills'] ??
              data['required_skills'] ??
              const []) is List
          ? List<String>.from(
              data['requiredSkills'] ?? data['required_skills'] ?? const [])
          : const <String>[],
      'descriptionSnippet': snippet,
      'employerId': employerId, // Needed for fetching company ratings
      'userId': employerId, // Alternative field name for backend compatibility
    };

    // Validate critical fields
    if (jobMap['jobId'] == null || (jobMap['jobId'] as String).isEmpty) {
      debugPrint(
          '❌ [Recommended Jobs] Invalid jobId for job: ${jobMap['title']}');
    }

    return jobMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          botsSuperLightGrey, // Super light grey background for card contrast
      drawer: const SideBar(),
      body: HintsWrapper(
        screenId: 'job_seekers_home',
        child: SafeArea(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  // Top Section: Search & Menu
                  Padding(
                    padding: AppDesignSystem.paddingSymmetric(
                        horizontal: AppDesignSystem.spaceL,
                        vertical: AppDesignSystem.spaceM),
                    child: Row(
                      children: [
                        // Menu Button
                        Container(
                          decoration: BoxDecoration(
                            color: botsWhite,
                            borderRadius: AppDesignSystem.borderRadiusM,
                            boxShadow: AppDesignSystem.cardShadow,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            color: botsTextPrimary,
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        // Notification Button Only (Search removed as requested)
                        StreamBuilder<int>(
                          stream: _getUnreadCount(),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: botsWhite,
                                    borderRadius: AppDesignSystem.borderRadiusM,
                                    boxShadow: AppDesignSystem.cardShadow,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.notifications_outlined),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationsScreen(),
                                        ),
                                      );
                                    },
                                    color: botsTextPrimary,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppDesignSystem.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: botsWhite, width: 2),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        count > 9 ? '9+' : count.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content - Matching banner-image_home.png layout
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Balance Hero Card and Action Buttons - Only show if monetization is enabled
                          if (_isWalletVisible) ...[
                            Padding(
                              padding: AppDesignSystem.paddingHorizontal(
                                  AppDesignSystem.spaceL),
                              child: BalanceHeroCard(
                                title: 'Your current balance',
                                value:
                                    CurrencyFormatter.formatBWP(_walletBalance),
                                onVisibilityToggle: () {
                                  // Toggle visibility logic
                                },
                              ),
                            ),
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceM),
                            // Action Buttons Row - Maps to Deposit and History buttons
                            // Withdraw option removed - not available for any users
                            Padding(
                              padding: AppDesignSystem.paddingHorizontal(
                                  AppDesignSystem.spaceL),
                              child: ActionButtonsRow(
                                onDeposit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const UserWalletScreen()),
                                  );
                                },
                                onHistory: () {
                                  // Navigate to wallet screen which shows transaction history
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const UserWalletScreen()),
                                  );
                                },
                              ),
                            ),
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceXL),
                          ],

                          // My Portfolio Section - Maps to horizontal scrollable cards in image
                          PortfolioSection(
                            title: 'My Portfolio',
                            items: [
                              PortfolioCardData(
                                title: 'Applications',
                                value: '$_applicationsCount',
                                subtitle: 'Pending reviews',
                                icon: Icons.work_outline,
                                iconColor: AppDesignSystem.brandBlue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ApplicationManagementJobSeekerScreen()),
                                  );
                                },
                              ),
                              PortfolioCardData(
                                title: 'Smart Matching',
                                value: _recommendationCount > 0
                                    ? '$_recommendationCount'
                                    : 'AI',
                                subtitle: _recommendationCount > 0
                                    ? 'Recommendations'
                                    : 'Loading...',
                                icon: Icons.auto_awesome,
                                iconColor: AppDesignSystem.brandGreen,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const JobMatchingScreen()),
                                  );
                                },
                              ),
                              PortfolioCardData(
                                title: 'CV Builder',
                                value: _hasCV ? 'Ready' : 'Build',
                                subtitle:
                                    _hasCV ? 'CV Complete' : 'Build your CV',
                                icon: Icons.description,
                                iconColor: AppDesignSystem.brandYellow,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CVBuilderScreen()),
                                  );
                                },
                              ),
                              PortfolioCardData(
                                title: 'Completed Jobs',
                                value: 'View',
                                subtitle: 'Rate companies',
                                icon: Icons.check_circle,
                                iconColor: AppDesignSystem.brandGreen,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CompletedJobsSeekerScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                          AppDesignSystem.verticalSpace(
                              AppDesignSystem.spaceXL),

                          // Tools Section - Using CategoryRail for horizontal scrolling
                          SectionHeader(title: 'Tools'),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                          CategoryRail(
                            items: [
                              CategoryItem(
                                id: 'cv_builder',
                                label: 'CV Builder',
                                icon: Icons.description,
                                color: AppDesignSystem.brandBlue,
                              ),
                              CategoryItem(
                                id: 'applications',
                                label: 'History',
                                icon: Icons.history,
                                color: AppDesignSystem.brandYellow,
                              ),
                              CategoryItem(
                                id: 'tracker',
                                label: 'Tracker',
                                icon: Icons.track_changes,
                                color: AppDesignSystem.brandGreen,
                              ),
                              CategoryItem(
                                id: 'mentorship',
                                label: 'Mentors',
                                icon: Icons.people,
                                color: AppDesignSystem.brandBlue,
                              ),
                              CategoryItem(
                                id: 'video',
                                label: 'Video CV',
                                icon: Icons.videocam,
                                color: AppDesignSystem.brandYellow,
                              ),
                              CategoryItem(
                                id: 'roadmap',
                                label: 'Roadmap',
                                icon: Icons.rocket_launch,
                                color: AppDesignSystem.brandBlue,
                              ),
                              CategoryItem(
                                id: 'plugins',
                                label: 'Plugins',
                                icon: Icons.extension,
                                color: AppDesignSystem.brandGreen,
                              ),
                            ],
                            onItemSelected: (id) {
                              switch (id) {
                                case 'cv_builder':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CVBuilderScreen()));
                                  break;
                                case 'applications':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ApplicationManagementJobSeekerScreen()));
                                  break;
                                case 'tracker':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CareerTrackerScreen()));
                                  break;
                                case 'mentorship':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MentorshipCornerScreen()));
                                  break;
                                case 'video':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const VideoResumeScreen()));
                                  break;
                                case 'roadmap':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CareerRoadmapScreen()));
                                  break;
                                case 'plugins':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const PluginsHub()));
                                  break;
                              }
                            },
                          ),
                          AppDesignSystem.verticalSpace(
                              AppDesignSystem.spaceXL),

                          // Recommended Jobs Section with Tabs - Maps to "Trade Crypto" section in image
                          Padding(
                            padding: AppDesignSystem.paddingHorizontal(
                                AppDesignSystem.spaceL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recommended For You',
                                      style:
                                          AppDesignSystem.headlineSmall(context)
                                              .copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const Search()),
                                        );
                                      },
                                      child: Text(
                                        'See all',
                                        style:
                                            AppDesignSystem.bodySmall(context)
                                                .copyWith(
                                          color: AppDesignSystem.brandBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AppDesignSystem.verticalSpace(
                                    AppDesignSystem.spaceM),
                                // Tab Navigation - Only show when there are recommendations
                                FutureBuilder<List<_RecommendedJob>>(
                                  future: _recommendedJobsFuture,
                                  builder: (context, snapshot) {
                                    final items = snapshot.data ?? [];
                                    if (items.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return TabNavigationBar(
                                      tabs: const [
                                        'Job Title',
                                        'Location',
                                        'Match Score',
                                        'Experience',
                                      ],
                                      selectedIndex: _selectedTabIndex,
                                      onTabChanged: (index) {
                                        setState(() {
                                          _selectedTabIndex = index;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                          // Jobs List - Using ListItemCard for clean list style
                          FutureBuilder<List<_RecommendedJob>>(
                            future: _recommendedJobsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final items = snapshot.data ?? [];
                              if (items.isEmpty) {
                                return Padding(
                                  padding: AppDesignSystem.paddingL,
                                  child: Column(
                                    children: [
                                      AppDesignSystem.verticalSpace(
                                          AppDesignSystem.spaceXL),
                                      Icon(
                                        Icons.auto_awesome_outlined,
                                        size: 64,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                      AppDesignSystem.verticalSpace(
                                          AppDesignSystem.spaceM),
                                      Text(
                                        "No recommendations yet",
                                        style:
                                            AppDesignSystem.titleMedium(context)
                                                .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      AppDesignSystem.verticalSpace(
                                          AppDesignSystem.spaceS),
                                      Text(
                                        "Complete your profile to get personalized job recommendations",
                                        textAlign: TextAlign.center,
                                        style:
                                            AppDesignSystem.bodySmall(context)
                                                .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      AppDesignSystem.verticalSpace(
                                          AppDesignSystem.spaceL),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: items.map((item) {
                                  return ListItemCard(
                                    title: item.job.title,
                                    value: item.job.location ??
                                        'Location not specified',
                                    percentageChange: item.matchScore > 0
                                        ? '+${item.matchScore}%'
                                        : null,
                                    isPositive: item.matchScore > 0,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppDesignSystem.brandBlue
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.work_outline,
                                        color: AppDesignSystem.brandBlue,
                                        size: 20,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => JobDetailsScreen(
                                            id: item.job.employerId,
                                            jobId: item.job.jobId,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          AppDesignSystem.verticalSpace(
                              AppDesignSystem.spaceXXL *
                                  1.67), // Bottom spacing
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JobDoc {
  final String id;
  final Map<String, dynamic> data;

  const _JobDoc({
    required this.id,
    required this.data,
  });
}

class _RecommendedJob {
  final JobModel job;
  final String contactEmail;
  final int matchScore;
  final String reason;

  const _RecommendedJob({
    required this.job,
    required this.contactEmail,
    required this.matchScore,
    required this.reason,
  });
}
