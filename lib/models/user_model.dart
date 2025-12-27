/// User Model for BotsJobsConnect
/// Supports multiple user roles: Job Seeker, Employer, Trainer/Mentor
class UserModel {
  final String userId;
  final String email;
  final String name;
  final String? userImage;
  final String? address;
  final String? phone;
  final UserRole role;
  final bool isApproved;
  final String? approvalStatus;
  final DateTime? createdAt;
  final List<String> searchKeywords;
  
  // Company/Employer specific fields
  final String? companyName;
  final String? registrationNumber;
  final String? industry;
  final String? website;
  final String? companyDescription;
  
  // Trainer/Mentor specific fields
  final String? specialization;
  final String? bio;
  final List<String>? certifications;
  final double? rating;
  final int? ratingCount;
  final int? totalStudents;

  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    this.userImage,
    this.address,
    this.phone,
    required this.role,
    this.isApproved = false,
    this.approvalStatus,
    this.createdAt,
    this.companyName,
    this.registrationNumber,
    this.industry,
    this.website,
    this.companyDescription,
    this.specialization,
    this.bio,
    this.certifications,
    this.rating,
    this.ratingCount,
    this.totalStudents,
    this.searchKeywords = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String userId) {
    return UserModel(
      userId: userId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userImage: map['user_image'],
      address: map['address'],
      phone: map['phone'],
      role: _parseRole(map),
      isApproved: map['isApproved'] ?? false,
      approvalStatus: map['approvalStatus'],
      createdAt: map['created']?.toDate(),
      companyName: map['company_name'],
      registrationNumber: map['registration_number'],
      industry: map['industry'],
      website: map['website'],
      companyDescription: map['company_description'],
      specialization: map['specialization'],
      bio: map['bio'],
      certifications: map['certifications'] != null 
          ? List<String>.from(map['certifications']) 
          : null,
      rating: map['rating']?.toDouble(),
      ratingCount: map['rating_count'],
      totalStudents: map['total_students'],
      searchKeywords: (map['searchKeywords'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    final keywords = <String>{};
    void addTokens(String? text) {
      if (text == null || text.isEmpty) return;
      final tokens = text.toLowerCase().split(RegExp(r'[\s,._/-]+'));
      for (final t in tokens) {
        if (t.length > 1) keywords.add(t);
      }
    }

    addTokens(name);
    addTokens(companyName);
    addTokens(industry);
    addTokens(specialization);

    return {
      'email': email,
      'name': name,
      'user_image': userImage,
      'address': address,
      'phone': phone,
      'isCompany': role == UserRole.employer,
      'isTrainer': role == UserRole.trainer,
      'isJobSeeker': role == UserRole.jobSeeker,
      'isApproved': isApproved,
      'approvalStatus': approvalStatus,
      'created': createdAt,
      'company_name': companyName,
      'registration_number': registrationNumber,
      'industry': industry,
      'website': website,
      'company_description': companyDescription,
      'specialization': specialization,
      'bio': bio,
      'certifications': certifications,
      'rating': rating,
      'rating_count': ratingCount,
      'total_students': totalStudents,
      'searchKeywords': keywords.toList(),
    };
  }

  static UserRole _parseRole(Map<String, dynamic> map) {
    if (map['isTrainer'] == true || map['isMentor'] == true) {
      return UserRole.trainer;
    } else if (map['isCompany'] == true || map['isEmployer'] == true) {
      return UserRole.employer;
    } else {
      return UserRole.jobSeeker;
    }
  }

  bool get isJobSeeker => role == UserRole.jobSeeker;
  bool get isEmployer => role == UserRole.employer;
  bool get isTrainer => role == UserRole.trainer;
}

enum UserRole {
  jobSeeker,
  employer,
  trainer,
}

