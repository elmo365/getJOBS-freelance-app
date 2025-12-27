import 'package:flutter/foundation.dart';

/// Rating Model for bidirectional ratings
class RatingModel {
  final String ratingId;
  final String raterId; // User who gave the rating
  final String raterType; // 'company' or 'jobSeeker'
  final String ratedUserId; // User being rated
  final String ratedUserType; // 'jobSeeker' or 'company'
  final String jobId; // Job associated with the rating
  final String? jobTitle; // Job title for reference
  final double rating; // Rating value (0-5)
  final String? feedback; // Optional feedback/review text
  final DateTime createdAt; // When the rating was created

  RatingModel({
    required this.ratingId,
    required this.raterId,
    required this.raterType,
    required this.ratedUserId,
    required this.ratedUserType,
    required this.jobId,
    this.jobTitle,
    required this.rating,
    this.feedback,
    required this.createdAt,
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

  factory RatingModel.fromMap(Map<String, dynamic> map, String ratingId) {
    return RatingModel(
      ratingId: ratingId,
      raterId: map['raterId'] as String? ?? '',
      raterType: map['raterType'] as String? ?? 'company',
      ratedUserId: map['ratedUserId'] as String? ?? '',
      ratedUserType: map['ratedUserType'] as String? ?? 'jobSeeker',
      jobId: map['jobId'] as String? ?? '',
      jobTitle: map['jobTitle'] as String?,
      rating: _validateRating(map['rating']),
      feedback: map['feedback'] as String?,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'raterId': raterId,
      'raterType': raterType,
      'ratedUserId': ratedUserId,
      'ratedUserType': ratedUserType,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'rating': rating,
      'feedback': feedback,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Rating Type Constants
class RatingType {
  static const String company = 'company'; // Company rating a job seeker
  static const String jobSeeker = 'jobSeeker'; // Job seeker rating a company
}

/// User Type Constants for Ratings
class RatedUserType {
  static const String jobSeeker = 'jobSeeker';
  static const String company = 'company';
}
/// Helper method to validate rating data
double _validateRating(dynamic rawRating) {
  try {
    final rating = (rawRating as num?)?.toDouble();
    if (rating == null || rating < 0 || rating > 5) {
      throw Exception('Invalid rating value: $rating');
    }
    return rating;
  } catch (e) {
    debugPrint('❌ ERROR: Failed to parse rating: $e');
    throw Exception('Rating data validation failed');
  }
}