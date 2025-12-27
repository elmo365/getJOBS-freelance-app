import 'package:cloud_firestore/cloud_firestore.dart';

/// Extension methods for Firebase DocumentSnapshot to simplify data access
extension DocumentSnapshotExtensions on DocumentSnapshot {
  /// Get data as a `Map<String, dynamic>`
  Map<String, dynamic> get dataMap {
    final data = this.data();
    if (data == null) return {};
    return data as Map<String, dynamic>;
  }

  /// Get a value from the document data
  dynamic operator [](String key) {
    return dataMap[key];
  }
}

/// Extension methods for Firebase QueryDocumentSnapshot
extension QueryDocumentSnapshotExtensions on QueryDocumentSnapshot {
  /// Get data as a `Map<String, dynamic>`
  Map<String, dynamic> get dataMap {
    return data() as Map<String, dynamic>;
  }

  /// Get a value from the document data
  dynamic operator [](String key) {
    return dataMap[key];
  }
}

