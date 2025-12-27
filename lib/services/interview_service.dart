import 'package:freelance_app/models/interview_model.dart';
import 'package:intl/intl.dart';

/// Service for managing interviews, conflict detection, and timezone operations
class InterviewService {
  static const String botswanaTimezone = 'Africa/Gaborone';
  static const int botswanaUtcOffset = 2; // UTC+2
  static const int defaultMinimumGapMinutes = 30; // Minimum gap between consecutive interviews

  /// Convert UTC DateTime to Botswana time (UTC+2)
  static DateTime convertToBotswanaTime(DateTime utcDateTime) {
    return utcDateTime.add(const Duration(hours: 2));
  }

  /// Convert Botswana time to UTC for storage
  static DateTime convertToUtc(DateTime botswanaDateTime) {
    return botswanaDateTime.subtract(const Duration(hours: 2));
  }

  /// Format DateTime for display in Botswana timezone
  static String formatForDisplay(DateTime utcDateTime) {
    final botswanaTime = convertToBotswanaTime(utcDateTime);
    final formatter = DateFormat('EEE, MMM d, yyyy • h:mm a');
    return formatter.format(botswanaTime);
  }

  /// Format time only for display
  static String formatTimeOnly(DateTime utcDateTime) {
    final botswanaTime = convertToBotswanaTime(utcDateTime);
    final formatter = DateFormat('h:mm a');
    return formatter.format(botswanaTime);
  }

  /// Format date only for display
  static String formatDateOnly(DateTime utcDateTime) {
    final botswanaTime = convertToBotswanaTime(utcDateTime);
    final formatter = DateFormat('EEE, MMM d, yyyy');
    return formatter.format(botswanaTime);
  }

  /// Check if interview is happening soon (within 15 minutes)
  static bool isHappeningSoon(DateTime utcDateTime) {
    final now = DateTime.now();
    final difference = utcDateTime.difference(now);
    return difference.inMinutes <= 15 && difference.isNegative == false;
  }

  /// Check if interview has started
  static bool hasStarted(DateTime utcDateTime) {
    return DateTime.now().isAfter(utcDateTime);
  }

  /// Check if two interviews conflict
  /// Returns true if they overlap considering the minimum gap requirement
  static bool intervalsConflict(
    DateTime start1,
    int durationMinutes1,
    DateTime start2,
    int durationMinutes2, {
    int minimumGapMinutes = defaultMinimumGapMinutes,
  }) {
    final end1 = start1.add(Duration(minutes: durationMinutes1));
    final end2 = start2.add(Duration(minutes: durationMinutes2));

    // Apply minimum gap requirement
    final endWithGap1 = end1.add(Duration(minutes: minimumGapMinutes));
    final endWithGap2 = end2.add(Duration(minutes: minimumGapMinutes));

    // Check if they overlap
    return !(endWithGap1.isBefore(start2) || endWithGap2.isBefore(start1));
  }

  /// Detect conflicts for a candidate's interviews
  /// Returns a map of interview IDs to list of conflicting interview IDs
  static Map<String, List<String>> detectConflicts(
    List<InterviewModel> interviews, {
    int minimumGapMinutes = defaultMinimumGapMinutes,
  }) {
    final conflicts = <String, List<String>>{};

    for (int i = 0; i < interviews.length; i++) {
      conflicts[interviews[i].interviewId] = [];

      for (int j = 0; j < interviews.length; j++) {
        if (i != j) {
          final hasConflict = intervalsConflict(
            interviews[i].scheduledDate,
            interviews[i].durationMinutes,
            interviews[j].scheduledDate,
            interviews[j].durationMinutes,
            minimumGapMinutes: minimumGapMinutes,
          );

          if (hasConflict) {
            conflicts[interviews[i].interviewId]!.add(interviews[j].interviewId);
          }
        }
      }
    }

    return conflicts;
  }

  /// Get suggested next available time slot for an interview
  /// considering existing interviews and minimum gap
  static DateTime getSuggestedNextSlot(
    DateTime requestedTime,
    List<InterviewModel> existingInterviews,
    int interviewDurationMinutes, {
    int minimumGapMinutes = defaultMinimumGapMinutes,
  }) {
    var suggestedTime = requestedTime;
    var attempts = 0;
    const maxAttempts = 100;

    while (attempts < maxAttempts) {
      bool hasConflict = false;

      for (final interview in existingInterviews) {
        if (intervalsConflict(
          suggestedTime,
          interviewDurationMinutes,
          interview.scheduledDate,
          interview.durationMinutes,
          minimumGapMinutes: minimumGapMinutes,
        )) {
          hasConflict = true;
          // Move to 30 minutes after the conflicting interview ends
          final conflictEnd =
              interview.scheduledDate.add(Duration(minutes: interview.durationMinutes));
          suggestedTime = conflictEnd.add(Duration(minutes: minimumGapMinutes));
          break;
        }
      }

      if (!hasConflict) {
        return suggestedTime;
      }

      attempts++;
    }

    return suggestedTime;
  }

  /// Format conflict message for display
  static String formatConflictMessage(
    DateTime conflictingTime,
    int durationMinutes,
    String jobTitle,
  ) {
    final endTime = conflictingTime.add(Duration(minutes: durationMinutes));
    final startStr = formatTimeOnly(conflictingTime);
    final endStr = formatTimeOnly(endTime);
    return 'Conflict with: $jobTitle\n$startStr - $endStr';
  }

  /// Check if interview time is in the past
  static bool isPastDateTime(DateTime dateTime) {
    return DateTime.now().isAfter(dateTime);
  }

  /// Get time remaining until interview (as formatted string)
  static String getTimeRemaining(DateTime utcDateTime) {
    final now = DateTime.now();
    final difference = utcDateTime.difference(now);

    if (difference.isNegative) {
      return 'Interview has ended';
    }

    if (difference.inSeconds < 0) {
      return 'Now';
    }

    if (difference.inMinutes < 1) {
      return 'In less than a minute';
    }

    if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    }

    if (difference.inHours < 24) {
      return 'In ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    }

    final days = difference.inDays;
    return 'In $days day${days == 1 ? '' : 's'}';
  }

  /// Calculate interview end time
  static DateTime calculateEndTime(DateTime startTime, int durationMinutes) {
    return startTime.add(Duration(minutes: durationMinutes));
  }

  /// Check if candidate is available for new interview
  static ({
    bool available,
    String? reason,
    DateTime? suggestedTime,
  }) checkAvailability(
    DateTime proposedTime,
    int durationMinutes,
    List<InterviewModel> existingInterviews, {
    int minimumGapMinutes = defaultMinimumGapMinutes,
  }) {
    for (final interview in existingInterviews) {
      if (interview.status == 'Cancelled') continue; // Skip cancelled interviews

      if (intervalsConflict(
        proposedTime,
        durationMinutes,
        interview.scheduledDate,
        interview.durationMinutes,
        minimumGapMinutes: minimumGapMinutes,
      )) {
        final suggestedSlot = getSuggestedNextSlot(
          proposedTime,
          existingInterviews,
          durationMinutes,
          minimumGapMinutes: minimumGapMinutes,
        );

        return (
          available: false,
          reason:
              'Conflict with another interview. Job seeker has a ${interview.durationMinutes} minute interview with ${interview.employerName} scheduled for ${formatTimeOnly(interview.scheduledDate)}. Please reschedule to at least ${formatTimeOnly(suggestedSlot)}.',
          suggestedTime: suggestedSlot,
        );
      }
    }

    return (available: true, reason: null, suggestedTime: null);
  }
}
