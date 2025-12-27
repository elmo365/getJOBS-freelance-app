import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class InterviewCoachScreen extends StatefulWidget {
  final String? jobTitle;
  final String? company;
  final List<String>? skills;

  const InterviewCoachScreen({
    super.key,
    this.jobTitle,
    this.company,
    this.skills,
  });

  @override
  State<InterviewCoachScreen> createState() => _InterviewCoachScreenState();
}

class _InterviewCoachScreenState extends State<InterviewCoachScreen>
    with ConnectivityAware {
  final _aiService = GeminiAIService();
  final _answerController = TextEditingController();
  final _jobTitleController = TextEditingController();

  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isLoadingQuestions = false;
  bool _isEvaluating = false;
  Map<String, dynamic>? _currentEvaluation;
  String _selectedLevel = 'mid';

  @override
  void initState() {
    super.initState();
    _jobTitleController.text = widget.jobTitle ?? '';
    if (widget.jobTitle != null) {
      _loadQuestions();
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (_jobTitleController.text.trim().isEmpty) {
      SnackbarHelper.showWarning(context, 'Please enter a job title');
      return;
    }

    if (!await checkConnectivity(context)) return;

    setState(() {
      _isLoadingQuestions = true;
      _questions = [];
      _currentQuestionIndex = 0;
      _currentEvaluation = null;
    });

    try {
      final questions = await _aiService.generateInterviewQuestions(
        jobTitle: _jobTitleController.text.trim(),
        company: widget.company ?? 'the company',
        skills: widget.skills ?? [],
        level: _selectedLevel,
        count: 5,
      );

      setState(() {
        _questions = questions;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to generate questions');
      }
    }
  }

  Future<void> _evaluateAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      SnackbarHelper.showWarning(context, 'Please enter your answer first');
      return;
    }

    if (!await checkConnectivity(context)) return;

    setState(() => _isEvaluating = true);

    try {
      final currentQuestion = _questions[_currentQuestionIndex];
      final evaluation = await _aiService.evaluateInterviewAnswer(
        question: currentQuestion['question'] as String,
        answer: _answerController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        category: currentQuestion['category'] as String? ?? 'behavioral',
      );

      setState(() {
        _currentEvaluation = evaluation;
        _isEvaluating = false;
      });
    } catch (e) {
      setState(() => _isEvaluating = false);
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to evaluate answer');
      }
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.clear();
        _currentEvaluation = null;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _answerController.clear();
        _currentEvaluation = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'interview_coach',
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: 'AI Interview Coach',
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                              gradient: AppDesignSystem.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                  AppDesignSystem.radiusM),
                            ),
                            child: Icon(
                              Icons.psychology,
                              color: AppDesignSystem.surface(context),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppDesignSystem.spaceM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Practice Interview',
                                  style: AppDesignSystem.titleLarge(context),
                                ),
                                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                                Text(
                                  'Get AI-powered feedback on your answers',
                                  style: AppDesignSystem.bodySmall(context)
                                      .copyWith(color: AppDesignSystem.outline(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignSystem.spaceL),
                      // Job title input
                      TextField(
                        controller: _jobTitleController,
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          hintText: 'e.g., Software Developer',
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDesignSystem.radiusM),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesignSystem.spaceM),
                      // Experience level
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Experience Level',
                          prefixIcon: const Icon(Icons.trending_up),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDesignSystem.radiusM),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'entry', child: Text('Entry Level')),
                          DropdownMenuItem(
                              value: 'mid', child: Text('Mid Level')),
                          DropdownMenuItem(
                              value: 'senior', child: Text('Senior Level')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLevel = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppDesignSystem.spaceL),
                      // Start button
                      SizedBox(
                        width: double.infinity,
                        child: MicroInteractions.scaleCard(
                          child: FilledButton.icon(
                            onPressed:
                                _isLoadingQuestions ? null : _loadQuestions,
                            icon: _isLoadingQuestions
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppDesignSystem.surface(context),
                                    ),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: Text(_isLoadingQuestions
                                ? 'Generating Questions...'
                                : 'Start Practice'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Questions section
            if (_questions.isNotEmpty) ...[
              const SizedBox(height: AppDesignSystem.spaceXL),
              MicroInteractions.fadeInListItem(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    Row(
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                          style: AppDesignSystem.titleMedium(context),
                        ),
                        const Spacer(),
                        _buildCategoryChip(
                          _questions[_currentQuestionIndex]['category']
                                  as String? ??
                              'general',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDesignSystem.spaceS),
                    LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _questions.length,
                      borderRadius:
                          BorderRadius.circular(AppDesignSystem.radiusS),
                      minHeight: 6,
                    ),
                    const SizedBox(height: AppDesignSystem.spaceL),

                    // Question card
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDesignSystem.spaceL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: AppDesignSystem.paddingS,
                                  decoration: BoxDecoration(
                                    color: AppDesignSystem.primary(context)
                                        .withValues(alpha: 0.1),
                                    borderRadius: AppDesignSystem.borderRadiusS,
                                  ),
                                  child: Icon(
                                    Icons.help_outline,
                                    color: AppDesignSystem.primary(context),
                                  ),
                                ),
                                const SizedBox(width: AppDesignSystem.spaceM),
                                Expanded(
                                  child: Text(
                                    _questions[_currentQuestionIndex]
                                            ['question'] as String? ??
                                        '',
                                    style: AppDesignSystem.titleMedium(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDesignSystem.spaceM),
                            Text(
                              'Looking for: ${_questions[_currentQuestionIndex]['lookingFor'] ?? ''}',
                              style: AppDesignSystem.bodySmall(context)
                                  .copyWith(color: AppDesignSystem.outline(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spaceL),

                    // Answer input
                    Text(
                      'Your Answer',
                      style: AppDesignSystem.titleSmall(context),
                    ),
                    const SizedBox(height: AppDesignSystem.spaceS),
                    TextField(
                      controller: _answerController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'Type your answer here... Be specific and use examples.',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.radiusM),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spaceM),

                    // Evaluate button
                    SizedBox(
                      width: double.infinity,
                      child: MicroInteractions.scaleCard(
                        child: FilledButton.icon(
                          onPressed: _isEvaluating ? null : _evaluateAnswer,
                          icon: _isEvaluating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppDesignSystem.surface(context),
                                  ),
                                )
                              : const Icon(Icons.rate_review),
                          label: Text(_isEvaluating
                              ? 'Evaluating...'
                              : 'Get AI Feedback'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Evaluation results
            if (_currentEvaluation != null) ...[
              const SizedBox(height: AppDesignSystem.spaceXL),
              MicroInteractions.fadeInListItem(
                index: 2,
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignSystem.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Feedback',
                              style: AppDesignSystem.titleLarge(context),
                            ),
                            const Spacer(),
                            _buildScoreBadge(
                              _currentEvaluation!['score'] as int? ?? 5,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDesignSystem.spaceL),

                        // Strengths
                        _buildFeedbackSection(
                          context,
                          icon: Icons.thumb_up,
                          iconColor: AppDesignSystem.success,
                          title: 'Strengths',
                          items: (_currentEvaluation!['strengths']
                                  as List<dynamic>?)
                              ?.cast<String>(),
                        ),
                        const SizedBox(height: AppDesignSystem.spaceM),

                        // Improvements
                        _buildFeedbackSection(
                          context,
                          icon: Icons.lightbulb,
                          iconColor: AppDesignSystem.warning,
                          title: 'Areas to Improve',
                          items: (_currentEvaluation!['improvements']
                                  as List<dynamic>?)
                              ?.cast<String>(),
                        ),
                        const SizedBox(height: AppDesignSystem.spaceM),

                        // General feedback
                        Text(
                          'Overall Feedback',
                          style: AppDesignSystem.titleSmall(context),
                        ),
                        const SizedBox(height: AppDesignSystem.spaceS),
                        Text(
                          _currentEvaluation!['feedback'] as String? ?? '',
                          style: AppDesignSystem.bodyMedium(context),
                        ),

                        // Suggested answer
                        if ((_currentEvaluation!['revisedAnswer'] as String?)
                                ?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: AppDesignSystem.spaceL),
                          Container(
                            padding:
                                const EdgeInsets.all(AppDesignSystem.spaceM),
                            decoration: BoxDecoration(
                                  color:
                                  AppDesignSystem.primary(context).withValues(alpha: 0.05),
                              borderRadius: AppDesignSystem.borderRadiusM,
                              border: Border.all(
                                color:
                                    AppDesignSystem.primary(context).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high,
                                      color: AppDesignSystem.primary(context),
                                      size: 18,
                                    ),
                                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                                    Text(
                                      'Suggested Answer',
                                      style: AppDesignSystem.titleSmall(context)
                                          .copyWith(color: colorScheme.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppDesignSystem.spaceS),
                                Text(
                                  _currentEvaluation!['revisedAnswer']
                                      as String,
                                  style: AppDesignSystem.bodyMedium(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Navigation buttons
            if (_questions.isNotEmpty) ...[
              const SizedBox(height: AppDesignSystem.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed:
                        _currentQuestionIndex > 0 ? _previousQuestion : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  TextButton.icon(
                    onPressed: _currentQuestionIndex < _questions.length - 1
                        ? _nextQuestion
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppDesignSystem.spaceXL),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    IconData icon;
    switch (category.toLowerCase()) {
      case 'technical':
        color = AppDesignSystem.primary(context);
        icon = Icons.code;
        break;
      case 'behavioral':
        color = AppDesignSystem.tertiary(context);
        icon = Icons.psychology;
        break;
      case 'situational':
        color = AppDesignSystem.secondary(context);
        icon = Icons.lightbulb;
        break;
      default:
        color = AppDesignSystem.primary(context);
        icon = Icons.groups;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusL,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS - 2),
          Text(
            category.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    Color color;
    if (score >= 8) {
      color = AppDesignSystem.success;
    } else if (score >= 6) {
      color = AppDesignSystem.warning;
    } else {
      color = AppDesignSystem.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusXL,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '/10',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    List<String>? items,
  }) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
            Text(title, style: AppDesignSystem.titleSmall(context)),
          ],
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      item,
                      style: AppDesignSystem.bodyMedium(context),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
