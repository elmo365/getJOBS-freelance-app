import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages user rating initialization and aggregation
class RatingAggregationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize user with default 5-star rating (called on signup)
  Future<void> initializeUserRating(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data() ?? {};
      final avgRating = data['avgRating'];
      final ratingCount = data['ratingCount'];

      // Only initialize if not already set
      if (avgRating == null || ratingCount == null) {
        await _firestore.collection('users').doc(userId).update({
          'avgRating': 5.0,
          'ratingCount': 0,
          'initializedRating': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrintStack(label: 'Error initializing user rating: $e');
    }
  }

  /// Update user's rating after a new rating is created
  /// This is called from the client after a rating is submitted
  Future<void> updateUserRatingAggregate(String userId) async {
    try {
      // Fetch all approved ratings for this user
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .where('isApproved', isEqualTo: true)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        // No ratings yet, keep default 5.0
        await _firestore.collection('users').doc(userId).update({
          'avgRating': 5.0,
          'ratingCount': 0,
        });
        return;
      }

      // Calculate average
      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
        totalRating += rating;
      }

      final avgRating = totalRating / ratingsSnapshot.docs.length;
      final ratingCount = ratingsSnapshot.docs.length;

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'avgRating': double.parse(avgRating.toStringAsFixed(1)),
        'ratingCount': ratingCount,
        'lastRatingUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrintStack(label: 'Error updating user rating aggregate: $e');
    }
  }
}
