import 'package:flutter/foundation.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';

/// Service to gather and format context for AI prompts.
/// This acts as a lightweight RAG (Retrieval-Augmented Generation) system.
class ContextService {
  static final ContextService _instance = ContextService._internal();
  factory ContextService() => _instance;
  ContextService._internal();

  final _db = FirebaseDatabaseService();

  /// Builds a comprehensive user profile context for AI.
  /// Aggregates data from User document, CV, and recent activity (if available).
  Future<Map<String, dynamic>> buildUserProfileContext(String userId) async {
    try {
      // 1. Fetch Basic User Data
      final userDoc = await _db.getUser(userId);
      final userData = userDoc?.data() as Map<String, dynamic>? ?? {};

      // 2. Fetch CV Data
      final cvDoc = await _db.getCVByUserId(userId);
      final cvData = (cvDoc != null && cvDoc.exists)
          ? (cvDoc.data() as Map<String, dynamic>?)
          : null;
      final cvDataMap = cvData ?? {};

      // 3. Process and Flatten Data for AI
      // Combining skills from CV and User profile if they exist separately
      final userSkills = <String>{};
      if (cvDataMap['skills'] != null) {
        userSkills.addAll((cvDataMap['skills'] as List)
            .map((s) => s.toString().toLowerCase()));
      }
      if (userData['skills'] != null) {
        userSkills.addAll((userData['skills'] as List)
            .map((s) => s.toString().toLowerCase()));
      }

      // Extract work experience summary
      final experience = (cvDataMap['experience'] as List<dynamic>? ?? [])
          .map((e) {
            final exp = e as Map<String, dynamic>? ?? {};
            return "${exp['position']} at ${exp['company']}";
          })
          .take(5) // Limit to top 5 recent roles to save tokens
          .toList();

      // Calculate years of experience
      int yearsExperience = 0;
      // ... logic copied from JobSeekersHome and enhanced ...
      for (final exp in (cvDataMap['experience'] as List<dynamic>? ?? [])) {
        final expMap = exp as Map<String, dynamic>? ?? {};
        final startDateStr = expMap['startDate']?.toString();
        if (startDateStr != null) {
          try {
            final start = DateTime.parse(startDateStr);
            final endStr = expMap['endDate']?.toString();
            final end =
                endStr != null ? DateTime.parse(endStr) : DateTime.now();
            yearsExperience += (end.difference(start).inDays / 365).floor();
          } catch (_) {}
        }
      }

      return {
        'userId': userId,
        'name': userData['name'] ?? 'User',
        'role': userData['accountType'] ?? 'job_seeker',
        'location': userData['location'] ?? 'Botswana',
        'skills': userSkills.toList(),
        'experienceYears': yearsExperience,
        'recentRoles': experience,
        'education': (cvDataMap['education'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        'bio': userData['bio'] ?? cvDataMap['summary'] ?? '',
      };
    } catch (e) {
      debugPrint('Error building user context: $e');
      return {'userId': userId, 'error': 'Failed to load profile'};
    }
  }

  /// Builds context for a specific job, including employer details if needed.
  Future<Map<String, dynamic>> buildJobContext(String jobId) async {
    try {
      final jobDoc = await _db.getJob(jobId);
      if (jobDoc == null || !jobDoc.exists) return {};

      final jobData = jobDoc.data() as Map<String, dynamic>? ?? {};

      // Sanitizing huge descriptions
      String description = jobData['description'] ?? jobData['desc'] ?? '';
      if (description.length > 2000) {
        description = '${description.substring(0, 2000)}... (truncated)';
      }

      return {
        'jobId': jobId,
        'title': jobData['title'] ?? 'Job',
        'company': jobData['employerName'] ?? jobData['name'] ?? 'Company',
        'description': description,
        'requirements': jobData['requiredSkills'] ?? [],
        'location': jobData['location'] ?? 'Remote',
        'salary': jobData['salary'] ?? 'Not specified',
        'type': jobData['jobType'] ?? 'Full-time',
      };
    } catch (e) {
      debugPrint('Error building job context: $e');
      return {'jobId': jobId, 'error': 'Failed to load job'};
    }
  }
}
