import 'package:cloud_firestore/cloud_firestore.dart';

/// Job Closure Request Model
/// Represents a formal request to close a job with hired candidates
/// Requires admin approval for safety (protects job seekers from scam companies)
class JobClosureRequest {
  final String id;
  final String jobId;
  final String employerId;
  final String jobTitle;
  final String closureReason; // Why employer wants to close
  final List<HiredApplicant> hiredApplicants; // People who were hired for this job
  final List<String> applicantsToNotify; // IDs of applicants who applied but weren't hired
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? adminId; // Which admin reviewed
  final String? adminResponse; // Admin notes/feedback
  final int totalApplications; // Total number of applications received

  JobClosureRequest({
    required this.id,
    required this.jobId,
    required this.employerId,
    required this.jobTitle,
    required this.closureReason,
    required this.hiredApplicants,
    required this.applicantsToNotify,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
    this.adminId,
    this.adminResponse,
    this.totalApplications = 0,
  });

  /// Create from Firestore document
  factory JobClosureRequest.fromMap(Map<String, dynamic> map, String docId) {
    return JobClosureRequest(
      id: docId,
      jobId: map['jobId'] as String? ?? '',
      employerId: map['employerId'] as String? ?? '',
      jobTitle: map['jobTitle'] as String? ?? 'Unknown Job',
      closureReason: map['closureReason'] as String? ?? '',
      hiredApplicants: (map['hiredApplicants'] as List<dynamic>? ?? [])
          .map((item) => HiredApplicant.fromMap(item as Map<String, dynamic>))
          .toList(),
      applicantsToNotify: List<String>.from(
        map['applicantsToNotify'] as List<dynamic>? ?? [],
      ),
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      adminId: map['adminId'] as String?,
      adminResponse: map['adminResponse'] as String?,
      totalApplications: map['totalApplications'] as int? ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'employerId': employerId,
      'jobTitle': jobTitle,
      'closureReason': closureReason,
      'hiredApplicants': hiredApplicants.map((h) => h.toMap()).toList(),
      'applicantsToNotify': applicantsToNotify,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'adminId': adminId,
      'adminResponse': adminResponse,
      'totalApplications': totalApplications,
    };
  }

  /// Check if this request has hired applicants
  bool hasHiredApplicants() => hiredApplicants.isNotEmpty;

  /// Check if still pending review
  bool isPending() => status == 'pending';

  /// Check if approved by admin
  bool isApproved() => status == 'approved';

  /// Check if rejected by admin
  bool isRejected() => status == 'rejected';
}

/// Hired Applicant Information
/// Details of person who was hired for the job
class HiredApplicant {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? userImage;
  final DateTime hiredDate;
  final String? notes; // Position notes or agreement details

  HiredApplicant({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.userImage,
    required this.hiredDate,
    this.notes,
  });

  factory HiredApplicant.fromMap(Map<String, dynamic> map) {
    return HiredApplicant(
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      userImage: map['userImage'] as String?,
      hiredDate: (map['hiredDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'userImage': userImage,
      'hiredDate': Timestamp.fromDate(hiredDate),
      'notes': notes,
    };
  }
}
