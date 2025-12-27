import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:freelance_app/models/interview_prep_model.dart';
import 'package:freelance_app/models/interview_model.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';

class InterviewCoachService {
  static const String _practiceQuestionsCollection = 'practice_questions';
  static const String _mockInterviewResultsCollection = 'mock_interview_results';
  static const String _prepSessionsCollection = 'interview_prep_sessions';
  static const String _questionBankCollection = 'interview_question_bank';
  static const String _aiResponseCacheCollection = 'ai_response_cache'; // AI output cache
  static const String _careerGuideCollection = 'career_guides'; // Career guidance database
  static const String _jobAnalysisCacheCollection = 'job_analysis_cache'; // Job analysis (industry, salary, highlights, challenges)
  static const int _questionCacheDays = 90; // Cache questions for 90 days
  static const int _aiResponseCacheDays = 30; // Cache AI responses for 30 days
  static const int _jobAnalysisCacheDays = 90; // Cache job analysis for 90 days

  // Memory cache for current session (in-memory to prevent duplicate API calls)
  static final Map<String, List<Map<String, dynamic>>> _questionCache = {};
  static final Map<String, Map<String, dynamic>> _aiResponseCache = {}; // Cache AI responses
  static final Map<String, dynamic> _careerGuideCache = {}; // Cache career guides
  static final Map<String, Map<String, dynamic>> _jobAnalysisCache = {}; // Cache job analysis (insights, salary, highlights, challenges)

  // Normalize job title for caching purposes (lowercase, trim, remove extra spaces)
  static String _normalizeJobTitle(String jobTitle) {
    return jobTitle.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Generate hash of prompt for AI response caching
  // Simple hash: combine normalized prompt elements with separators
  static String _generatePromptHash(String question, String answer, String jobTitle, String category) {
    final prompt = '$question|$answer|${_normalizeJobTitle(jobTitle)}|$category'.toLowerCase();
    // Use simple hashCode for consistent identification of similar prompts
    return 'prompt_${prompt.hashCode.toString().replaceAll('-', '0')}';
  }

  // Check AI response cache for identical evaluations
  static Future<Map<String, dynamic>?> _getAICachedResponse(String promptHash) async {
    try {
      // Check memory cache first (fastest)
      if (_aiResponseCache.containsKey(promptHash)) {
        return _aiResponseCache[promptHash];
      }

      // Check Firestore cache
      final doc = await FirebaseFirestore.instance
          .collection(_aiResponseCacheCollection)
          .doc(promptHash)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['created_at'] as Timestamp?;
        final now = DateTime.now();
        final cacheCutoffDate = now.subtract(Duration(days: _aiResponseCacheDays));

        // Return if still fresh
        if (createdAt != null && createdAt.toDate().isAfter(cacheCutoffDate)) {
          final response = data['response'] as Map<String, dynamic>?;
          if (response != null) {
            // Store in memory for this session
            _aiResponseCache[promptHash] = response;
            return response;
          }
        }
      }
    } catch (e) {
      // Silently fail - cache is optional
    }
    return null;
  }

  // Bank AI response for future reuse
  static Future<void> _bankAIResponse(
    String promptHash,
    Map<String, dynamic> response,
    String jobTitle,
    String evaluationType,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(_aiResponseCacheCollection)
          .doc(promptHash)
          .set({
        'prompt_hash': promptHash,
        'response': response,
        'job_title': jobTitle,
        'type': evaluationType, // 'answer_eval', 'question_gen', 'career_guide'
        'usage_count': FieldValue.increment(1),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - caching is optional
    }
  }

  // Get or create career guide for a job title
  // Career guides provide comprehensive guidance including paths, skills, and interview prep
  static Future<Map<String, dynamic>> _getCareerGuide(String jobTitle) async {
    try {
      final normalizedTitle = _normalizeJobTitle(jobTitle);

      // Check memory cache first
      if (_careerGuideCache.containsKey(normalizedTitle)) {
        return _careerGuideCache[normalizedTitle];
      }

      // Check Firestore
      final doc = await FirebaseFirestore.instance
          .collection(_careerGuideCollection)
          .doc(normalizedTitle)
          .get();

      if (doc.exists) {
        final guide = doc.data() as Map<String, dynamic>;
        _careerGuideCache[normalizedTitle] = guide;
        return guide;
      }
    } catch (e) {
      // Silently fail
    }

    // Return empty guide if not found
    return {
      'jobTitle': jobTitle,
      'careerPaths': [],
      'skillProgression': [],
      'commonRoles': [],
      'salaryRange': 'Market dependent',
    };
  }

  // Bank career guide for AI Career Guide pattern
  static Future<void> _bankCareerGuide(
    String jobTitle,
    Map<String, dynamic> guideData,
  ) async {
    try {
      final normalizedTitle = _normalizeJobTitle(jobTitle);
      await FirebaseFirestore.instance
          .collection(_careerGuideCollection)
          .doc(normalizedTitle)
          .set({
        'job_title': jobTitle,
        'normalized_title': normalizedTitle,
        'career_paths': guideData['careerPaths'] ?? [],
        'skill_progression': guideData['skillProgression'] ?? [],
        'common_roles': guideData['commonRoles'] ?? [],
        'salary_range': guideData['salaryRange'] ?? '',
        'interview_tips': guideData['interviewTips'] ?? [],
        'success_stories': guideData['successStories'] ?? [],
        'usage_count': FieldValue.increment(1),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));

      // Store in memory cache
      _careerGuideCache[normalizedTitle] = guideData;
    } catch (e) {
      // Silently fail
    }
  }

  // Helper to check if a Firestore timestamp is still fresh
  static bool _isStillFresh(Timestamp? created, int days) {
    if (created == null) return false;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return created.toDate().isAfter(cutoff);
  }

  // Get or generate comprehensive job analysis (industry insights, salary, highlights, challenges)
  // Uses caching to avoid redundant Gemini calls for repeated job titles
  static Future<Map<String, dynamic>> _getOrGenerateJobAnalysis(String jobTitle) async {
    try {
      final normalizedTitle = _normalizeJobTitle(jobTitle);

      // Check memory cache first (fastest)
      if (_jobAnalysisCache.containsKey(normalizedTitle)) {
        debugPrint('📊 [Job Analysis] Memory cache hit for "$jobTitle"');
        final cached = _jobAnalysisCache[normalizedTitle];
        if (cached != null) {
          return cached;
        }
      }

      // Check Firestore cache
      try {
        final doc = await FirebaseFirestore.instance
            .collection(_jobAnalysisCacheCollection)
            .doc(normalizedTitle)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (_isStillFresh(data['created_at'] as Timestamp?, _jobAnalysisCacheDays)) {
            debugPrint('📊 [Job Analysis] Firestore cache hit for "$jobTitle" (90-day TTL)');
            final analysis = {
              'jobTitle': jobTitle,
              'industryInsights': data['industry_insights'] ?? '',
              'salaryRange': data['salary_range'] ?? '',
              'companyHighlights': List<String>.from(data['company_highlights'] ?? []),
              'commonChallenges': List<String>.from(data['common_challenges'] ?? []),
            };
            _jobAnalysisCache[normalizedTitle] = analysis;
            return analysis;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Job Analysis] Firestore cache check failed: $e');
      }

      // Generate fresh from Gemini (only if not cached)
      debugPrint('🔄 [Job Analysis] Generating fresh analysis for "$jobTitle" (no cache hit)');
      final insights = await _generateIndustryInsights(jobTitle);
      final salary = await _estimateSalaryRange(jobTitle);
      final highlights = await _generateCompanyHighlights(jobTitle);
      final challenges = await _generateCommonChallenges(jobTitle);

      final analysis = {
        'jobTitle': jobTitle,
        'industryInsights': insights,
        'salaryRange': salary,
        'companyHighlights': highlights,
        'commonChallenges': challenges,
      };

      _jobAnalysisCache[normalizedTitle] = analysis;
      await _bankJobAnalysis(normalizedTitle, analysis);

      return analysis;
    } catch (e) {
      debugPrint('❌ [Job Analysis] Error: $e');
      // Return empty analysis as fallback
      return {
        'jobTitle': jobTitle,
        'industryInsights': 'Unable to generate insights at this time.',
        'salaryRange': 'Market dependent',
        'companyHighlights': [],
        'commonChallenges': [],
      };
    }
  }

  // Bank job analysis to Firestore for 90-day persistence
  static Future<void> _bankJobAnalysis(String jobTitle, Map<String, dynamic> analysis) async {
    try {
      await FirebaseFirestore.instance
          .collection(_jobAnalysisCacheCollection)
          .doc(jobTitle)
          .set({
            'job_title': analysis['jobTitle'],
            'industry_insights': analysis['industryInsights'],
            'salary_range': analysis['salaryRange'],
            'company_highlights': analysis['companyHighlights'],
            'common_challenges': analysis['commonChallenges'],
            'created_at': Timestamp.now(),
            'usage_count': FieldValue.increment(1),
          }, SetOptions(merge: true));
      debugPrint('✅ [Job Analysis] Banked to Firestore for "$jobTitle"');
    } catch (e) {
      debugPrint('⚠️ [Job Analysis] Banking failed: $e');
      // Silently fail - caching is optional
    }
  }

  // Check question bank for cached questions from similar job titles
  static Future<List<Map<String, dynamic>>?> _getQuestionsFromBank(
    String jobTitle,
    String jobDescription,
  ) async {
    try {
      final normalizedTitle = _normalizeJobTitle(jobTitle);
      final now = DateTime.now();
      final cacheCutoffDate = now.subtract(Duration(days: _questionCacheDays));

      final bankDoc = await FirebaseFirestore.instance
          .collection(_questionBankCollection)
          .doc(normalizedTitle)
          .get();

      if (bankDoc.exists) {
        final data = bankDoc.data() as Map<String, dynamic>;
        final createdAt = data['created_at'] as Timestamp?;

        // Return questions if they're fresh (within cache period)
        if (createdAt != null && createdAt.toDate().isAfter(cacheCutoffDate)) {
          final questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
          if (questions.isNotEmpty) {
            return questions;
          }
        }
      }
    } catch (e) {
      // Silently fail and let caller handle fallback
    }
    return null;
  }

  // Bank generated questions in Firestore for future reuse
  static Future<void> _bankQuestions(
    String jobTitle,
    List<Map<String, dynamic>> questions,
  ) async {
    try {
      final normalizedTitle = _normalizeJobTitle(jobTitle);
      await FirebaseFirestore.instance
          .collection(_questionBankCollection)
          .doc(normalizedTitle)
          .set({
        'job_title': jobTitle,
        'normalized_title': normalizedTitle,
        'questions': questions,
        'usage_count': FieldValue.increment(1),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - cache is optional enhancement
    }
  }
  static Future<List<PracticeQuestion>> getPracticeQuestions(String prepSessionId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_prepSessionsCollection)
          .doc(prepSessionId)
          .collection(_practiceQuestionsCollection)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PracticeQuestion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Generate practice questions based on job details
  // Uses Google Gemini AI to create unique, contextual questions
  // Implements smart caching to reduce API calls
  static Future<List<PracticeQuestion>> generatePracticeQuestions({
    required String jobTitle,
    required String jobDescription,
    required String prepSessionId,
    List<String> skills = const [],
    int numberOfQuestions = 7,
  }) async {
    try {
      final normalizedTitle = _normalizeJobTitle(jobTitle);

      // STEP 1: Check in-memory cache first (fastest)
      if (_questionCache.containsKey(normalizedTitle)) {
        final cachedData = _questionCache[normalizedTitle]!;
        return _saveQuestionsToSession(cachedData, prepSessionId, jobTitle);
      }

      // STEP 2: Check question bank in Firestore (avoid redundant AI calls)
      final bankedQuestions = await _getQuestionsFromBank(jobTitle, jobDescription);
      if (bankedQuestions != null && bankedQuestions.isNotEmpty) {
        // Store in memory cache for this session
        _questionCache[normalizedTitle] = bankedQuestions;
        return _saveQuestionsToSession(bankedQuestions, prepSessionId, jobTitle);
      }

      // STEP 3: Call Gemini AI (only if not cached)
      final aiService = GeminiAIService();
      await aiService.initialize();

      // Use Gemini to generate interview questions
      final generatedQuestions = await aiService.generateInterviewQuestions(
        jobTitle: jobTitle,
        company: '', // Company name can be extracted from interview if needed
        skills: skills.isNotEmpty
            ? skills
            : _extractSkillsFromDescription(jobDescription),
        count: numberOfQuestions,
      );

      // STEP 4: Store in caches (memory + Firestore)
      _questionCache[normalizedTitle] = generatedQuestions;
      await _bankQuestions(jobTitle, generatedQuestions);

      return _saveQuestionsToSession(generatedQuestions, prepSessionId, jobTitle);
    } catch (e) {
      // Fallback to placeholder questions if AI fails
      return _generatePlaceholderQuestions(jobTitle, prepSessionId, numberOfQuestions);
    }
  }

  // Helper: Save questions from any source to the prep session
  static Future<List<PracticeQuestion>> _saveQuestionsToSession(
    List<Map<String, dynamic>> questionData,
    String prepSessionId,
    String jobTitle,
  ) async {
    final questions = <PracticeQuestion>[];
    final now = DateTime.now();

    for (final qData in questionData) {
      try {
        final questionDoc = FirebaseFirestore.instance
            .collection('interview_prep_sessions')
            .doc(prepSessionId)
            .collection('practice_questions')
            .doc();

        final question = PracticeQuestion(
          id: questionDoc.id,
          prepSessionId: prepSessionId,
          question: qData['question'] ?? '',
          category: qData['category'] ?? 'general',
          attemptNumber: 1,
          createdAt: now,
        );

        await questionDoc.set(question.toMap());
        questions.add(question);
      } catch (e) {
        continue;
      }
    }

    return questions;
  }

  // Submit answer to a practice question
  // Uses Google Gemini AI to evaluate the answer and provide feedback
  static Future<CoachFeedback> submitPracticeAnswer({
    required String prepSessionId,
    required String questionId,
    required String userAnswer,
    String? questionText,
    String? category,
    String jobTitle = 'the position',
  }) async {
    try {
      // Get the question text if not provided
      String question = questionText ?? '';
      String cat = category ?? 'general';

      if (question.isEmpty) {
        final questionDoc = await FirebaseFirestore.instance
            .collection('interview_prep_sessions')
            .doc(prepSessionId)
            .collection('practice_questions')
            .doc(questionId)
            .get();

        if (questionDoc.exists) {
          question = questionDoc['question'] ?? '';
          cat = questionDoc['category'] ?? 'general';
        }
      }

      // STEP 1: Check AI response cache for identical evaluations
      final promptHash = _generatePromptHash(question, userAnswer, jobTitle, cat);
      var evaluationResult = await _getAICachedResponse(promptHash);

      // STEP 2: If not cached, call Gemini AI
      if (evaluationResult == null) {
        final aiService = GeminiAIService();
        await aiService.initialize();

        final aiEvalResult = await aiService.evaluateInterviewAnswer(
          question: question,
          answer: userAnswer,
          jobTitle: jobTitle,
          category: cat,
        );

        // STEP 3: Bank the AI response for future reuse
        await _bankAIResponse(promptHash, aiEvalResult, jobTitle, 'answer_eval');
        evaluationResult = aiEvalResult;
      }

      // Validate evaluation result
      if (evaluationResult['score'] == null) {
        debugPrint('❌ ERROR: AI evaluation returned null score for question $questionId');
        throw Exception('Evaluation failed: invalid response from AI');
      }
      
      final score = (evaluationResult['score'] as num).toDouble() * 10;
      if (score < 0 || score > 100) {
        debugPrint('❌ ERROR: Invalid score calculated: $score for question $questionId');
        throw Exception('Evaluation failed: invalid score');
      }
      
      final feedback = CoachFeedback(
        questionId: questionId,
        score: score,
        feedback: evaluationResult['feedback'] ?? 'Good response',
        tone: 'constructive',
        improvements: List<String>.from(evaluationResult['improvements'] ?? []),
      );

      // Update the practice question with user answer and feedback
      await FirebaseFirestore.instance
          .collection('interview_prep_sessions')
          .doc(prepSessionId)
          .collection('practice_questions')
          .doc(questionId)
          .update({
        'user_answer': userAnswer,
        'feedback_score': feedback.score,
        'feedback_text': feedback.feedback,
      });

      // Update prep session with new attempt count
      final prepSession = await getOrCreatePrepSession(
        prepSessionId: prepSessionId,
      );
      await FirebaseFirestore.instance
          .collection('interview_prep_sessions')
          .doc(prepSessionId)
          .update({
        'practice_questions_attempted': (prepSession.practiceQuestionsAttempted + 1),
        'updated_at': Timestamp.now(),
      });

      return feedback;
    } catch (e) {
      return CoachFeedback(
        questionId: questionId,
        score: 0,
        feedback: 'Error processing your answer. Please try again.',
      );
    }
  }

  // Start or get prep session for an interview
  static Future<InterviewPrepSession> getOrCreatePrepSession({
    required String prepSessionId,
    String? jobSeekerId,
    String? interviewId,
  }) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection(_prepSessionsCollection).doc(prepSessionId).get();

      if (doc.exists) {
        return InterviewPrepSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      // Create new prep session
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final now = DateTime.now();

      final session = InterviewPrepSession(
        id: prepSessionId,
        jobSeekerId: jobSeekerId ?? userId,
        interviewId: interviewId ?? '',
        sessionDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await FirebaseFirestore.instance
          .collection(_prepSessionsCollection)
          .doc(prepSessionId)
          .set(session.toMap());

      return session;
    } catch (e) {
      rethrow;
    }
  }

  // Mark section as completed
  static Future<void> markSectionCompleted(String prepSessionId, String section) async {
    try {
      final session = await getOrCreatePrepSession(prepSessionId: prepSessionId);
      final updatedSections = [...session.completedSections];

      if (!updatedSections.contains(section)) {
        updatedSections.add(section);
      }

      await FirebaseFirestore.instance
          .collection(_prepSessionsCollection)
          .doc(prepSessionId)
          .update({
        'completed_sections': updatedSections,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      // Section tracking failure is non-critical
    }
  }

  // Get job analysis for interview
  static Future<JobAnalysisData> generateJobAnalysis({
    required InterviewModel interview,
    required String jobTitle,
    required String jobDescription,
  }) async {
    try {
      // STEP 1: Get or create career guide for comprehensive guidance
      final careerGuide = await _getCareerGuide(jobTitle);
      
      // STEP 2: Check cache first before calling Gemini
      final bankedQuestions = await _getQuestionsFromBank(jobTitle, jobDescription);
      List<String> likelyQuestions;
      
      if (bankedQuestions != null && bankedQuestions.isNotEmpty) {
        // Use cached questions
        likelyQuestions = bankedQuestions.map((q) => q['question'] as String).toList();
      } else {
        // Generate new questions and bank them
        likelyQuestions = await _generateJobBasedQuestions(jobTitle, jobDescription);
        await _bankQuestions(
          jobTitle,
          likelyQuestions.map((q) => {'question': q, 'category': 'interview_likely'}).toList(),
        );
      }

      // STEP 3: Create comprehensive job analysis with career guidance
      final careerPaths = careerGuide['careerPaths'] as List?;
      
      // Use job analysis caching for industry insights, salary, highlights, and challenges
      Map<String, dynamic> jobAnalysisData;
      if (careerPaths != null && careerPaths.isNotEmpty) {
        // Career guide has some data, use it with generated data
        jobAnalysisData = {
          'industryInsights': careerPaths.join(', '),
          'salaryRange': careerGuide['salaryRange'] ?? 'Market dependent',
          'companyHighlights': [],
          'commonChallenges': careerGuide['commonRoles'] ?? [],
        };
      } else {
        // Get comprehensive job analysis with caching (99% reduction for repeated jobs)
        jobAnalysisData = await _getOrGenerateJobAnalysis(jobTitle);
      }

      final jobAnalysis = JobAnalysisData(
        interviewId: interview.interviewId,
        jobTitle: jobTitle,
        company: interview.employerName,
        keySkillsNeeded: _extractKeySkills(jobDescription),
        likelyInterviewQuestions: likelyQuestions,
        salaryRange: jobAnalysisData['salaryRange'] as String,
        companyHighlights: List<String>.from(jobAnalysisData['companyHighlights'] ?? []),
        industryInsights: jobAnalysisData['industryInsights'] as String,
        commonChallenges: List<String>.from(jobAnalysisData['commonChallenges'] ?? []),
        analyzedAt: DateTime.now(),
      );

      // STEP 4: Bank career guide for future use
      if (careerGuide.isEmpty || careerGuide['careerPaths'] == null) {
        await _bankCareerGuide(jobTitle, {
          'careerPaths': jobAnalysis.industryInsights,
          'skillProgression': jobAnalysis.keySkillsNeeded,
          'commonRoles': jobAnalysis.commonChallenges,
          'salaryRange': jobAnalysis.salaryRange,
          'interviewTips': likelyQuestions,
        });
      }

      return jobAnalysis;
    } catch (e) {
      rethrow;
    }
  }

  // Get interview tips based on medium type
  static InterviewTipsData getInterviewTips(String medium) {
    switch (medium.toLowerCase()) {
      case 'video':
        return _getVideoInterviewTips();
      case 'phone':
        return _getPhoneInterviewTips();
      case 'chat':
        return _getChatInterviewTips();
      default:
        return _getGeneralInterviewTips();
    }
  }

  // Get mock interview feedback using Gemini AI
  static Future<MockInterviewResult> submitMockInterview({
    required String prepSessionId,
    required String userResponse,
    required List<String> questionsAsked,
    String jobTitle = 'the position',
  }) async {
    try {
      final aiService = GeminiAIService();
      await aiService.initialize();

      final resultDoc = FirebaseFirestore.instance
          .collection('interview_prep_sessions')
          .doc(prepSessionId)
          .collection('mock_interview_results')
          .doc();

      // Use Gemini to evaluate all interview dimensions dynamically
      var overallScore = 75.0;
      var communicationScore = 75.0;
      var technicalScore = 75.0;
      var confidentScore = 75.0;
      var profesionalismScore = 75.0;

      try {
        // Evaluate technical skills from user response
        try {
          if (questionsAsked.isNotEmpty) {
            final technicalEval = await aiService.evaluateInterviewAnswer(
              question: questionsAsked[0],
              answer: userResponse.length > 500 ? userResponse.substring(0, 500) : userResponse,
              jobTitle: jobTitle,
              category: 'technical',
            );
            if (technicalEval['score'] == null) {
              throw Exception('Technical evaluation returned null score');
            }
            technicalScore = (technicalEval['score'] as num).toDouble() * 10;
          }

          // Evaluate communication skills
          final commEval = await aiService.evaluateInterviewAnswer(
            question: 'How would you explain your experience to the team?',
            answer: userResponse,
            jobTitle: jobTitle,
            category: 'communication',
          );
          if (commEval['score'] == null) {
            throw Exception('Communication evaluation returned null score');
          }
          communicationScore = (commEval['score'] as num).toDouble() * 10;

          // Evaluate confidence level from response length and structure
          confidentScore = _calculateConfidenceScore(userResponse, questionsAsked.length);

          // Evaluate professionalism
          final profEval = await aiService.evaluateInterviewAnswer(
            question: 'Assess professionalism and interview etiquette',
            answer: userResponse,
            jobTitle: jobTitle,
            category: 'professionalism',
          );
          if (profEval['score'] == null) {
            throw Exception('Professionalism evaluation returned null score');
          }
          profesionalismScore = (profEval['score'] as num).toDouble() * 10;
        } catch (e) {
          debugPrint('❌ ERROR: Interview evaluation failed: $e');
          rethrow; // Propagate error, let caller handle
        }

        // Calculate overall score as average of all dimensions
        overallScore = (technicalScore + communicationScore + confidentScore + profesionalismScore) / 4;
      } catch (e) {
        // Gemini evaluation failed - use default fallback scores (all 75.0)
      }

      // Generate dynamic feedback summary using Gemini
      String feedbackSummary = 'Good overall performance. Focus on providing specific examples with metrics.';
      List<String> strengths = ['Clear communication', 'Professional response'];
      List<String> improvements = ['Add specific examples', 'Expand technical depth'];

      try {
        final feedbackEval = await aiService.evaluateInterviewAnswer(
          question: 'Provide detailed feedback on this mock interview performance',
          answer: userResponse,
          jobTitle: jobTitle,
          category: 'feedback',
        );
        feedbackSummary = feedbackEval['feedback'] ?? feedbackSummary;
        strengths = List<String>.from(feedbackEval['strengths'] ?? strengths);
        improvements = List<String>.from(feedbackEval['improvements'] ?? improvements);
      } catch (e) {
        // Use default fallback feedback
      }

      final result = MockInterviewResult(
        id: resultDoc.id,
        prepSessionId: prepSessionId,
        overallScore: overallScore,
        communicationScore: communicationScore,
        technicalScore: technicalScore,
        confidentScore: confidentScore,
        profesionalismScore: profesionalismScore,
        videoUrl: '',
        feedbackSummary: feedbackSummary,
        strengths: strengths,
        improvements: improvements,
        durationSeconds: 600,
        completedAt: DateTime.now(),
      );

      await resultDoc.set(result.toMap());

      // Update prep session
      await FirebaseFirestore.instance
          .collection('interview_prep_sessions')
          .doc(prepSessionId)
          .update({
        'mock_interview_completed': true,
        'average_feedback_score': result.overallScore,
        'updated_at': Timestamp.now(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Get previous mock interview results
  static Future<List<MockInterviewResult>> getMockInterviewResults(String prepSessionId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_prepSessionsCollection)
          .doc(prepSessionId)
          .collection(_mockInterviewResultsCollection)
          .orderBy('completed_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => MockInterviewResult.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============ Helper Methods ============

  // Calculate confidence score based on response quality indicators
  // Longer, well-structured responses indicate more confidence
  static double _calculateConfidenceScore(String userResponse, int questionCount) {
    if (userResponse.isEmpty) return 30.0;
    
    // Base score from response length (longer = more confident)
    final lengthScore = (userResponse.length / 500 * 50).clamp(0, 50).toDouble();
    
    // Bonus for complete sentences and structure
    final sentences = userResponse.split(RegExp(r'[.!?]')).length;
    final structureBonus = (sentences > 3) ? 25.0 : (sentences > 1) ? 15.0 : 0.0;
    
    // Bonus if they answered multiple questions
    final completenessBonus = (questionCount > 1) ? 15.0 : 10.0;
    
    final score = (lengthScore + structureBonus + completenessBonus).clamp(0, 100).toDouble();
    return score;
  }

  // Extract skills from job description (used for Gemini API)
  static List<String> _extractSkillsFromDescription(String jobDescription) {
    // Simple skill extraction - can be enhanced with NLP
    final skills = <String>[];
    final commonSkills = [
      'Python',
      'JavaScript',
      'Java',
      'C#',
      'React',
      'Flutter',
      'SQL',
      'AWS',
      'GCP',
      'Azure',
      'Docker',
      'Kubernetes',
      'Git',
      'REST API',
      'Leadership',
      'Communication',
      'Problem Solving',
      'Teamwork',
      'Project Management',
      'Agile',
      'Scrum',
    ];

    for (final skill in commonSkills) {
      if (jobDescription.toLowerCase().contains(skill.toLowerCase())) {
        skills.add(skill);
      }
    }

    return skills.isEmpty
        ? ['Communication', 'Problem Solving', 'Technical Proficiency', 'Teamwork']
        : skills;
  }

  // Fallback to placeholder questions if AI fails
  static Future<List<PracticeQuestion>> _generatePlaceholderQuestions(
    String jobTitle,
    String prepSessionId,
    int numberOfQuestions,
  ) async {
    final questions = <PracticeQuestion>[];
    final now = DateTime.now();

    final placeholderQuestions = [
      {'question': 'Tell us about your experience with the key technologies required for this role.', 'category': 'technical'},
      {'question': 'Describe a time when you had to solve a complex problem. What was your approach?', 'category': 'behavioral'},
      {'question': 'Why are you interested in this $jobTitle position?', 'category': 'motivational'},
      {'question': 'Tell us about your greatest professional achievement.', 'category': 'behavioral'},
      {'question': 'How do you handle working in a team? Can you give an example of successful collaboration?', 'category': 'behavioral'},
      {'question': 'What are your strengths and how do they apply to this role?', 'category': 'situational'},
      {'question': 'Where do you see yourself in 5 years?', 'category': 'motivational'},
    ];

    for (int i = 0; i < numberOfQuestions && i < placeholderQuestions.length; i++) {
      final q = placeholderQuestions[i];
      final questionDoc = FirebaseFirestore.instance
          .collection('interview_prep_sessions')
          .doc(prepSessionId)
          .collection('practice_questions')
          .doc();

      final question = PracticeQuestion(
        id: questionDoc.id,
        prepSessionId: prepSessionId,
        question: q['question'] as String,
        category: q['category'] as String,
        attemptNumber: 1,
        createdAt: now,
      );

      await questionDoc.set(question.toMap());
      questions.add(question);
    }

    return questions;
  }

  // Extract key skills from job description
  static List<String> _extractKeySkills(String jobDescription) {
    return _extractSkillsFromDescription(jobDescription);
  }

  // Generate job-based questions using Gemini (for job analysis)
  static Future<List<String>> _generateJobBasedQuestions(String jobTitle, String jobDescription) async {
    try {
      final aiService = GeminiAIService();
      await aiService.initialize();

      final questions = await aiService.generateInterviewQuestions(
        jobTitle: jobTitle,
        company: '',
        skills: _extractSkillsFromDescription(jobDescription),
        count: 3,
      );

      return questions.map((q) => q['question'] as String).toList();
    } catch (e) {
      return [
        'What attracts you to this $jobTitle position?',
        'How would you approach your first 30 days in this role?',
        'What is your experience with the key requirements?',
      ];
    }
  }

  // Estimate salary range dynamically using Gemini AI
  static Future<String> _estimateSalaryRange(String jobTitle) async {
    try {
      final aiService = GeminiAIService();
      await aiService.initialize();
      
      final response = await aiService.evaluateInterviewAnswer(
        question: 'What is the typical salary range for a $jobTitle position?',
        answer: 'Please provide the salary range based on market research.',
        jobTitle: jobTitle,
        category: 'salary_research',
      );
      
      return response['feedback'] ?? '\$50,000 - \$120,000 per year';
    } catch (e) {
      return 'Market dependent - \$50,000 - \$120,000+ per year';
    }
  }

  // Generate company highlights dynamically using Gemini AI
  static Future<List<String>> _generateCompanyHighlights(String companyName) async {
    try {
      final aiService = GeminiAIService();
      await aiService.initialize();
      
      final response = await aiService.evaluateInterviewAnswer(
        question: 'What are the key highlights and strengths of working at $companyName?',
        answer: 'Please provide key company highlights that would appeal to candidates.',
        jobTitle: companyName,
        category: 'company_research',
      );
      
      final highlights = response['improvements'] ?? [];
      return List<String>.from(highlights).isNotEmpty ? List<String>.from(highlights) : [
        'Strong team culture',
        'Career development',
        'Competitive benefits',
      ];
    } catch (e) {
      return ['Strong team culture', 'Career development', 'Competitive benefits'];
    }
  }

  // Generate industry insights dynamically using Gemini AI
  static Future<String> _generateIndustryInsights(String jobTitle) async {
    try {
      final aiService = GeminiAIService();
      await aiService.initialize();
      
      final response = await aiService.evaluateInterviewAnswer(
        question: 'What are the current industry insights and trends for a $jobTitle position?',
        answer: 'Please provide key industry trends and what employers are looking for.',
        jobTitle: jobTitle,
        category: 'industry_research',
      );
      
      return response['feedback'] ?? 'This is a dynamic market role. Emphasize both technical and soft skills.';
    } catch (e) {
      return 'Growing field with strong demand. Showcase relevant technical skills and communication ability.';
    }
  }

  // Generate common challenges dynamically using Gemini AI
  static Future<List<String>> _generateCommonChallenges(String jobTitle) async {
    try {
      final aiService = GeminiAIService();
      await aiService.initialize();
      
      final response = await aiService.evaluateInterviewAnswer(
        question: 'What are the most common challenges faced by professionals in a $jobTitle role?',
        answer: 'Please identify key challenges and obstacles candidates should be prepared for.',
        jobTitle: jobTitle,
        category: 'challenges_research',
      );
      
      final challenges = response['improvements'] ?? [];
      return List<String>.from(challenges).isNotEmpty ? List<String>.from(challenges) : [
        'Rapid technology evolution',
        'Cross-team collaboration',
        'Deadline management',
      ];
    } catch (e) {
      return ['Rapid technology evolution', 'Cross-team collaboration', 'Deadline management'];
    }
  }

  // Video interview tips
  static InterviewTipsData _getVideoInterviewTips() {
    return InterviewTipsData(
      medium: 'video',
      technicalTips: [
        'Test your camera, microphone, and internet before the interview',
        'Use good lighting - position a light source in front of you',
        'Look at the camera when speaking, not at your reflection',
      ],
      behavioralTips: [
        'Dress professionally',
        'Maintain good posture',
        'Use hand gestures naturally',
        'Smile and show enthusiasm',
      ],
      mediaTips: [
        'Close unnecessary browser tabs and notifications',
        'Use a plain background or blur your background',
        'Position camera at eye level',
        'Test platform (Zoom, Google Meet, etc.) beforehand',
      ],
      doDontsList: [
        'DO: Make eye contact with camera',
        'DO: Smile naturally',
        'DONT: Multitask or check phone',
        'DONT: Interrupt the interviewer',
        'DONT: Eat or drink during interview',
      ],
      beforeInterviewChecklist:
          'Test tech 10 mins early • Have resume ready • Quiet room • Professional background',
      duringInterviewTips:
          'Listen fully before answering • Speak clearly • Answer completely but concisely',
      afterInterviewTips: 'Send thank you email within 24 hours • Reference specific conversation points',
    );
  }

  // Phone interview tips
  static InterviewTipsData _getPhoneInterviewTips() {
    return InterviewTipsData(
      medium: 'phone',
      technicalTips: [
        'Use a quiet, private space',
        'Ensure good phone signal or use headphones',
        'Have all materials (resume, notes) in front of you',
      ],
      behavioralTips: [
        'Speak clearly and at a moderate pace',
        'Show energy through your voice',
        'Smile - it affects your tone positively',
        'Avoid background noise',
      ],
      mediaTips: [
        'Silence other notifications and devices',
        'Have pen and paper ready for notes',
        'Keep water nearby',
        'Start 2 minutes before scheduled time',
      ],
      doDontsList: [
        'DO: Smile (yes, they can hear it)',
        'DO: Take brief notes',
        'DONT: Eat, chew gum, or drink noisily',
        'DONT: Use speakerphone unless necessary',
        'DONT: Have pets or kids in background',
      ],
      beforeInterviewChecklist:
          'Test phone connection • Quiet location • Resume nearby • Silence distractions',
      duringInterviewTips:
          'Slow down your speech • Use pauses • Be enthusiastic without being loud',
      afterInterviewTips: 'Follow up via email with key points from conversation',
    );
  }

  // Chat interview tips
  static InterviewTipsData _getChatInterviewTips() {
    return InterviewTipsData(
      medium: 'chat',
      technicalTips: [
        'Use professional language and tone',
        'Check your typing for errors before sending',
        'Be concise but comprehensive in responses',
      ],
      behavioralTips: [
        'Respond promptly to messages',
        'Use proper punctuation and grammar',
        'Be professional but personable',
        'Show genuine interest in the role',
      ],
      mediaTips: [
        'Test the chat platform beforehand',
        'Keep responses visible on screen',
        'Copy important questions to text editor first',
        'Ensure stable internet connection',
      ],
      doDontsList: [
        'DO: Take time to write thoughtful responses',
        'DO: Ask clarifying questions',
        'DONT: Use emojis or slang',
        'DONT: Send multiple short messages',
        'DONT: Use ALL CAPS',
      ],
      beforeInterviewChecklist:
          'Test chat platform • Have notes ready • Professional setup • Clear desk',
      duringInterviewTips:
          'Read questions fully • Draft complex answers first • Proofread before sending',
      afterInterviewTips: 'Ask about next steps in writing • Reference conversation in follow-up email',
    );
  }

  // General interview tips
  static InterviewTipsData _getGeneralInterviewTips() {
    return InterviewTipsData(
      medium: 'general',
      technicalTips: [
        'Research the company thoroughly',
        'Understand the job description completely',
        'Prepare examples using STAR method',
      ],
      behavioralTips: [
        'Be authentic and genuine',
        'Show enthusiasm for the role',
        'Listen actively to questions',
      ],
      mediaTips: [
        'Arrive early (physical) or log in 10 mins early (virtual)',
        'Bring copies of your resume',
        'Have questions prepared for the interviewer',
      ],
      doDontsList: [
        'DO: Research the company',
        'DO: Prepare questions',
        'DONT: Badmouth previous employers',
        'DONT: Be overconfident',
        'DONT: Give one-word answers',
      ],
      beforeInterviewChecklist:
          'Research company • Review job description • Prepare examples • Get good sleep',
      duringInterviewTips:
          'Take a breath before answering • Use STAR for stories • Ask thoughtful questions',
      afterInterviewTips: 'Send thank you email • Reflect on your performance • Follow up as instructed',
    );
  }
}
