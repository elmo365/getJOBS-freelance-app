import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';

/// Firebase Realtime Service
/// Handles real-time data subscriptions for live updates using Firestore snapshots
class FirebaseRealtimeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Subscribe to jobs collection changes
  Stream<QuerySnapshot> subscribeToJobs({
    String? categoryFilter,
    String? userId,
  }) {
    Query query = _firestore
        .collection(FirebaseConfig.jobsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.where('jobCategory', isEqualTo: categoryFilter);
    }

    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots();
  }

  /// Subscribe to user document changes
  Stream<DocumentSnapshot> subscribeToUser(String userId) {
    return _firestore
        .collection(FirebaseConfig.usersCollection)
        .doc(userId)
        .snapshots();
  }

  /// Subscribe to applications for a job
  Stream<QuerySnapshot> subscribeToApplications(String jobId) {
    return _firestore
        .collection(FirebaseConfig.applicationsCollection)
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Subscribe to applications for a user
  Stream<QuerySnapshot> subscribeToUserApplications(String userId) {
    return _firestore
        .collection(FirebaseConfig.applicationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Subscribe to interviews for a candidate
  Stream<QuerySnapshot> subscribeToInterviews(String userId) {
    return _firestore
        .collection(FirebaseConfig.interviewsCollection)
        .where('candidateId', isEqualTo: userId)
        .orderBy('scheduledDate', descending: true)
        .snapshots();
  }

  /// Subscribe to interviews for an employer
  Stream<QuerySnapshot> subscribeToEmployerInterviews(String employerId) {
    return _firestore
        .collection(FirebaseConfig.interviewsCollection)
        .where('employerId', isEqualTo: employerId)
        .orderBy('scheduledDate', descending: true)
        .snapshots();
  }
}

