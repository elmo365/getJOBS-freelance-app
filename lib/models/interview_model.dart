/// Interview Model for Interview Scheduling
class InterviewModel {
  final String interviewId;
  final String jobId;
  final String jobTitle;
  final String candidateId;
  final String candidateName;
  final String employerId;
  final String employerName;
  final String? applicationId; // Link to application (NEW)
  final DateTime scheduledDate; // Stored in UTC, displayed in Botswana time (UTC+2)
  final String? location;
  final String? meetingLink; // For virtual interviews
  final String type; // In-person, Virtual, Phone
  final String medium; // video, phone, chat - how the interview will be conducted
  final String status; // Scheduled, Accepted, Completed, Cancelled, Rescheduled, Ongoing, Declined
  final String? cancelReason; // Reason for cancellation by employer (NEW)
  final String? declineReason; // Reason for decline by candidate (NEW)
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? duration; // e.g., "30 minutes", "1 hour"
  final int durationMinutes; // Duration in minutes for conflict detection
  final String timezone; // Timezone of the interview (Botswana: Africa/Gaborone)
  final bool hasConflict; // Flag indicating conflict with other interviews
  final List<String>? conflictingInterviewIds; // IDs of conflicting interviews

  InterviewModel({
    required this.interviewId,
    required this.jobId,
    required this.jobTitle,
    required this.candidateId,
    required this.candidateName,
    required this.employerId,
    required this.employerName,
    this.applicationId, // NEW: optional
    required this.scheduledDate,
    this.location,
    this.meetingLink,
    this.type = 'Virtual',
    this.medium = 'video', // Default to video call
    this.status = 'Scheduled',
    this.cancelReason, // NEW: optional
    this.declineReason, // NEW: optional
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.duration,
    this.durationMinutes = 60, // Default 1 hour
    this.timezone = 'Africa/Gaborone', // Botswana timezone
    this.hasConflict = false,
    this.conflictingInterviewIds,
  });

  factory InterviewModel.fromMap(Map<String, dynamic> map, String interviewId) {
    return InterviewModel(
      interviewId: interviewId,
      jobId: map['job_id'] ?? map['jobId'] ?? '',
      jobTitle: map['job_title'] ?? map['jobTitle'] ?? '',
      candidateId: map['candidate_id'] ?? map['candidateId'] ?? '',
      candidateName: map['candidate_name'] ?? map['candidateName'] ?? '',
      employerId: map['employer_id'] ?? map['employerId'] ?? '',
      employerName: map['employer_name'] ?? map['employerName'] ?? '',
      applicationId: map['application_id'], // NEW
      scheduledDate: map['scheduled_date']?.toDate() ?? DateTime.now(),
      location: map['location'],
      meetingLink: map['meeting_link'],
      type: map['type'] ?? 'Virtual',
      medium: map['medium'] ?? map['type'] ?? 'video', // Default to video
      status: map['status'] ?? 'Scheduled',
      cancelReason: map['cancel_reason'], // NEW
      declineReason: map['decline_reason'], // NEW
      notes: map['notes'],
      createdAt: map['created_at']?.toDate(),
      updatedAt: map['updated_at']?.toDate(),
      duration: map['duration'],
      durationMinutes: map['duration_minutes'] ?? 60,
      timezone: map['timezone'] ?? 'Africa/Gaborone',
      hasConflict: map['has_conflict'] ?? false,
      conflictingInterviewIds: List<String>.from(map['conflicting_interview_ids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'job_title': jobTitle,
      'candidate_id': candidateId,
      'candidate_name': candidateName,
      'employer_id': employerId,
      'employer_name': employerName,
      'application_id': applicationId, // NEW
      'scheduled_date': scheduledDate,
      'location': location,
      'meeting_link': meetingLink,
      'type': type,
      'medium': medium, // New field: chat, video, phone
      'status': status,
      'cancel_reason': cancelReason, // NEW
      'decline_reason': declineReason, // NEW
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'duration': duration,
      'duration_minutes': durationMinutes,
      'timezone': timezone,
      'has_conflict': hasConflict,
      'conflicting_interview_ids': conflictingInterviewIds ?? [],
    };
  }
}

