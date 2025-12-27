/// Gig Model for Gig Space module
class GigModel {
  final String gigId;
  final String freelancerId;
  final String freelancerName;
  final String? freelancerImage;
  final String title;
  final String description;
  final String category;
  final double price;
  final String? deliveryTime; // e.g., "3 days", "1 week"
  final List<String>? tags;
  final List<String>? images;
  final double? rating;
  final int totalOrders;
  final DateTime? createdAt;
  final bool isActive;
  final List<String>? packages; // Basic, Standard, Premium

  GigModel({
    required this.gigId,
    required this.freelancerId,
    required this.freelancerName,
    this.freelancerImage,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.deliveryTime,
    this.tags,
    this.images,
    this.rating,
    this.totalOrders = 0,
    this.createdAt,
    this.isActive = true,
    this.packages,
  });

  factory GigModel.fromMap(Map<String, dynamic> map, String gigId) {
    return GigModel(
      gigId: gigId,
      freelancerId: map['freelancer_id'] ?? '',
      freelancerName: map['freelancer_name'] ?? '',
      freelancerImage: map['freelancer_image'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      deliveryTime: map['delivery_time'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      rating: map['rating']?.toDouble(),
      totalOrders: map['total_orders'] ?? 0,
      createdAt: map['created_at']?.toDate(),
      isActive: map['is_active'] ?? true,
      packages: map['packages'] != null ? List<String>.from(map['packages']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'freelancer_id': freelancerId,
      'freelancer_name': freelancerName,
      'freelancer_image': freelancerImage,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'delivery_time': deliveryTime,
      'tags': tags,
      'images': images,
      'rating': rating,
      'total_orders': totalOrders,
      'created_at': createdAt,
      'is_active': isActive,
      'packages': packages,
    };
  }
}

