import 'package:cloud_firestore/cloud_firestore.dart';

// Interview Prep Session model
class InterviewPrepSession {
  final String id;
  final String jobSeekerId;
  final String interviewId;
  final DateTime sessionDate;
  final int practiceQuestionsAttempted;
  final double averageFeedbackScore; // 0-100
  final bool mockInterviewCompleted;
  final int jobAnalysisReviewedAt; // timestamp
  final int tipsReviewedAt; // timestamp
  final List<String> completedSections; // ['job_analysis', 'tips', 'practice', 'mock_interview']
  final DateTime createdAt;
  final DateTime updatedAt;

  InterviewPrepSession({
    required this.id,
    required this.jobSeekerId,
    required this.interviewId,
    required this.sessionDate,
    this.practiceQuestionsAttempted = 0,
    this.averageFeedbackScore = 0.0,
    this.mockInterviewCompleted = false,
    this.jobAnalysisReviewedAt = 0,
    this.tipsReviewedAt = 0,
    this.completedSections = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory InterviewPrepSession.fromMap(Map<String, dynamic> map, String docId) {
    return InterviewPrepSession(
      id: docId,
      jobSeekerId: map['job_seeker_id'] ?? '',
      interviewId: map['interview_id'] ?? '',
      sessionDate: (map['session_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      practiceQuestionsAttempted: map['practice_questions_attempted'] ?? 0,
      averageFeedbackScore: (map['average_feedback_score'] ?? 0.0).toDouble(),
      mockInterviewCompleted: map['mock_interview_completed'] ?? false,
      jobAnalysisReviewedAt: map['job_analysis_reviewed_at'] ?? 0,
      tipsReviewedAt: map['tips_reviewed_at'] ?? 0,
      completedSections: List<String>.from(map['completed_sections'] ?? []),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'job_seeker_id': jobSeekerId,
      'interview_id': interviewId,
      'session_date': Timestamp.fromDate(sessionDate),
      'practice_questions_attempted': practiceQuestionsAttempted,
      'average_feedback_score': averageFeedbackScore,
      'mock_interview_completed': mockInterviewCompleted,
      'job_analysis_reviewed_at': jobAnalysisReviewedAt,
      'tips_reviewed_at': tipsReviewedAt,
      'completed_sections': completedSections,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}

// Practice Question model
class PracticeQuestion {
  final String id;
  final String prepSessionId;
  final String question;
  final String? userAnswer;
  final double? feedbackScore; // 0-100
  final String? feedbackText;
  final String category; // technical, behavioral, situational, etc
  final int attemptNumber;
  final DateTime createdAt;

  PracticeQuestion({
    required this.id,
    required this.prepSessionId,
    required this.question,
    this.userAnswer,
    this.feedbackScore,
    this.feedbackText,
    required this.category,
    this.attemptNumber = 1,
    required this.createdAt,
  });

  factory PracticeQuestion.fromMap(Map<String, dynamic> map, String docId) {
    return PracticeQuestion(
      id: docId,
      prepSessionId: map['prep_session_id'] ?? '',
      question: map['question'] ?? '',
      userAnswer: map['user_answer'],
      feedbackScore: (map['feedback_score'] as num?)?.toDouble(),
      feedbackText: map['feedback_text'],
      category: map['category'] ?? 'general',
      attemptNumber: map['attempt_number'] ?? 1,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prep_session_id': prepSessionId,
      'question': question,
      'user_answer': userAnswer,
      'feedback_score': feedbackScore,
      'feedback_text': feedbackText,
      'category': category,
      'attempt_number': attemptNumber,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

// Mock Interview Result model
class MockInterviewResult {
  final String id;
  final String prepSessionId;
  final double overallScore; // 0-100
  final double communicationScore;
  final double technicalScore;
  final double confidentScore;
  final double profesionalismScore;
  final String videoUrl; // recording of mock interview
  final String feedbackSummary;
  final List<String> strengths;
  final List<String> improvements;
  final int durationSeconds;
  final DateTime completedAt;

  MockInterviewResult({
    required this.id,
    required this.prepSessionId,
    required this.overallScore,
    required this.communicationScore,
    required this.technicalScore,
    required this.confidentScore,
    required this.profesionalismScore,
    this.videoUrl = '',
    required this.feedbackSummary,
    required this.strengths,
    required this.improvements,
    required this.durationSeconds,
    required this.completedAt,
  });

  factory MockInterviewResult.fromMap(Map<String, dynamic> map, String docId) {
    return MockInterviewResult(
      id: docId,
      prepSessionId: map['prep_session_id'] ?? '',
      overallScore: (map['overall_score'] ?? 0.0).toDouble(),
      communicationScore: (map['communication_score'] ?? 0.0).toDouble(),
      technicalScore: (map['technical_score'] ?? 0.0).toDouble(),
      confidentScore: (map['confident_score'] ?? 0.0).toDouble(),
      profesionalismScore: (map['profesionalism_score'] ?? 0.0).toDouble(),
      videoUrl: map['video_url'] ?? '',
      feedbackSummary: map['feedback_summary'] ?? '',
      strengths: List<String>.from(map['strengths'] ?? []),
      improvements: List<String>.from(map['improvements'] ?? []),
      durationSeconds: map['duration_seconds'] ?? 0,
      completedAt: (map['completed_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prep_session_id': prepSessionId,
      'overall_score': overallScore,
      'communication_score': communicationScore,
      'technical_score': technicalScore,
      'confident_score': confidentScore,
      'profesionalism_score': profesionalismScore,
      'video_url': videoUrl,
      'feedback_summary': feedbackSummary,
      'strengths': strengths,
      'improvements': improvements,
      'duration_seconds': durationSeconds,
      'completed_at': Timestamp.fromDate(completedAt),
    };
  }
}

// Coach Feedback model for practice questions
class CoachFeedback {
  final String questionId;
  final double score; // 0-100
  final String feedback;
  final String tone; // positive, constructive, neutral
  final List<String> improvements;

  CoachFeedback({
    required this.questionId,
    required this.score,
    required this.feedback,
    this.tone = 'constructive',
    this.improvements = const [],
  });
}

// Job Analysis data model
class JobAnalysisData {
  final String interviewId;
  final String jobTitle;
  final String company;
  final List<String> keySkillsNeeded;
  final List<String> likelyInterviewQuestions;
  final String salaryRange;
  final List<String> companyHighlights;
  final String industryInsights;
  final List<String> commonChallenges;
  final DateTime analyzedAt;

  JobAnalysisData({
    required this.interviewId,
    required this.jobTitle,
    required this.company,
    required this.keySkillsNeeded,
    required this.likelyInterviewQuestions,
    required this.salaryRange,
    required this.companyHighlights,
    required this.industryInsights,
    required this.commonChallenges,
    required this.analyzedAt,
  });
}

// Interview tips data model
class InterviewTipsData {
  final String medium; // video, phone, chat
  final List<String> technicalTips;
  final List<String> behavioralTips;
  final List<String> mediaTips; // specific to video/phone/chat
  final List<String> doDontsList;
  final String beforeInterviewChecklist;
  final String duringInterviewTips;
  final String afterInterviewTips;

  InterviewTipsData({
    required this.medium,
    required this.technicalTips,
    required this.behavioralTips,
    required this.mediaTips,
    required this.doDontsList,
    required this.beforeInterviewChecklist,
    required this.duringInterviewTips,
    required this.afterInterviewTips,
  });
}
