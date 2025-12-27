import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_config.dart';

/// Firebase Firestore Database Service
/// Handles all database CRUD operations
class FirebaseDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a collection reference
  CollectionReference getCollection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  // ==================== USERS ====================

  /// Create a new user document
  Future<DocumentSnapshot> createUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .set(data);

      return await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .get();
    } on FirebaseException catch (e) {
      debugPrint('createUser error => code: ${e.code}, message: ${e.message}');
      throw _handleException(e);
    }
  }

  /// Get user by ID
  Future<DocumentSnapshot?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return doc;
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Update user document
  Future<DocumentSnapshot> updateUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .update(data);

      return await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Search users with filters
  Future<QuerySnapshot> searchUsers({
    bool? isCompany,
    String? approvalStatus,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConfig.usersCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (isCompany != null) {
        query = query.where('isCompany', isEqualTo: isCompany);
      }

      if (approvalStatus != null) {
        query = query.where('approvalStatus', isEqualTo: approvalStatus);
      }

      return await query.get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get admin users (for notifications, audit, etc.)
  Future<QuerySnapshot> getAdminUsers({int limit = 100}) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.usersCollection)
          .where('isAdmin', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get users by account type
  Future<QuerySnapshot> getUsersByType({
    required String accountType,
    int limit = 25,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.usersCollection)
          .where('accountType', isEqualTo: accountType)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get pending company approvals (for admin)
  Future<QuerySnapshot> getPendingCompanies() async {
    try {
      return await _firestore
          .collection(FirebaseConfig.usersCollection)
          .where('accountType', isEqualTo: 'company')
          .where('approvalStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== CVs ====================

  /// Create a new CV document
  Future<DocumentSnapshot> createCV(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore
          .collection('cvs')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return await docRef.get();
    } on FirebaseException catch (e) {
      debugPrint('createCV error => code: ${e.code}, message: ${e.message}');
      throw _handleException(e);
    }
  }

  /// Get CV by user ID
  Future<DocumentSnapshot?> getCVByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('cvs')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint('getCVByUserId error => code: ${e.code}, message: ${e.message}');
      throw _handleException(e);
    }
  }

  /// Update CV
  Future<void> updateCV({
    required String cvId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('cvs').doc(cvId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('updateCV error => code: ${e.code}, message: ${e.message}');
      throw _handleException(e);
    }
  }

  // ==================== JOBS ====================

  /// Get jobs by user ID
  Future<QuerySnapshot> getUserJobs(String userId) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
    } on FirebaseException catch (e) {
      debugPrint('getUserJobs error => code: ${e.code}, message: ${e.message}');
      throw _handleException(e);
    }
  }

  /// Create a new job posting
  Future<DocumentSnapshot> createJob(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .add(data);

      return await docRef.get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get job by ID
  Future<DocumentSnapshot?> getJob(String jobId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .doc(jobId)
          .get();

      if (!doc.exists) return null;
      return doc;
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Update job
  Future<DocumentSnapshot> updateJob({
    required String jobId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .doc(jobId)
          .update(data);

      return await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .doc(jobId)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Soft delete job (marks as deleted and updates applications)
  Future<void> softDeleteJob(String jobId) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Mark Job as deleted
      batch.update(_firestore.collection(FirebaseConfig.jobsCollection).doc(jobId), {
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // 2. Mark applications as "jobDeleted"
      final apps = await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .get();
      
      for (var doc in apps.docs) {
        batch.update(doc.reference, {'jobDeleted': true});
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .doc(jobId)
          .delete();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get all active jobs
  Future<QuerySnapshot> getActiveJobs({
    int limit = 25,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Search jobs by category
  Future<QuerySnapshot> getJobsByCategory({
    required String category,
    int limit = 25,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .where('jobCategory', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get jobs posted by a company
  Future<QuerySnapshot> getJobsByCompany({
    required String userId,
    int limit = 25,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.jobsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Search jobs with filters
  Future<QuerySnapshot> searchJobs({
    String? keyword,
    String? category,
    String? location,
    String? experienceLevel,
    String? userId,
    int limit = 25,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConfig.jobsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (userId != null && userId.isNotEmpty) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('jobCategory', isEqualTo: category);
      }

      if (experienceLevel != null && experienceLevel.isNotEmpty) {
        query = query.where('experienceLevel', isEqualTo: experienceLevel);
      }

      if (keyword != null && keyword.trim().isNotEmpty) {
        query = query.where('searchKeywords', arrayContains: keyword.trim().toLowerCase());
      }

      return await query.get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== APPLICATIONS ====================

  /// Submit job application atomically
  Future<void> submitApplicationTransaction({
    required String jobId,
    required String userId,
    required Map<String, dynamic> applicationData,
    required Map<String, dynamic> applicantBrief,
  }) async {
    final applicationRef = _firestore
        .collection(FirebaseConfig.applicationsCollection)
        .doc(); // Generate new ID
    final jobRef = _firestore.collection(FirebaseConfig.jobsCollection).doc(jobId);

    await _firestore.runTransaction((transaction) async {
      // 1. Check if already applied (safety)
      final appQuery = await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .where('userId', isEqualTo: userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();
      if (appQuery.docs.isNotEmpty) {
        throw Exception("You have already applied for this job.");
      }

      // 2. Create Application
      transaction.set(applicationRef, {
        ...applicationData,
        'id': applicationRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Job doc
      transaction.update(jobRef, {
        'applicantsList': FieldValue.arrayUnion([
          {
            ...applicantBrief,
            'id': userId,
            'timeapplied': Timestamp.now(),
          }
        ]),
        'applicants': FieldValue.increment(1),
      });
    });
  }

  /// Submit job application
  Future<DocumentSnapshot> createApplication(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .add(data);

      return await docRef.get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get application by ID
  Future<DocumentSnapshot?> getApplication(String applicationId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .doc(applicationId)
          .get();

      if (!doc.exists) return null;
      return doc;
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Update application status
  Future<DocumentSnapshot> updateApplication({
    required String applicationId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .doc(applicationId)
          .update(data);

      return await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .doc(applicationId)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get applications for a specific job
  Future<QuerySnapshot> getApplicationsByJob(String jobId) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .orderBy('createdAt', descending: true)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get applications for a job
  Future<QuerySnapshot> getApplicationsForJob({
    required String jobId,
    int limit = 50,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get applications by user
  Future<QuerySnapshot> getApplicationsByUser({
    required String userId,
    int limit = 50,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      // If orderBy fails, try without it
      try {
        return await _firestore
            .collection(FirebaseConfig.applicationsCollection)
            .where('userId', isEqualTo: userId)
            .limit(limit)
            .get();
      } catch (e2) {
        throw _handleException(e);
      }
    }
  }

  /// Check if user already applied to job
  Future<bool> hasUserApplied({
    required String userId,
    required String jobId,
  }) async {
    try {
      final result = await _firestore
          .collection(FirebaseConfig.applicationsCollection)
          .where('userId', isEqualTo: userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== INTERVIEWS ====================

  /// Get interviews by user ID
  Future<QuerySnapshot> getUserInterviews(String userId) async {
    try {
      return await _firestore
          .collection('interviews')
          .where('employer_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
    } on FirebaseException catch (e) {
      debugPrint('getUserInterviews error => code: ${e.code}, message: ${e.message}');
      throw _handleException(e);
    }
  }

  /// Schedule an interview
  Future<DocumentSnapshot> createInterview(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConfig.interviewsCollection)
          .add(data);

      return await docRef.get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get interviews for a candidate
  Future<QuerySnapshot> getInterviewsForCandidate({
    required String candidateId,
    int limit = 25,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.interviewsCollection)
          .where('candidateId', isEqualTo: candidateId)
          .orderBy('scheduledDate', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get interviews for an employer
  Future<QuerySnapshot> getInterviewsForEmployer({
    required String employerId,
    int limit = 25,
  }) async {
    try {
      return await _firestore
          .collection(FirebaseConfig.interviewsCollection)
          .where('employerId', isEqualTo: employerId)
          .orderBy('scheduledDate', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Update interview
  Future<DocumentSnapshot> updateInterview({
    required String interviewId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConfig.interviewsCollection)
          .doc(interviewId)
          .update(data);

      return await _firestore
          .collection(FirebaseConfig.interviewsCollection)
          .doc(interviewId)
          .get();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Log administrative actions for audit trail
  Future<void> logAdminAction({
    required String adminId,
    required String action, // e.g., 'approve_company', 'reject_job', 'update_monetization'
    required String targetId,
    required String targetType, // 'company', 'job', 'settings'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('admin_audit_logs').add({
        'adminId': adminId,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to log admin action: $e');
      // Non-blocking error
    }
  }

  // ==================== JOB CLOSURE ====================

  /// Request job closure (creates closure request for admin approval if hired applicants exist)
  /// If no hired applicants: directly closes job and revokes applications
  Future<String> requestJobClosure({
    required String jobId,
    required String employerId,
    required String jobTitle,
    required String closureReason,
    required List<Map<String, dynamic>> hiredApplicants,
    required List<String> applicantsToNotify,
    required int totalApplications,
  }) async {
    try {
      // If no hired applicants, close immediately without admin approval
      if (hiredApplicants.isEmpty) {
        return await _performSimpleJobClosure(
          jobId: jobId,
          applicantsToNotify: applicantsToNotify,
          closureReason: closureReason,
        );
      }

      // Otherwise, create closure request for admin review
      final requestId = _firestore.collection('job_closure_requests').doc().id;
      await _firestore.collection('job_closure_requests').doc(requestId).set({
        'jobId': jobId,
        'employerId': employerId,
        'jobTitle': jobTitle,
        'closureReason': closureReason,
        'hiredApplicants': hiredApplicants,
        'applicantsToNotify': applicantsToNotify,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'adminId': null,
        'adminResponse': null,
        'totalApplications': totalApplications,
      });

      // Log admin audit
      await logAdminAction(
        adminId: 'system', // Employer initiated
        action: 'job_closure_requested',
        targetId: jobId,
        targetType: 'job',
        metadata: {
          'employerId': employerId,
          'closureReason': closureReason,
          'hiredApplicantsCount': hiredApplicants.length,
          'requestId': requestId,
        },
      );

      return requestId;
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Perform simple job closure (no hired applicants)
  /// Revokes pending applications and closes job immediately
  Future<String> _performSimpleJobClosure({
    required String jobId,
    required List<String> applicantsToNotify,
    required String closureReason,
  }) async {
    try {
      // Update job status
      await updateJob(jobId: jobId, data: {
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'closeReason': closureReason,
        'closureType': 'simple', // Not with hired applicants
      });

      // Revoke pending applications (don't mark as rejected - just clear)
      // This way applicants don't see unnecessary rejections
      if (applicantsToNotify.isNotEmpty) {
        final batch = _firestore.batch();

        // Find applications from these users for this job
        final applicationsQuery = await _firestore
            .collection('applications')
            .where('jobId', isEqualTo: jobId)
            .where('userId', whereIn: applicantsToNotify)
            .get();

        for (final doc in applicationsQuery.docs) {
          // Mark as withdrawn (not rejected)
          batch.update(doc.reference, {
            'status': 'withdrawn',
            'withdrawnAt': FieldValue.serverTimestamp(),
            'withdrawReason': 'Job posting was closed',
          });
        }

        await batch.commit();
      }

      return jobId;
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Admin approves job closure
  Future<void> approveJobClosure({
    required String requestId,
    required String adminId,
    String? adminResponse,
  }) async {
    try {
      // Get the request
      final requestDoc =
          await _firestore.collection('job_closure_requests').doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Closure request not found');

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final jobId = requestData['jobId'] as String;
      final applicantsToNotify =
          List<String>.from(requestData['applicantsToNotify'] as List? ?? []);
      final closureReason = requestData['closureReason'] as String? ?? '';

      // Update request status
      await _firestore.collection('job_closure_requests').doc(requestId).update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'adminId': adminId,
        'adminResponse': adminResponse ?? 'Approved',
      });

      // Close the job
      await updateJob(jobId: jobId, data: {
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'closeReason': closureReason,
        'closureType': 'approved_by_admin',
        'closureRequestId': requestId,
      });

      // Revoke pending applications
      if (applicantsToNotify.isNotEmpty) {
        final batch = _firestore.batch();

        final applicationsQuery = await _firestore
            .collection('applications')
            .where('jobId', isEqualTo: jobId)
            .where('userId', whereIn: applicantsToNotify)
            .get();

        for (final doc in applicationsQuery.docs) {
          batch.update(doc.reference, {
            'status': 'withdrawn',
            'withdrawnAt': FieldValue.serverTimestamp(),
            'withdrawReason': 'Job posting was closed - position filled',
          });
        }

        await batch.commit();
      }

      // Log admin action
      await logAdminAction(
        adminId: adminId,
        action: 'job_closure_approved',
        targetId: jobId,
        targetType: 'job',
        metadata: {
          'requestId': requestId,
          'applicantsWithdrawn': applicantsToNotify.length,
        },
      );
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Admin rejects job closure request
  Future<void> rejectJobClosure({
    required String requestId,
    required String adminId,
    required String rejectionReason,
  }) async {
    try {
      await _firestore.collection('job_closure_requests').doc(requestId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'adminId': adminId,
        'adminResponse': rejectionReason,
      });

      // Log admin action
      await logAdminAction(
        adminId: adminId,
        action: 'job_closure_rejected',
        targetId: 'unknown',
        targetType: 'job_closure_request',
        metadata: {
          'requestId': requestId,
          'reason': rejectionReason,
        },
      );
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get pending closure requests for admin
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingClosureRequests() {
    return _firestore
        .collection('job_closure_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get closure requests for a specific job
  Future<QuerySnapshot<Map<String, dynamic>>> getJobClosureRequests(
    String jobId,
  ) async {
    return _firestore
        .collection('job_closure_requests')
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  /// Check if job has hired applicants
  Future<List<Map<String, dynamic>>> getHiredApplicants(String jobId) async {
    try {
      final result = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: 'accepted')
          .get();

      return result.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'] ?? '',
          'name': data['applicantName'] ?? data['name'] ?? 'Unknown',
          'email': data['applicantEmail'] ?? data['email'] ?? '',
          'phone': data['phone'],
          'userImage': data['applicantImage'] ?? data['userImage'],
          'hiredDate': data['acceptedAt'] ?? FieldValue.serverTimestamp(),
          'notes': data['notes'],
        };
      }).toList();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get applications to notify (pending or applied, but not accepted/rejected)
  Future<List<String>> getApplicantsToNotify(String jobId) async {
    try {
      final result = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('status', whereIn: ['pending', 'applied', 'shortlisted'])
          .get();

      return result.docs.map((doc) => doc['userId'] as String? ?? '').toList();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Handle Firebase exceptions
  String _handleException(FirebaseException e) {
    switch (e.code) {
      case 'not-found':
        return 'Resource not found.';
      case 'permission-denied':
        return 'Permission denied. Please login again.';
      case 'invalid-argument':
        return 'Invalid data provided.';
      case 'already-exists':
        return 'Resource already exists.';
      case 'unavailable':
        return 'Service unavailable. Please try again later.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }
}

