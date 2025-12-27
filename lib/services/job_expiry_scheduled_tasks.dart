import 'package:flutter/foundation.dart';
import 'package:freelance_app/services/job_expiry_service.dart';

/// Service to run scheduled tasks for job expiry management
/// Can be called manually or via Cloud Function scheduler
class JobExpiryScheduledTasks {
  final _expiryService = JobExpiryService();

  /// Run all daily maintenance tasks
  /// Call this once per day (e.g., via Cloud Function scheduled at midnight)
  Future<Map<String, dynamic>> runDailyTasks() async {
    debugPrint('🕐 Running daily job expiry tasks...');

    final results = <String, dynamic>{};

    try {
      // Task 1: Close expired jobs
      final closedCount = await _expiryService.closeExpiredJobs();
      results['closedJobs'] = closedCount;
      debugPrint('✅ Closed $closedCount expired jobs');

      // Task 2: Send 7-day warnings
      await _expiryService.notifyExpiringJobs(daysWarning: 7);
      results['warnings7Days'] = 'sent';
      debugPrint('✅ Sent 7-day warnings');

      // Task 3: Send 3-day urgent warnings
      await _expiryService.notifyExpiringJobs(daysWarning: 3);
      results['warnings3Days'] = 'sent';
      debugPrint('✅ Sent 3-day urgent warnings');

      // Task 4: Send 1-day critical warnings
      await _expiryService.notifyExpiringJobs(daysWarning: 1);
      results['warnings1Day'] = 'sent';
      debugPrint('✅ Sent 1-day critical warnings');

      // Task 5: Notify applicants about jobs closing in 3 days
      final jobsClosingIn3Days = await _expiryService.getExpiringJobs(3);
      for (final job in jobsClosingIn3Days) {
        await _expiryService.notifyApplicantsJobClosing(
          jobId: job['jobId'],
          jobTitle: job['title'],
          deadline: job['deadline'],
        );
        await _expiryService.notifyBookmarkedJobClosing(
          jobId: job['jobId'],
          jobTitle: job['title'],
          deadline: job['deadline'],
        );
      }
      results['applicantNotifications'] = 'sent';
      debugPrint('✅ Sent applicant notifications');

      results['success'] = true;
      results['timestamp'] = DateTime.now().toIso8601String();

      debugPrint('✅ Daily job expiry tasks completed successfully');
    } catch (e) {
      debugPrint('❌ Error in daily tasks: $e');
      results['success'] = false;
      results['error'] = e.toString();
    }

    return results;
  }

  /// Test method - run expiry notifications for all thresholds
  /// Useful for testing without waiting for scheduled execution
  Future<void> testNotifications() async {
    debugPrint('🧪 Testing expiry notifications...');

    try {
      // Get jobs expiring within 30 days
      final expiringJobs = await _expiryService.getExpiringJobs(30);
      debugPrint('Found ${expiringJobs.length} jobs expiring within 30 days');

      for (final job in expiringJobs) {
        final deadline = job['deadline'] as DateTime;
        final daysLeft = deadline.difference(DateTime.now()).inDays;
        debugPrint(
            '  - ${job['title']}: $daysLeft days until ${deadline.toLocal().toString().split(' ')[0]}');
      }

      // Send notifications
      await _expiryService.notifyExpiringJobs(daysWarning: 7);
      debugPrint('✅ Test notifications sent');
    } catch (e) {
      debugPrint('❌ Test failed: $e');
    }
  }
}
