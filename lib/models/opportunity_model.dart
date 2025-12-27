/// Opportunity Model for Youth Opportunities Hub
class OpportunityModel {
  final String opportunityId;
  final String organizationId;
  final String organizationName;
  final String title;
  final String description;
  final String category; // Internship, Scholarship, Volunteer, Program
  final String? location;
  final DateTime? deadline;
  final DateTime? createdAt;
  final String? ageRange;
  final String? eligibility;
  final List<String>? benefits;
  final bool isVerified;
  final String? applicationUrl;
  final List<String>? tags;

  OpportunityModel({
    required this.opportunityId,
    required this.organizationId,
    required this.organizationName,
    required this.title,
    required this.description,
    required this.category,
    this.location,
    this.deadline,
    this.createdAt,
    this.ageRange,
    this.eligibility,
    this.benefits,
    this.isVerified = false,
    this.applicationUrl,
    this.tags,
  });

  factory OpportunityModel.fromMap(Map<String, dynamic> map, String opportunityId) {
    return OpportunityModel(
      opportunityId: opportunityId,
      organizationId: map['organization_id'] ?? '',
      organizationName: map['organization_name'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'],
      deadline: map['deadline']?.toDate(),
      createdAt: map['created_at']?.toDate(),
      ageRange: map['age_range'],
      eligibility: map['eligibility'],
      benefits: map['benefits'] != null ? List<String>.from(map['benefits']) : null,
      isVerified: map['is_verified'] ?? false,
      applicationUrl: map['application_url'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organization_id': organizationId,
      'organization_name': organizationName,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'deadline': deadline,
      'created_at': createdAt,
      'age_range': ageRange,
      'eligibility': eligibility,
      'benefits': benefits,
      'is_verified': isVerified,
      'application_url': applicationUrl,
      'tags': tags,
    };
  }
}

