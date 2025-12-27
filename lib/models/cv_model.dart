/// CV/Resume Model for Digital CV Builder
/// Aligned with industry standards (Upwork, Freelancer, Internshala)
class CVModel {
  final String cvId;
  final String userId;
  final PersonalInfo personalInfo;
  final List<Education> education;
  final List<Experience> experience;
  final List<String> skills;
  final List<Language> languages; // Changed from List<String> to List<Language>
  final String? summary;
  final List<Certification> certifications; // Changed from List<String>? to List<Certification>
  final List<Project> projects; // New: Projects/Portfolio section
  final String? videoResumeUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String templateId;
  final bool isSearchable;

  CVModel({
    required this.cvId,
    required this.userId,
    required this.personalInfo,
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.languages = const [],
    this.summary,
    this.certifications = const [],
    this.projects = const [],
    this.videoResumeUrl,
    this.createdAt,
    this.updatedAt,
    this.templateId = 'default',
    this.isSearchable = true,
  });

  factory CVModel.fromMap(Map<String, dynamic> map, String cvId) {
    return CVModel(
      cvId: cvId,
      userId: map['user_id'] ?? '',
      personalInfo: PersonalInfo.fromMap(map['personal_info'] ?? {}),
      education: (map['education'] as List<dynamic>?)
              ?.map((e) => Education.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      experience: (map['experience'] as List<dynamic>?)
              ?.map((e) => Experience.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      skills: map['skills'] != null ? List<String>.from(map['skills']) : [],
      languages: (map['languages'] as List<dynamic>?)
              ?.map((l) => Language.fromMap(l is Map<String, dynamic>
                  ? l
                  : <String, dynamic>{'name': l.toString(), 'proficiency': 'intermediate'}))
              .toList() ??
          [],
      summary: map['summary'],
      certifications: (map['certifications'] as List<dynamic>?)
              ?.map((c) => Certification.fromMap(c is Map<String, dynamic>
                  ? c
                  : <String, dynamic>{'name': c.toString()}))
              .toList() ??
          [],
      projects: (map['projects'] as List<dynamic>?)
              ?.map((p) => Project.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      videoResumeUrl: map['video_resume_url'],
      createdAt: map['created_at']?.toDate(),
      updatedAt: map['updated_at']?.toDate(),
      templateId: map['template_id'] ?? 'default',
      isSearchable: map['is_searchable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'personal_info': personalInfo.toMap(),
      'education': education.map((e) => e.toMap()).toList(),
      'experience': experience.map((e) => e.toMap()).toList(),
      'skills': skills,
      'languages': languages.map((l) => l.toMap()).toList(),
      'summary': summary,
      'certifications': certifications.map((c) => c.toMap()).toList(),
      'projects': projects.map((p) => p.toMap()).toList(),
      'video_resume_url': videoResumeUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'template_id': templateId,
      'is_searchable': isSearchable,
    };
  }
}

class PersonalInfo {
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? linkedIn;
  final String? portfolio;
  final String? profileImage;
  final String? professionalTitle; // New: Professional headline/title

  PersonalInfo({
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.linkedIn,
    this.portfolio,
    this.profileImage,
    this.professionalTitle,
  });

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      linkedIn: map['linkedin'],
      portfolio: map['portfolio'],
      profileImage: map['profile_image'],
      professionalTitle: map['professional_title'] ?? map['title'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'linkedin': linkedIn,
      'portfolio': portfolio,
      'profile_image': profileImage,
      'professional_title': professionalTitle,
    };
  }
}

class Education {
  final String institution;
  final String? degree;
  final String? fieldOfStudy;
  final String? startDate;
  final String? endDate;
  final String? gpa;
  final String? description;
  final String? educationType; // 'formal', 'online', 'self-taught', 'workshop', 'certification'

  Education({
    required this.institution,
    this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.gpa,
    this.description,
    this.educationType,
  });

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      institution: map['institution'] ?? '',
      degree: map['degree'],
      fieldOfStudy: map['field_of_study'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      gpa: map['gpa'],
      description: map['description'],
      educationType: map['education_type'] ?? map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institution': institution,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_date': startDate,
      'end_date': endDate,
      'gpa': gpa,
      'description': description,
      'education_type': educationType,
    };
  }
}

class Experience {
  final String company;
  final String position;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;
  final List<String>? achievements;

  Experience({
    required this.company,
    required this.position,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
    this.achievements,
  });

  factory Experience.fromMap(Map<String, dynamic> map) {
    return Experience(
      company: map['company'] ?? '',
      position: map['position'] ?? '',
      startDate: map['start_date'],
      endDate: map['end_date'],
      isCurrent: map['is_current'] ?? false,
      description: map['description'],
      achievements: map['achievements'] != null
          ? List<String>.from(map['achievements'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'position': position,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'description': description,
      'achievements': achievements,
    };
  }
}

/// Language with proficiency level (industry standard)
class Language {
  final String name;
  final String proficiency; // 'basic', 'intermediate', 'advanced', 'native'

  Language({
    required this.name,
    this.proficiency = 'intermediate',
  });

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      name: map['name'] ?? '',
      proficiency: map['proficiency'] ?? 'intermediate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'proficiency': proficiency,
    };
  }
}

/// Detailed Certification (industry standard)
class Certification {
  final String name;
  final String? issuer; // Issuing organization
  final String? issueDate;
  final String? expiryDate;
  final String? credentialId; // Certificate ID/URL
  final String? credentialUrl; // Link to verify certificate

  Certification({
    required this.name,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      name: map['name'] ?? '',
      issuer: map['issuer'],
      issueDate: map['issue_date'] ?? map['issueDate'],
      expiryDate: map['expiry_date'] ?? map['expiryDate'],
      credentialId: map['credential_id'] ?? map['credentialId'],
      credentialUrl: map['credential_url'] ?? map['credentialUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'issuer': issuer,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'credential_id': credentialId,
      'credential_url': credentialUrl,
    };
  }
}

/// Project/Portfolio item (industry standard)
class Project {
  final String name;
  final String? description;
  final String? url; // Project URL/GitHub link
  final String? startDate;
  final String? endDate;
  final List<String>? technologies; // Technologies used
  final String? role; // Role in project (if team project)

  Project({
    required this.name,
    this.description,
    this.url,
    this.startDate,
    this.endDate,
    this.technologies,
    this.role,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      name: map['name'] ?? '',
      description: map['description'],
      url: map['url'],
      startDate: map['start_date'] ?? map['startDate'],
      endDate: map['end_date'] ?? map['endDate'],
      technologies: map['technologies'] != null
          ? List<String>.from(map['technologies'])
          : null,
      role: map['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'url': url,
      'start_date': startDate,
      'end_date': endDate,
      'technologies': technologies,
      'role': role,
    };
  }
}

