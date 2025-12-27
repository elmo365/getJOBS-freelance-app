import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({super.key});

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen>
    with ConnectivityAware {
  final _aiService = GeminiAIService();
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _targetRoleController = TextEditingController();

  Map<String, dynamic>? _roadmapData;
  bool _isGenerating = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _targetRoleController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    try {
      final cvDoc = await _dbService.getCVByUserId(user.uid);
      if (cvDoc != null) {
        setState(() {
          _userProfile = cvDoc.data() as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _generateRoadmap() async {
    if (_targetRoleController.text.trim().isEmpty) {
      SnackbarHelper.showWarning(context, 'Please enter a target job title');
      return;
    }

    if (!await checkConnectivity(context)) return;

    setState(() {
      _isGenerating = true;
      _roadmapData = null;
    });

    try {
      final roadmap = await _aiService.generateCareerRoadmap(
        userProfile: _userProfile ?? {'status': 'No CV found'},
        targetRole: _targetRoleController.text.trim(),
      );

      setState(() {
        _roadmapData = roadmap;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        // User-friendly error message
        String errorMessage = 'Unable to generate your career roadmap right now. ';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('not ready') || errorStr.contains('not configured')) {
          errorMessage += 'AI service is currently unavailable. Please try again later.';
        } else if (errorStr.contains('quota') || errorStr.contains('limit')) {
          errorMessage += 'AI service is temporarily busy. Please try again in a few moments.';
        } else if (errorStr.contains('network') || errorStr.contains('connection')) {
          errorMessage += 'Please check your internet connection and try again.';
        } else {
          errorMessage += 'Please try again. If the problem continues, contact support.';
        }
        
        SnackbarHelper.showError(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'career_roadmap',
      child: Scaffold(
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      appBar: AppAppBar(
        title: 'AI Career Roadmap',
        variant: AppBarVariant.primary, // Blue background with white text
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            MicroInteractions.fadeInListItem(
              index: 0,
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignSystem.spaceL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: AppDesignSystem.paddingM,
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDesignSystem.radiusM),
                            ),
                            child: Icon(Icons.map,
                                color: colorScheme.secondary, size: 28),
                          ),
                          const SizedBox(width: AppDesignSystem.spaceM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Future Path',
                                  style: AppDesignSystem.titleLarge(context),
                                ),
                                Text(
                                  'Tell us your dream job, and we\'ll map the way.',
                                  style: AppDesignSystem.bodySmall(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignSystem.spaceL),
                      TextField(
                        controller: _targetRoleController,
                        scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Target Job Title',
                          hintText: 'e.g., Senior CTO, Product Manager',
                          prefixIcon: const Icon(Icons.stars),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDesignSystem.radiusM),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesignSystem.spaceM),
                      SizedBox(
                        width: double.infinity,
                        child: MicroInteractions.scaleCard(
                          child: FilledButton.icon(
                            onPressed: _isGenerating ? null : _generateRoadmap,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isGenerating
                                ? 'Mapping Path...'
                                : 'Generate Roadmap'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_roadmapData != null) ...[
              const SizedBox(height: AppDesignSystem.spaceXL),

              // Key Stats
              MicroInteractions.fadeInListItem(
                index: 1,
                child: Row(
                  children: [
                    _buildStatCard(
                      context,
                      'Duration',
                      _roadmapData!['totalEstimatedTime'] ?? 'N/A',
                      Icons.timer_outlined,
                      colorScheme.primary,
                    ),
                    const SizedBox(width: AppDesignSystem.spaceM),
                    _buildStatCard(
                      context,
                      'Outcome',
                      'Market Ready',
                      Icons.check_circle_outline,
                      colorScheme.tertiary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDesignSystem.spaceXL),
              Text('Career Milestones',
                  style: AppDesignSystem.titleLarge(context)),
              const SizedBox(height: AppDesignSystem.spaceM),

              // Milestones List
              ...(_roadmapData!['milestones'] as List<dynamic>? ?? [])
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final milestone = entry.value as Map<String, dynamic>;
                return MicroInteractions.fadeInListItem(
                  index: index + 2,
                  child: _buildMilestoneStep(
                      context,
                      milestone,
                      index ==
                          (_roadmapData!['milestones'] as List).length - 1),
                );
              }),

              const SizedBox(height: AppDesignSystem.spaceXL),

              // Market Insights
              MicroInteractions.fadeInListItem(
                index: 10,
                child: AppCard(
                  variant: SurfaceVariant.standard,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignSystem.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Market Outlook',
                            style: AppDesignSystem.titleMedium(context)),
                        const SizedBox(height: 8),
                        Text(_roadmapData!['marketOutlook'] ?? '',
                            style: AppDesignSystem.bodyMedium(context)),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        Text('Salary Progression',
                            style: AppDesignSystem.titleMedium(context)),
                        const SizedBox(height: 8),
                        Text(_roadmapData!['salaryProgression'] ?? '',
                            style: AppDesignSystem.bodyMedium(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppDesignSystem.spaceXL * 2),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Expanded(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spaceM),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(value,
                  style: AppDesignSystem.titleMedium(context)
                      .copyWith(color: color, fontWeight: FontWeight.bold)),
              Text(label, style: AppDesignSystem.labelSmall(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneStep(
      BuildContext context, Map<String, dynamic> milestone, bool isLast) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                    child: Icon(Icons.flag, color: Colors.white, size: 16)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppDesignSystem.spaceM),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDesignSystem.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(milestone['title'] ?? '',
                      style: AppDesignSystem.titleMedium(context)
                          .copyWith(fontWeight: FontWeight.bold)),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(milestone['estimatedDuration'] ?? '',
                      style: AppDesignSystem.labelSmall(context)
                          .copyWith(color: colorScheme.secondary)),
                  const SizedBox(height: 8),
                  Text(milestone['description'] ?? '',
                      style: AppDesignSystem.bodyMedium(context)),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),

                  // Skills
                  if (milestone['skillsToLearn'] != null) ...[
                    Wrap(
                      spacing: 4,
                      children: (milestone['skillsToLearn'] as List<dynamic>)
                          .map((s) => Chip(
                                label: Text(s.toString(),
                                    style: const TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  ],

                  // Resources
                  if (milestone['recommendedResources'] != null) ...[
                    Container(
                      padding: AppDesignSystem.paddingS,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: AppDesignSystem.borderRadiusS,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.library_books,
                                  size: 14, color: colorScheme.primary),
                              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                              const Text('Learning Resources',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          AppDesignSystem.verticalSpace(6),
                          ...(milestone['recommendedResources']
                                  as List<dynamic>)
                              .map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text('• ${r.toString()}',
                                        style: const TextStyle(fontSize: 11)),
                                  )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
