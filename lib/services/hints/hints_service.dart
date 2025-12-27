import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/services/monetization_visibility_service.dart';

/// Service to manage hints system across the app
/// Handles user preferences and admin overrides
class HintsService {
  static final HintsService _instance = HintsService._internal();
  factory HintsService() => _instance;
  HintsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MonetizationVisibilityService _monetizationService = MonetizationVisibilityService();

  // Cache for user preferences
  bool? _userHintsEnabled;
  bool? _adminHintsEnabled;
  bool? _aiHintsEnabled; // Admin setting for AI hints
  DateTime? _lastFetch;

  /// Check if hints should be shown for the current user
  /// Returns false if admin has disabled hints globally
  /// Returns user preference if admin hasn't overridden
  Future<bool> areHintsEnabled() async {
    // Check cache (5 minute TTL)
    if (_lastFetch != null && 
        DateTime.now().difference(_lastFetch!).inMinutes < 5 &&
        _adminHintsEnabled != null) {
      if (_adminHintsEnabled == false) return false;
      return _userHintsEnabled ?? true; // Default to enabled
    }

    try {
      // Check admin global setting first
      final adminSettingsDoc = await _firestore
          .collection('app_settings')
          .doc('hints')
          .get();

      if (adminSettingsDoc.exists) {
        final data = adminSettingsDoc.data() ?? {};
        _adminHintsEnabled = data['enabled'] as bool? ?? true;
        
        // If admin disabled globally, return false
        if (_adminHintsEnabled == false) {
          _lastFetch = DateTime.now();
          return false;
        }
      } else {
        _adminHintsEnabled = true; // Default to enabled
      }

      // Check user preference
      final user = _auth.currentUser;
      if (user != null) {
        final userPrefsDoc = await _firestore
            .collection('user_preferences')
            .doc(user.uid)
            .get();

        if (userPrefsDoc.exists) {
          final data = userPrefsDoc.data() ?? {};
          _userHintsEnabled = data['hints_enabled'] as bool? ?? true;
        } else {
          _userHintsEnabled = true; // Default to enabled
        }
      } else {
        _userHintsEnabled = true; // Default for non-authenticated
      }

      _lastFetch = DateTime.now();
      return _userHintsEnabled ?? true;
    } catch (e) {
      // On error, default to enabled
      return true;
    }
  }

  /// Save user's hints preference
  Future<void> setUserHintsEnabled(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .set({
        'hints_enabled': enabled,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _userHintsEnabled = enabled;
      _lastFetch = DateTime.now();
    } catch (e) {
      // Silently fail - preference will be checked on next load
    }
  }

  /// Admin: Set global hints enabled/disabled for all users
  Future<void> setAdminHintsEnabled(bool enabled) async {
    try {
      await _firestore
          .collection('app_settings')
          .doc('hints')
          .set({
        'enabled': enabled,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': _auth.currentUser?.uid,
      });

      _adminHintsEnabled = enabled;
      _lastFetch = DateTime.now();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if monetization is enabled (for conditional hints)
  Future<bool> isMonetizationEnabled() async {
    return await _monetizationService.isWalletVisible();
  }

  /// Check if AI hints are enabled (admin setting)
  /// Returns false if AI hints are disabled globally
  Future<bool> areAIHintsEnabled() async {
    // Check cache (5 minute TTL)
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5 &&
        _aiHintsEnabled != null) {
      return _aiHintsEnabled ?? false; // Default to disabled
    }

    try {
      final adminSettingsDoc = await _firestore
          .collection('app_settings')
          .doc('hints')
          .get();

      if (adminSettingsDoc.exists) {
        final data = adminSettingsDoc.data() ?? {};
        _aiHintsEnabled = data['ai_hints_enabled'] as bool? ?? false;
      } else {
        _aiHintsEnabled = false; // Default to disabled
      }

      _lastFetch = DateTime.now();
      return _aiHintsEnabled ?? false;
    } catch (e) {
      // On error, default to disabled
      return false;
    }
  }

  /// Admin: Set AI hints enabled/disabled globally
  Future<void> setAIHintsEnabled(bool enabled) async {
    try {
      await _firestore
          .collection('app_settings')
          .doc('hints')
          .set({
        'ai_hints_enabled': enabled,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': _auth.currentUser?.uid,
      }, SetOptions(merge: true));

      _aiHintsEnabled = enabled;
      _lastFetch = DateTime.now();
    } catch (e) {
      rethrow;
    }
  }

  /// Clear cache (useful after settings changes)
  void clearCache() {
    _userHintsEnabled = null;
    _adminHintsEnabled = null;
    _aiHintsEnabled = null;
    _lastFetch = null;
  }
}

