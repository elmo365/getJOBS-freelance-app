/// Job Model for job postings
class JobModel {
  final String jobId;
  final String employerId;
  final String employerName;
  final String? employerImage;
  final String title;
  final String description;
  final String category;
  final String? location;
  final String? salary;
  final String? jobType; // Full-time, Part-time, Contract, etc.
  final DateTime? deadlineDate;
  final DateTime? createdAt;
  final bool isRecruiting;
  final int applicantsCount;
  final List<String> applicantsList;
  final List<String> requiredSkills;
  final bool isVerified;
  final List<String> searchKeywords;
  final String? experienceLevel;
  final int positionsAvailable; // Number of positions available (default: 1)
  final int positionsFilled; // Number of positions filled (default: 0)
  final List<String> hiredApplicants; // List of hired applicant user IDs
  final DateTime? completedAt; // When all positions were filled
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final bool isApproved; // Quick approval status check
  final String? approvedBy; // Admin user ID who approved
  final DateTime? approvedAt; // When job was approved

  JobModel({
    required this.jobId,
    required this.employerId,
    required this.employerName,
    this.employerImage,
    required this.title,
    required this.description,
    required this.category,
    this.location,
    this.salary,
    this.jobType,
    this.deadlineDate,
    this.createdAt,
    this.isRecruiting = true,
    this.applicantsCount = 0,
    this.applicantsList = const [],
    this.requiredSkills = const [],
    this.experienceLevel,
    this.isVerified = false,
    this.searchKeywords = const [],
    this.positionsAvailable = 1,
    this.positionsFilled = 0,
    this.hiredApplicants = const [],
    this.completedAt,
    this.approvalStatus = 'pending',
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      if (value is String) return DateTime.tryParse(value);
      // Firestore Timestamp has a toDate() method.
      // ignore: avoid_dynamic_calls
      final dynamic maybeDateTime = value.toDate();
      if (maybeDateTime is DateTime) return maybeDateTime;
    } catch (_) {
      // Ignore parsing errors.
    }
    return null;
  }

  factory JobModel.fromMap(Map<String, dynamic> map, String jobId) {
    final rawApplicantsList = map['applicantsList'] ?? map['applicants_list'];
    final applicantsList = <String>[];
    if (rawApplicantsList is List) {
      for (final item in rawApplicantsList) {
        if (item is String) {
          applicantsList.add(item);
        } else if (item is Map) {
          final id = item['id']?.toString();
          if (id != null && id.isNotEmpty) applicantsList.add(id);
        }
      }
    }

    final hiredApplicants = <String>[];
    final rawHiredApplicants = map['hiredApplicants'] ?? map['hired_applicants'];
    if (rawHiredApplicants is List) {
      for (final item in rawHiredApplicants) {
        if (item is String) {
          hiredApplicants.add(item);
        }
      }
    }

    return JobModel(
      jobId: jobId,
      employerId: (map['userId'] ?? map['id'] ?? '').toString(),
      employerName: (map['name'] ?? map['employerName'] ?? '').toString(),
      employerImage: map['user_image'],
      title: map['title'] ?? '',
      description: (map['description'] ?? map['desc'] ?? '').toString(),
      category: (map['category'] ?? map['jobCategory'] ?? '').toString(),
      location: (map['location'] ?? map['address'])?.toString(),
      salary: map['salary']?.toString(),
      jobType: (map['jobType'] ?? map['job_type'])?.toString(),
      deadlineDate: _parseDate(map['deadlineDate'] ?? map['deadline_timestamp']),
      createdAt: _parseDate(map['createdAt'] ?? map['created']),
      isRecruiting: (map['recruiting'] as bool?) ?? (map['status'] == 'active'),
      applicantsCount: (map['applicants'] as int?) ?? 0,
      applicantsList: applicantsList,
      requiredSkills: (map['requiredSkills'] ?? map['required_skills']) is List
          ? List<String>.from(
              (map['requiredSkills'] ?? map['required_skills']) as List,
            )
          : const <String>[],
      experienceLevel:
          (map['experienceLevel'] ?? map['experience_level'])?.toString(),
      isVerified: (map['isVerified'] as bool?) ?? (map['is_verified'] as bool?) ?? false,
      searchKeywords: (map['searchKeywords'] as List?)?.cast<String>() ?? [],
      positionsAvailable: (map['positionsAvailable'] as int?) ?? 1,
      positionsFilled: (map['positionsFilled'] as int?) ?? 0,
      hiredApplicants: hiredApplicants,
      completedAt: _parseDate(map['completedAt']),
      approvalStatus: (map['approvalStatus'] ?? map['status'] ?? '').toString(),
      isApproved: (map['isApproved'] as bool?) ?? false,
      approvedBy: map['approvedBy']?.toString(),
      approvedAt: _parseDate(map['approvedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final keywords = <String>{};
    // Helper to tokenize
    void addTokens(String? text) {
      if (text == null || text.isEmpty) return;
      final tokens = text.toLowerCase().split(RegExp(r'[\s,._/-]+'));
      for (final t in tokens) {
        if (t.length > 1) keywords.add(t);
      }
    }

    addTokens(title);
    addTokens(category);
    addTokens(location);
    addTokens(jobType);
    for (final skill in requiredSkills) {
      addTokens(skill);
    }

    return {
      'userId': employerId,
      'name': employerName,
      'user_image': employerImage,
      'title': title,
      'description': description,
      'category': category,
      'jobCategory': category,
      'location': location,
      'salary': salary,
      'jobType': jobType,
      'deadlineDate': deadlineDate?.toIso8601String(),
      'deadline_timestamp': deadlineDate,
      'createdAt': createdAt?.toIso8601String(),
      'created': createdAt,
      'recruiting': isRecruiting,
      'status': isRecruiting ? 'active' : 'closed',
      'applicants': applicantsCount,
      'applicantsList': applicantsList,
      'requiredSkills': requiredSkills,
      'experienceLevel': experienceLevel,
      'isVerified': isVerified,
      'searchKeywords': keywords.toList(),
      'positionsAvailable': positionsAvailable,
      'positionsFilled': positionsFilled,
      'hiredApplicants': hiredApplicants,
      'completedAt': completedAt?.toIso8601String(),
      'approvalStatus': approvalStatus,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}

