import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin Setup Utility
/// Used to configure admin users in the system
class AdminSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Set a user as admin by their email address
  /// This updates the user's document to have isAdmin = true
  static Future<bool> setAdminByEmail(String email) async {
    try {
      // Find user by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('AdminSetup: No user found with email: $email');
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      
      // Update user to be admin
      await userDoc.reference.update({
        'isAdmin': true,
        'userType': 'admin',
        'adminGrantedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('AdminSetup: Successfully set $email as admin');
      return true;
    } catch (e) {
      debugPrint('AdminSetup: Error setting admin: $e');
      return false;
    }
  }

  /// Check if a user is admin by their email
  static Future<bool> isAdminByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('AdminSetup: Error checking admin status: $e');
      return false;
    }
  }

  /// Remove admin privileges from a user
  static Future<bool> removeAdminByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      
      await userDoc.reference.update({
        'isAdmin': false,
        'userType': 'job_seeker',
        'adminRevokedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('AdminSetup: Error removing admin: $e');
      return false;
    }
  }

  /// Initialize default admin user
  /// Call this during app initialization if needed
  static Future<void> initializeDefaultAdmin() async {
    const defaultAdminEmail = 'ricardodiane365@gmail.com';
    
    final isAlreadyAdmin = await isAdminByEmail(defaultAdminEmail);
    if (!isAlreadyAdmin) {
      final success = await setAdminByEmail(defaultAdminEmail);
      if (success) {
        debugPrint('AdminSetup: Default admin initialized: $defaultAdminEmail');
      }
    } else {
      debugPrint('AdminSetup: Default admin already exists: $defaultAdminEmail');
    }
  }
}

