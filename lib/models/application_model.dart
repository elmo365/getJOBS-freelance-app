/// Application Model for job applications
class ApplicationModel {
  final String id;
  final String jobId;
  final String userId;
  final String applicantName;
  final String? applicantImage;
  final String? applicantEmail;
  final String
      status; // 'pending', 'shortlisted', 'approved', 'rejected', 'interview_scheduled'
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? interviewId;
  final DateTime? interviewDate; // When interview is scheduled (NEW)
  final int? aiMatchScore;
  final String? aiRecommendation;
  final String? coverLetter;
  final double? bidAmount;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.applicantName,
    this.applicantImage,
    this.applicantEmail,
    this.status = 'pending',
    required this.appliedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.interviewId,
    this.interviewDate, // NEW: optional
    this.aiMatchScore,
    this.aiRecommendation,
    this.coverLetter,
    this.bidAmount,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplicationModel(
      id: id,
      jobId: map['jobId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      applicantName: map['applicantName'] as String? ?? '',
      applicantImage: map['applicantImage'] as String?,
      applicantEmail: map['applicantEmail'] as String?,
      status: map['status'] as String? ?? 'pending',
      appliedAt: map['appliedAt'] != null
          ? DateTime.parse(map['appliedAt'] as String)
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.parse(map['reviewedAt'] as String)
          : null,
      reviewNotes: map['reviewNotes'] as String?,
      interviewId: map['interviewId'] as String?,
      interviewDate: map['interviewDate'] != null // NEW
          ? DateTime.parse(map['interviewDate'] as String)
          : null,
      aiMatchScore: map['aiMatchScore'] as int?,
      aiRecommendation: map['aiRecommendation'] as String?,
      coverLetter: map['coverLetter'] as String?,
      bidAmount: (map['bidAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userId': userId,
      'applicantName': applicantName,
      'applicantImage': applicantImage,
      'applicantEmail': applicantEmail,
      'status': status,
      'appliedAt': appliedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNotes': reviewNotes,
      'interviewId': interviewId,
      'interviewDate': interviewDate?.toIso8601String(), // NEW
      'aiMatchScore': aiMatchScore,
      'aiRecommendation': aiRecommendation,
      'coverLetter': coverLetter,
      'bidAmount': bidAmount,
    };
  }
}

/// Application Status Constants
class ApplicationStatus {
  static const String pending = 'pending';
  static const String shortlisted = 'shortlisted'; // NEW: direct shortlist
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String interviewScheduled = 'interview_scheduled';
  static const String hired = 'hired';
}
