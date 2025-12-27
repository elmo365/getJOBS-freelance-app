import 'package:cloud_firestore/cloud_firestore.dart';

class SavedSearchService {
  final FirebaseFirestore _firestore;

  SavedSearchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('saved_searches');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSavedSearches({
    required String userId,
    int limit = 20,
  }) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> saveSearch({
    required String userId,
    required String label,
    String? keyword,
    String? category,
    String? experienceLevel,
    String? locationQuery,
    String? sort,
  }) async {
    await _col.add({
      'userId': userId,
      'label': label,
      'keyword': keyword,
      'category': category,
      'experienceLevel': experienceLevel,
      'locationQuery': locationQuery,
      'sort': sort,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSavedSearch({
    required String savedSearchId,
  }) async {
    await _col.doc(savedSearchId).delete();
  }
}
