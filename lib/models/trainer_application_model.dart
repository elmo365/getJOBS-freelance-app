import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for trainer applications
/// Users can apply to become trainers with certifications and course details
class TrainerApplicationModel {
  final String applicationId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userImage;
  final String bio; // Brief description of trainer
  final List<String> certifications; // URLs to uploaded certification files
  final List<String> courses; // Courses or training areas they want to offer
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? adminNotes;
  final String? approvedByAdminId;

  TrainerApplicationModel({
    required this.applicationId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userImage,
    required this.bio,
    required this.certifications,
    required this.courses,
    this.status = 'pending',
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.adminNotes,
    this.approvedByAdminId,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userImage': userImage,
      'bio': bio,
      'certifications': certifications,
      'courses': courses,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
      'approvedByAdminId': approvedByAdminId,
    };
  }

  // Create from Firestore document
  factory TrainerApplicationModel.fromMap(
      Map<String, dynamic> map, String docId) {
    return TrainerApplicationModel(
      applicationId: map['applicationId'] as String? ?? docId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Unknown',
      userEmail: map['userEmail'] as String? ?? '',
      userImage: map['userImage'] as String?,
      bio: map['bio'] as String? ?? '',
      certifications: List<String>.from(map['certifications'] as List? ?? []),
      courses: List<String>.from(map['courses'] as List? ?? []),
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      approvedAt: map['approvedAt'] is Timestamp
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: map['rejectedAt'] is Timestamp
          ? (map['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'] as String?,
      adminNotes: map['adminNotes'] as String?,
      approvedByAdminId: map['approvedByAdminId'] as String?,
    );
  }

  // CopyWith method
  TrainerApplicationModel copyWith({
    String? applicationId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userImage,
    String? bio,
    List<String>? certifications,
    List<String>? courses,
    String? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? adminNotes,
    String? approvedByAdminId,
  }) {
    return TrainerApplicationModel(
      applicationId: applicationId ?? this.applicationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userImage: userImage ?? this.userImage,
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      courses: courses ?? this.courses,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedByAdminId: approvedByAdminId ?? this.approvedByAdminId,
    );
  }
}
