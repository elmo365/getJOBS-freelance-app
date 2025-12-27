import 'package:cloud_firestore/cloud_firestore.dart';

/// Content Moderation Service
/// In-app implementation for text content moderation
/// Checks for: profanity, spam, suspicious patterns
/// Integrates with approval workflows via compliance_warnings collection
class ContentModerationService {
  static final ContentModerationService _instance =
      ContentModerationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Common profanity list (basic - can be expanded)
  static const List<String> _profanityList = [
    'badword1',
    'badword2',
    'badword3',
    'offensive1',
    'offensive2',
  ];

  // Spam patterns
  static const List<String> _spamPatterns = [
    r'(?:http|https)://',
    r'\$\d+k',
    r'click here',
    r'buy now',
    r'free money',
    r'work from home',
    r'easy cash',
    r'guaranteed',
    r'limited offer',
    r'act now',
  ];

  // Suspicious character patterns
  static const List<String> _suspiciousPatterns = [
    r'[^\w\s\.\,\!\?\-\@]', // Non-standard characters
    r'([a-zA-Z])\1{3,}', // Excessive character repetition
    r'\d{6,}', // Too many consecutive numbers
  ];

  factory ContentModerationService() {
    return _instance;
  }

  ContentModerationService._internal();

  /// Moderate content and return flags
  /// Returns: Map with keys: flagged, reasons[], severity (low/medium/high), score (0-100)
  Future<Map<String, dynamic>> moderateContent(
    String content, {
    String? context, // Type: job_title, job_description, company_name, user_profile, etc.
  }) async {
    try {
      final flags = <String>[];
      int severityScore = 0;

      // Check profanity
      final profanityCheck = _checkProfanity(content);
      if (profanityCheck['found']) {
        flags.addAll(List<String>.from(profanityCheck['matches']));
        severityScore += 30;
      }

      // Check spam patterns
      final spamCheck = _checkSpam(content);
      if (spamCheck['found']) {
        flags.addAll(List<String>.from(spamCheck['matches']));
        severityScore += 25;
      }

      // Check suspicious patterns
      final suspiciousCheck = _checkSuspicious(content);
      if (suspiciousCheck['found']) {
        flags.addAll(List<String>.from(suspiciousCheck['matches']));
        severityScore += 20;
      }

      // Context-specific checks
      final contextCheck = _contextSpecificChecks(content, context);
      if (contextCheck['found']) {
        flags.addAll(List<String>.from(contextCheck['matches']));
        severityScore += contextCheck['score'] as int;
      }

      // Determine severity
      String severity = 'low';
      if (severityScore >= 70) {
        severity = 'high';
      } else if (severityScore >= 40) {
        severity = 'medium';
      }

      // Clamp score to 100
      final score = (severityScore > 100 ? 100 : severityScore).clamp(0, 100);

      return {
        'flagged': flags.isNotEmpty,
        'reasons': flags,
        'severity': severity,
        'score': score,
        'context': context ?? 'unknown',
      };
    } catch (e) {
      // Error in moderation - return clean result
      return {
        'flagged': false,
        'reasons': [],
        'severity': 'unknown',
        'score': 0,
        'error': e.toString(),
      };
    }
  }

  /// Check content against profanity list
  Map<String, dynamic> _checkProfanity(String content) {
    final lowerContent = content.toLowerCase();
    final matches = <String>[];

    for (final word in _profanityList) {
      if (lowerContent.contains(word)) {
        matches.add('profanity: $word');
      }
    }

    return {
      'found': matches.isNotEmpty,
      'matches': matches,
    };
  }

  /// Check for spam patterns
  Map<String, dynamic> _checkSpam(String content) {
    final matches = <String>[];

    for (final pattern in _spamPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(content)) {
        matches.add('spam: ${pattern.substring(0, 20)}...');
      }
    }

    return {
      'found': matches.isNotEmpty,
      'matches': matches,
    };
  }

  /// Check for suspicious patterns
  Map<String, dynamic> _checkSuspicious(String content) {
    final matches = <String>[];

    for (final pattern in _suspiciousPatterns) {
      final regex = RegExp(pattern);
      if (regex.hasMatch(content)) {
        matches.add('suspicious: pattern detected');
      }
    }

    return {
      'found': matches.isNotEmpty,
      'matches': matches,
    };
  }

  /// Context-specific moderation rules
  Map<String, dynamic> _contextSpecificChecks(String? content, String? context) {
    if (content == null || context == null) {
      return {'found': false, 'matches': [], 'score': 0};
    }

    final matches = <String>[];
    int score = 0;

    switch (context) {
      case 'job_title':
        // Job titles should be concise (< 100 chars) and descriptive
        if (content.length > 100) {
          matches.add('job_title_too_long');
          score += 10;
        }
        if (content.split(' ').length > 15) {
          matches.add('job_title_too_many_words');
          score += 10;
        }
        break;

      case 'job_description':
        // Job descriptions should have reasonable length
        if (content.length < 50) {
          matches.add('job_description_too_short');
          score += 5;
        }
        if (content.length > 10000) {
          matches.add('job_description_too_long');
          score += 10;
        }
        // Check for excessive caps
        final capsRatio = content
                .split('')
                .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
                .length /
            content.length;
        if (capsRatio > 0.5) {
          matches.add('excessive_capitalization');
          score += 15;
        }
        break;

      case 'company_name':
        // Company names should be reasonable length
        if (content.length < 2) {
          matches.add('company_name_too_short');
          score += 10;
        }
        if (content.length > 100) {
          matches.add('company_name_too_long');
          score += 10;
        }
        break;

      case 'user_profile':
        // Profile content should be reasonable
        if (content.length > 5000) {
          matches.add('profile_too_long');
          score += 10;
        }
        break;

      default:
        break;
    }

    return {
      'found': matches.isNotEmpty,
      'matches': matches,
      'score': score,
    };
  }

  /// Auto-flag content and create compliance warning
  /// Returns: true if flagged, false if clean
  Future<bool> autoFlagContent(
    String contentId,
    String contentType,
    String content, {
    String? userId,
    String? context,
  }) async {
    try {
      final moderation = await moderateContent(content, context: context);

      if (moderation['flagged'] as bool) {
        // Create compliance warning
        final warnings = _firestore.collection('compliance_warnings');
        await warnings.add({
          'contentId': contentId,
          'contentType': contentType,
          'userId': userId,
          'reason': (moderation['reasons'] as List).take(3).toList(),
          'severity': moderation['severity'],
          'score': moderation['score'],
          'context': moderation['context'],
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'automatedFlag': true,
          'source': 'content_moderation_service',
        });

        // Log to audit trail
        await _firestore.collection('admin_audit_logs').add({
          'timestamp': FieldValue.serverTimestamp(),
          'action': 'content_flagged',
          'contentId': contentId,
          'contentType': contentType,
          'userId': userId,
          'reason': moderation['reasons'],
          'severity': moderation['severity'],
          'type': 'content_moderation',
          'automatedFlag': true,
        });

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Batch moderate multiple content items
  /// Returns: List of moderation results with indices
  Future<List<Map<String, dynamic>>> moderateBatch(
    List<String> contents, {
    String? context,
  }) async {
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < contents.length; i++) {
      final result = await moderateContent(contents[i], context: context);
      results.add({
        'index': i,
        ...result,
      });
    }

    return results;
  }

  /// Get moderation statistics
  Future<Map<String, dynamic>> getModerationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('admin_audit_logs');

      // Filter by action
      query = query.where('action', isEqualTo: 'content_flagged');

      // Filter by date range if provided
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snap = await query.get();

      // Aggregate statistics
      final stats = {
        'total_flagged': snap.size,
        'by_severity': {'low': 0, 'medium': 0, 'high': 0},
        'by_type': <String, int>{},
        'by_reason': <String, int>{},
      };

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Count by severity
        final severity = data['severity'] ?? 'unknown';
        if (stats['by_severity'] is Map) {
          final severityMap = stats['by_severity'] as Map;
          if (severityMap.containsKey(severity)) {
            severityMap[severity] = (severityMap[severity] as int) + 1;
          }
        }

        // Count by content type
        final type = data['contentType'] ?? 'unknown';
        final typeMap = stats['by_type'] as Map<String, int>;
        typeMap[type] = (typeMap[type] ?? 0) + 1;

        // Count by reason
        final reasons = data['reason'] as List?;
        if (reasons != null) {
          for (final reason in reasons) {
            final reasonStr = reason.toString();
            final reasonMap = stats['by_reason'] as Map<String, int>;
            reasonMap[reasonStr] = (reasonMap[reasonStr] ?? 0) + 1;
          }
        }
      }

      return stats;
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Clear old moderation flags (older than specified days)
  /// Returns: Number of flags cleared
  Future<int> clearOldFlags({int daysOld = 90}) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysOld));

      final snap = await _firestore
          .collection('compliance_warnings')
          .where('createdAt',
              isLessThan: Timestamp.fromDate(cutoffDate))
          .where('status', isEqualTo: 'dismissed')
          .get();

      int cleared = 0;
      for (final doc in snap.docs) {
        await doc.reference.delete();
        cleared++;
      }

      // Log cleanup action
      if (cleared > 0) {
        await _firestore.collection('admin_audit_logs').add({
          'timestamp': FieldValue.serverTimestamp(),
          'action': 'cleanup_old_flags',
          'count': cleared,
          'daysOld': daysOld,
          'type': 'maintenance',
        });
      }

      return cleared;
    } catch (e) {
      return 0;
    }
  }
}
