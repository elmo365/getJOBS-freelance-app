import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/models/interview_model.dart';
import 'package:freelance_app/models/interview_prep_model.dart';
import 'package:freelance_app/services/interview_coach_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';

class InterviewPrepScreen extends StatefulWidget {
  final InterviewModel interview;
  final String jobTitle;
  final String jobDescription;

  const InterviewPrepScreen({
    super.key,
    required this.interview,
    required this.jobTitle,
    required this.jobDescription,
  });

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _prepSessionId;
  InterviewPrepSession? _prepSession;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _prepSessionId = '${widget.interview.interviewId}_${FirebaseAuth.instance.currentUser?.uid}';
    _initializePrepSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializePrepSession() async {
    try {
      final session = await InterviewCoachService.getOrCreatePrepSession(
        prepSessionId: _prepSessionId,
        interviewId: widget.interview.interviewId,
      );
      setState(() {
        _prepSession = session;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load prep session: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prepare for Interview'),
        centerTitle: true,
        backgroundColor: AppDesignSystem.brandGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializePrepSession,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Interview Summary Card
                    Container(
                      color: AppDesignSystem.brandGreen.withValues(alpha: 0.1),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.jobTitle,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                              color: AppDesignSystem.brandGreen,
                                ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${widget.interview.employerName} • ${widget.interview.medium}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_prepSession != null) ...[
                            SizedBox(height: 12),
                            _buildProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppDesignSystem.brandGreen,
                      labelColor: AppDesignSystem.brandGreen,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'Job Analysis'),
                        Tab(text: 'Tips'),
                        Tab(text: 'Practice'),
                        Tab(text: 'Mock'),
                      ],
                    ),
                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildJobAnalysisTab(),
                          _buildTipsTab(),
                          _buildPracticeTab(),
                          _buildMockInterviewTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Build progress indicator
  Widget _buildProgressIndicator() {
    if (_prepSession == null) return SizedBox.shrink();

    final completedCount = _prepSession!.completedSections.length;
    final totalSections = 4;
    final progress = completedCount / totalSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress: $completedCount/$totalSections sections completed',
                style: Theme.of(context).textTheme.bodySmall),
            Text('${(progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppDesignSystem.brandGreen,
                    )),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.brandGreen),
          ),
        ),
      ],
    );
  }

  // Job Analysis Tab
  Widget _buildJobAnalysisTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: FutureBuilder<JobAnalysisData>(
        future: InterviewCoachService.generateJobAnalysis(
          interview: widget.interview,
          jobTitle: widget.jobTitle,
          jobDescription: widget.jobDescription,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading analysis'));
          }

          final analysis = snapshot.data;
          if (analysis == null) return Center(child: Text('No analysis available'));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard('Key Skills Needed', analysis.keySkillsNeeded),
              SizedBox(height: 16),
              _buildSectionCard('Likely Interview Questions', analysis.likelyInterviewQuestions),
              SizedBox(height: 16),
              _buildInfoCard('Salary Range', analysis.salaryRange),
              SizedBox(height: 16),
              _buildSectionCard('Company Highlights', analysis.companyHighlights),
              SizedBox(height: 16),
              _buildInfoCard('Industry Insights', analysis.industryInsights),
              SizedBox(height: 16),
              _buildSectionCard('Common Challenges in this Role', analysis.commonChallenges),
            ],
          );
        },
      ),
    );
  }

  // Tips Tab
  Widget _buildTipsTab() {
    final tips = InterviewCoachService.getInterviewTips(widget.interview.medium);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipsSection('Before Interview', tips.beforeInterviewChecklist),
          SizedBox(height: 16),
          _buildTipsSection('Technical Tips', tips.technicalTips),
          SizedBox(height: 16),
          _buildTipsSection('Behavioral Tips', tips.behavioralTips),
          SizedBox(height: 16),
          _buildTipsSection('${widget.interview.medium.capitalize()} Interview Tips', tips.mediaTips),
          SizedBox(height: 16),
          _buildTipsSection('Do\'s and Don\'ts', tips.doDontsList),
          SizedBox(height: 16),
          _buildTipsSection('During Interview', tips.duringInterviewTips),
          SizedBox(height: 16),
          _buildTipsSection('After Interview', tips.afterInterviewTips),
        ],
      ),
    );
  }

  // Practice Tab
  Widget _buildPracticeTab() {
    return FutureBuilder<List<PracticeQuestion>>(
      future: InterviewCoachService.getPracticeQuestions(_prepSessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading practice questions'));
        }

        var questions = snapshot.data ?? [];

        if (questions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No practice questions yet'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _generatePracticeQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignSystem.brandGreen,
                  ),
                  child: Text('Generate Practice Questions'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            return _buildPracticeQuestionCard(questions[index]);
          },
        );
      },
    );
  }

  // Mock Interview Tab
  Widget _buildMockInterviewTab() {
    return FutureBuilder<List<MockInterviewResult>>(
      future: InterviewCoachService.getMockInterviewResults(_prepSessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (results.isEmpty)
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No mock interviews yet',
                          style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 8),
                      Text('Practice with a simulated interview to get feedback',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startMockInterview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesignSystem.brandGreen,
                        ),
                        child: Text('Start Mock Interview'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Previous Mock Interviews',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    SizedBox(height: 16),
                    ...results.map((result) => _buildMockResultCard(result)),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startMockInterview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesignSystem.brandGreen,
                        ),
                        child: Text('Take Another Mock Interview'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // Build practice question card
  Widget _buildPracticeQuestionCard(PracticeQuestion question) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    question.question,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(question.category),
                  backgroundColor: AppDesignSystem.brandGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: AppDesignSystem.brandGreen),
                ),
              ],
            ),
            if (question.userAnswer != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Answer:',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    SizedBox(height: 8),
                    Text(question.userAnswer!),
                  ],
                ),
              ),
              if (question.feedbackText != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Coach Feedback:',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                          Text('${question.feedbackScore?.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppDesignSystem.brandGreen,
                                    fontWeight: FontWeight.bold,
                                  )),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(question.feedbackText!),
                    ],
                  ),
                ),
              ],
            ] else
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showAnswerDialog(question),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignSystem.brandGreen,
                    ),
                    child: Text('Answer Question'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build mock result card
  Widget _buildMockResultCard(MockInterviewResult result) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mock Interview Result',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(result.overallScore),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${result.overallScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildScoreRow('Communication', result.communicationScore),
            _buildScoreRow('Technical Knowledge', result.technicalScore),
            _buildScoreRow('Confidence', result.confidentScore),
            _buildScoreRow('Professionalism', result.profesionalismScore),
            SizedBox(height: 12),
            Text('Feedback Summary:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            SizedBox(height: 8),
            Text(result.feedbackSummary),
            if (result.strengths.isNotEmpty) ...[
              SizedBox(height: 12),
              Text('Strengths:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              ...result.strengths
                  .map((s) => Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('✓ $s', style: TextStyle(color: Colors.green)),
                      )),
            ],
            if (result.improvements.isNotEmpty) ...[
              SizedBox(height: 12),
              Text('Areas to Improve:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              ...result.improvements
                  .map((i) => Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('→ $i', style: TextStyle(color: Colors.orange)),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  // Build score row
  Widget _buildScoreRow(String label, double score) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build section card
  Widget _buildSectionCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            ...items
                .map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(
                                color: AppDesignSystem.brandGreen,
                                fontWeight: FontWeight.bold,
                              )),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  // Build tips section
  Widget _buildTipsSection(String title, dynamic content) {
    final items = content is List ? content : [content];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            ...items
                .map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            item.toString().toLowerCase().startsWith('don')
                                ? Icons.cancel
                                : Icons.check_circle,
                            size: 20,
                            color: item.toString().toLowerCase().startsWith('don')
                                ? Colors.red
                                : Colors.green,
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Text(item.toString())),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  // Build info card
  Widget _buildInfoCard(String title, String content) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  // Show answer dialog
  void _showAnswerDialog(PracticeQuestion question) {
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Answer Question'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(question.question, style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 16),
              TextField(
                controller: answerController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _submitAnswer(question.id, answerController.text);
              if (!mounted) {
                return;
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              setState(() {}); // Refresh to show feedback
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.brandGreen,
            ),
            child: Text('Submit Answer'),
          ),
        ],
      ),
    );
  }

  // Submit answer
  Future<void> _submitAnswer(String questionId, String answer) async {
    try {
      await InterviewCoachService.submitPracticeAnswer(
        prepSessionId: _prepSessionId,
        questionId: questionId,
        userAnswer: answer,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Answer submitted! Coach feedback coming soon...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting answer: $e')),
        );
      }
    }
  }

  // Generate practice questions
  Future<void> _generatePracticeQuestions() async {
    try {
      setState(() => _isLoading = true);
      await InterviewCoachService.generatePracticeQuestions(
        jobTitle: widget.jobTitle,
        jobDescription: widget.jobDescription,
        prepSessionId: _prepSessionId,
        numberOfQuestions: 7,
      );
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Practice questions generated!')),
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating questions: $e')),
        );
      }
    }
  }

  // Start mock interview
  Future<void> _startMockInterview() async {
    // TODO: Implement mock interview screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mock interview feature coming soon!')),
    );
  }

  // Get score color
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
