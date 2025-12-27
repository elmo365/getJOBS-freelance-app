/// Tender Model for Tenders Portal
class TenderModel {
  final String tenderId;
  final String organizationId;
  final String organizationName;
  final String title;
  final String description;
  final String category;
  final double? budget;
  final DateTime? deadline;
  final DateTime? createdAt;
  final String? location;
  final List<String>? requiredDocuments;
  final String? status; // Open, Closed, Awarded
  final bool isVerified;
  final List<String>? tags;

  TenderModel({
    required this.tenderId,
    required this.organizationId,
    required this.organizationName,
    required this.title,
    required this.description,
    required this.category,
    this.budget,
    this.deadline,
    this.createdAt,
    this.location,
    this.requiredDocuments,
    this.status = 'Open',
    this.isVerified = false,
    this.tags,
  });

  factory TenderModel.fromMap(Map<String, dynamic> map, String tenderId) {
    return TenderModel(
      tenderId: tenderId,
      organizationId: map['organization_id'] ?? '',
      organizationName: map['organization_name'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      budget: map['budget']?.toDouble(),
      deadline: map['deadline']?.toDate(),
      createdAt: map['created_at']?.toDate(),
      location: map['location'],
      requiredDocuments: map['required_documents'] != null
          ? List<String>.from(map['required_documents'])
          : null,
      status: map['status'] ?? 'Open',
      isVerified: map['is_verified'] ?? false,
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
      'budget': budget,
      'deadline': deadline,
      'created_at': createdAt,
      'location': location,
      'required_documents': requiredDocuments,
      'status': status,
      'is_verified': isVerified,
      'tags': tags,
    };
  }
}

