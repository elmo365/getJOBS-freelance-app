import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/cache/firestore_cache_service.dart';

/// Service for managing job expiry, deadline extensions, and related operations
class JobExpiryService {
  final _firestore = FirebaseFirestore.instance;
  final _notificationService = NotificationService();

  /// Check if a job has expired based on deadline
  Future<bool> isJobExpired(String jobId) async {
    try {
      final cacheService = FirestoreCacheService();
      
      // Try cache first (5 minute TTL for job data)
      Map<String, dynamic>? cachedJob = cacheService.getCachedDoc(
        collection: 'jobs',
        docId: jobId,
        ttl: Duration(minutes: 5),
      );
      
      Map<String, dynamic>? data;
      if (cachedJob != null) {
        data = cachedJob;
        debugPrint('✅ Job data from cache for expiry check: $jobId');
      } else {
        // Cache miss, fetch from Firestore
        final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
        if (!jobDoc.exists) return true;
        data = jobDoc.data();
        
        // Cache the job document
        if (data != null) {
          cacheService.cacheDoc(
            collection: 'jobs',
            docId: jobId,
            data: data,
          );
        }
      }

      if (data == null) return true;

      final deadline = data['deadlineDate'] ?? data['deadline_timestamp'];
      if (deadline == null) return false; // No deadline = never expires

      DateTime deadlineDate;
      if (deadline is Timestamp) {
        deadlineDate = deadline.toDate();
      } else if (deadline is String) {
        deadlineDate = DateTime.parse(deadline);
      } else {
        return false;
      }

      return DateTime.now().isAfter(deadlineDate);
    } catch (e) {
      debugPrint('Error checking job expiry: $e');
      return false;
    }
  }

  /// Extend job deadline (company function)
  Future<void> extendJobDeadline({
    required String jobId,
    required DateTime newDeadline,
    required String companyId,
  }) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'deadlineDate': Timestamp.fromDate(newDeadline),
        'deadline_timestamp': Timestamp.fromDate(newDeadline),
        'lastExtended': FieldValue.serverTimestamp(),
        'extendedBy': companyId,
      });

      debugPrint('Job $jobId deadline extended to $newDeadline');
    } catch (e) {
      debugPrint('Error extending job deadline: $e');
      rethrow;
    }
  }

  /// Manually close a job (company function)
  Future<void> closeJob({
    required String jobId,
    required String companyId,
  }) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'recruiting': false,
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': companyId,
      });

      debugPrint('Job $jobId manually closed');
    } catch (e) {
      debugPrint('Error closing job: $e');
      rethrow;
    }
  }

  /// Get jobs expiring within specified days
  Future<List<Map<String, dynamic>>> getExpiringJobs(int days) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));

      final snapshot = await _firestore
          .collection('jobs')
          .where('recruiting', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      final expiringJobs = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deadline = data['deadlineDate'] ?? data['deadline_timestamp'];

        if (deadline != null) {
          DateTime deadlineDate;
          if (deadline is Timestamp) {
            deadlineDate = deadline.toDate();
          } else if (deadline is String) {
            deadlineDate = DateTime.parse(deadline);
          } else {
            continue;
          }

          // Check if deadline is between now and futureDate
          if (deadlineDate.isAfter(now) && deadlineDate.isBefore(futureDate)) {
            expiringJobs.add({
              'jobId': doc.id,
              'deadline': deadlineDate,
              'title': data['title'],
              'employerId': data['userId'] ?? data['id'],
              ...data,
            });
          }
        }
      }

      return expiringJobs;
    } catch (e) {
      debugPrint('Error getting expiring jobs: $e');
      return [];
    }
  }

  /// Close expired jobs (batch operation, can be run daily)
  Future<int> closeExpiredJobs() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('jobs')
          .where('recruiting', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      int closedCount = 0;
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deadline = data['deadlineDate'] ?? data['deadline_timestamp'];

        if (deadline != null) {
          DateTime deadlineDate;
          if (deadline is Timestamp) {
            deadlineDate = deadline.toDate();
          } else if (deadline is String) {
            deadlineDate = DateTime.parse(deadline);
          } else {
            continue;
          }

          if (now.isAfter(deadlineDate)) {
            batch.update(doc.reference, {
              'recruiting': false,
              'status': 'expired',
              'expiredAt': FieldValue.serverTimestamp(),
            });
            closedCount++;
          }
        }
      }

      if (closedCount > 0) {
        await batch.commit();
        debugPrint('Closed $closedCount expired jobs');
      }

      return closedCount;
    } catch (e) {
      debugPrint('Error closing expired jobs: $e');
      return 0;
    }
  }

  /// Notify companies about jobs closing soon
  Future<void> notifyExpiringJobs({int daysWarning = 7}) async {
    try {
      final expiringJobs = await getExpiringJobs(daysWarning);

      for (final job in expiringJobs) {
        final deadline = job['deadline'] as DateTime;
        final daysLeft = deadline.difference(DateTime.now()).inDays;
        final employerId = job['employerId']?.toString();

        if (employerId != null && employerId.isNotEmpty) {
          await _notificationService.sendNotification(
            userId: employerId,
            type: 'job_closing_soon',
            title: 'Job Closing Soon ⏰',
            body:
                'Your job "${job['title']}" closes in $daysLeft day${daysLeft == 1 ? '' : 's'}. Consider extending the deadline if you need more applications.',
            data: {
              'jobId': job['jobId'],
              'jobTitle': job['title'],
              'deadline': deadline.toIso8601String(),
              'daysLeft': daysLeft,
            },
            sendEmail: true,
          );
        }
      }

      debugPrint('Sent notifications for ${expiringJobs.length} expiring jobs');
    } catch (e) {
      debugPrint('Error notifying expiring jobs: $e');
    }
  }

  /// Notify company when job has closed
  Future<void> notifyJobClosed(String jobId, String employerId) async {
    try {
      final cacheService = FirestoreCacheService();
      
      // Try cache first (5 minute TTL)
      Map<String, dynamic>? jobData = cacheService.getCachedDoc(
        collection: 'jobs',
        docId: jobId,
        ttl: Duration(minutes: 5),
      );
      
      if (jobData == null) {
        // Cache miss, fetch from Firestore
        final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
        jobData = jobDoc.data();
        
        // Cache the job document
        if (jobData != null) {
          cacheService.cacheDoc(
            collection: 'jobs',
            docId: jobId,
            data: jobData,
          );
        }
      }

      final jobTitle = jobData?['title'] ?? 'Your job';

      await _notificationService.sendNotification(
        userId: employerId,
        type: 'job_closed',
        title: 'Job Applications Closed 🔒',
        body:
            'Applications for "$jobTitle" have closed. Review applicants in your dashboard.',
        data: {
          'jobId': jobId,
          'jobTitle': jobTitle,
          'closedAt': DateTime.now().toIso8601String(),
        },
        sendEmail: true,
      );
    } catch (e) {
      debugPrint('Error sending job closed notification: $e');
    }
  }

  /// Notify applicants when a job they applied to is closing soon
  Future<void> notifyApplicantsJobClosing({
    required String jobId,
    required String jobTitle,
    required DateTime deadline,
  }) async {
    try {
      // Get all applicants for this job
      final applicationsSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .get();

      final daysLeft = deadline.difference(DateTime.now()).inDays;

      for (final appDoc in applicationsSnapshot.docs) {
        final appData = appDoc.data();
        final applicantId = appData['userId']?.toString();

        if (applicantId != null && applicantId.isNotEmpty) {
          await _notificationService.sendNotification(
            userId: applicantId,
            type: 'applied_job_closing',
            title: 'Job Closing Soon 📅',
            body:
                'The job "$jobTitle" you applied for closes in $daysLeft day${daysLeft == 1 ? '' : 's'}.',
            data: {
              'jobId': jobId,
              'jobTitle': jobTitle,
              'deadline': deadline.toIso8601String(),
              'daysLeft': daysLeft,
            },
            sendEmail: false, // Don't spam applicants with emails
          );
        }
      }

      debugPrint(
          'Notified ${applicationsSnapshot.docs.length} applicants about job $jobId closing');
    } catch (e) {
      debugPrint('Error notifying applicants: $e');
    }
  }

  /// Notify users who bookmarked a job when it's closing soon
  Future<void> notifyBookmarkedJobClosing({
    required String jobId,
    required String jobTitle,
    required DateTime deadline,
  }) async {
    try {
      // Get all users who saved this job
      final usersSnapshot = await _firestore.collection('users').get();

      final daysLeft = deadline.difference(DateTime.now()).inDays;
      int notifiedCount = 0;

      for (final userDoc in usersSnapshot.docs) {
        final savedJobsRef =
            userDoc.reference.collection('saved_jobs').doc(jobId);
        final savedJobDoc = await savedJobsRef.get();

        if (savedJobDoc.exists) {
          await _notificationService.sendNotification(
            userId: userDoc.id,
            type: 'bookmarked_job_closing',
            title: 'Saved Job Closing Soon 🔖',
            body:
                'A job you saved, "$jobTitle", closes in $daysLeft day${daysLeft == 1 ? '' : 's'}. Apply now!',
            data: {
              'jobId': jobId,
              'jobTitle': jobTitle,
              'deadline': deadline.toIso8601String(),
              'daysLeft': daysLeft,
            },
            sendEmail: false,
          );
          notifiedCount++;
        }
      }

      debugPrint(
          'Notified $notifiedCount users about bookmarked job $jobId closing');
    } catch (e) {
      debugPrint('Error notifying bookmarked users: $e');
    }
  }
}
