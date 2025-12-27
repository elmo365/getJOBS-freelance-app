import 'package:intl/intl.dart';

/// Centralized date formatting utility for consistent date display across the app
class DateFormatter {
  /// Format date as DD/MM/YYYY (e.g., "24/12/2025")
  static String formatDateSlash(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format date as YYYY-MM-DD (e.g., "2025-12-24")
  static String formatDateDash(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date as MMM d, y (e.g., "Dec 24, 2025")
  static String formatDateMedium(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format date as MMMM d, y (e.g., "December 24, 2025")
  static String formatDateLong(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format time as h:mm a (e.g., "3:45 PM")
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format datetime as "MMM d, y h:mm a" (e.g., "Dec 24, 2025 3:45 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  /// Format datetime with localized pattern
  static String formatDateTimeLocalized(DateTime dateTime) {
    return DateFormat.yMMMMd().add_jm().format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago", "3 days ago", "Just now")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  /// Format date for list display (e.g., "Posted 2 hours ago" or "Posted Dec 24, 2025")
  static String formatDateForList(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return formatRelativeTime(dateTime);
    } else {
      return formatDateMedium(dateTime);
    }
  }

  /// Parse DateTime from various string formats
  static DateTime? parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    // Try ISO8601 format first
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Ignore and continue
    }

    // Try other common formats
    final formats = [
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'MMM d, y',
      'MMMM d, y',
      'd/M/y',
      'M/d/y',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateString);
      } catch (e) {
        // Continue to next format
      }
    }

    return null;
  }

  /// Check if a DateTime is overdue
  static bool isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  /// Get days remaining until deadline
  static int daysRemaining(DateTime deadline) {
    return deadline.difference(DateTime.now()).inDays;
  }

  /// Get human-readable countdown (e.g., "2 days left", "1 hour left")
  static String formatCountdown(DateTime deadline) {
    final remaining = daysRemaining(deadline);

    if (remaining < 0) {
      return 'Deadline passed';
    } else if (remaining == 0) {
      final hoursRemaining = deadline.difference(DateTime.now()).inHours;
      if (hoursRemaining <= 0) {
        return 'Closing soon';
      }
      return '$hoursRemaining hour${hoursRemaining > 1 ? 's' : ''} left';
    } else if (remaining == 1) {
      return '1 day left';
    } else {
      return '$remaining days left';
    }
  }
}
