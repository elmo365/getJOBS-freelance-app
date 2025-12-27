import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to manage API keys stored in Firestore
/// Allows admins to configure API keys through the admin portal
class APIKeysService {
  static final APIKeysService _instance = APIKeysService._internal();
  factory APIKeysService() => _instance;
  APIKeysService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'api_keys';
  static const String _documentId = 'config';

  // Cache for API keys (reduced to 1 minute for faster updates)
  Map<String, String>? _cachedKeys;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 1);

  /// Get all API keys from Firestore
  Future<Map<String, String>> getAllKeys() async {
    // Return cached keys if still valid
    if (_cachedKeys != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedKeys!;
    }

    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ API keys document not found. Using defaults.');
        _cachedKeys = _getDefaultKeys();
        _cacheTimestamp = DateTime.now();
        return _cachedKeys!;
      }

      final data = doc.data() ?? {};
      _cachedKeys = Map<String, String>.from(
        (data as Map).map((key, value) => MapEntry(key.toString(), value?.toString() ?? '')),
      );
      _cacheTimestamp = DateTime.now();
      return _cachedKeys!;
    } catch (e) {
      debugPrint('❌ Error loading API keys: $e');
      _cachedKeys = _getDefaultKeys();
      _cacheTimestamp = DateTime.now();
      return _cachedKeys!;
    }
  }

  /// Get a specific API key
  Future<String> getKey(String keyName) async {
    final keys = await getAllKeys();
    return keys[keyName] ?? '';
  }

  /// Update API keys (admin only)
  Future<bool> updateKeys(Map<String, String> keys) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set({
        ...keys,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin', // Could be enhanced to track admin user ID
      }, SetOptions(merge: true));

      // Clear cache to force reload
      _cachedKeys = null;
      _cacheTimestamp = null;

      debugPrint('✅ API keys updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating API keys: $e');
      return false;
    }
  }

  /// Update a single API key
  Future<bool> updateKey(String keyName, String keyValue) async {
    final currentKeys = await getAllKeys();
    currentKeys[keyName] = keyValue;
    return await updateKeys(currentKeys);
  }

  /// Get default/empty keys structure
  Map<String, String> _getDefaultKeys() {
    return {
      'gemini_api_key': '',
      'gemini_model': 'gemini-1.5-flash',
      'brevo_api_key': '',
      'brevo_from_email': 'noreply@botsjobsconnect.com',
      'brevo_from_name': 'BotsJobsConnect',
    };
  }

  /// Get all available API key names
  List<Map<String, dynamic>> getAvailableKeys() {
    return [
      {
        'key': 'gemini_api_key',
        'label': 'Gemini AI API Key',
        'description': 'Google Gemini AI API key for AI features (CV analysis, job matching, etc.)',
        'type': 'password',
        'required': true,
        'helpUrl': 'https://makersuite.google.com/app/apikey',
      },
      {
        'key': 'gemini_model',
        'label': 'Gemini Model',
        'description': 'Gemini model to use (e.g., gemini-1.5-flash, gemini-pro)',
        'type': 'text',
        'required': false,
        'defaultValue': 'gemini-1.5-flash',
      },
      {
        'key': 'brevo_api_key',
        'label': 'Brevo API Key',
        'description': 'Brevo (formerly Sendinblue) API key for email sending',
        'type': 'password',
        'required': false,
        'helpUrl': 'https://app.brevo.com/settings/keys/api',
      },
      {
        'key': 'brevo_from_email',
        'label': 'Brevo From Email',
        'description': 'Email address to send emails from',
        'type': 'email',
        'required': false,
        'defaultValue': 'noreply@botsjobsconnect.com',
      },
      {
        'key': 'brevo_from_name',
        'label': 'Brevo From Name',
        'description': 'Display name for sent emails',
        'type': 'text',
        'required': false,
        'defaultValue': 'BotsJobsConnect',
      },
    ];
  }

  /// Clear cache (useful after updates)
  void clearCache() {
    _cachedKeys = null;
    _cacheTimestamp = null;
  }
}

