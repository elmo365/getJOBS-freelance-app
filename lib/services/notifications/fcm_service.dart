import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Cloud Messaging (FCM) Service
///
/// Handles all FCM-related operations:
/// - Initialize Firebase Messaging
/// - Get and refresh FCM tokens
/// - Store tokens in Firestore
/// - Handle foreground/background/terminated messages
/// - Configure notification channels
///
/// This service is a singleton and should be initialized in main.dart
/// before any other Firebase operations.
///
/// Usage:
/// ```dart
/// // In main.dart
/// await FCMService.initialize();
///
/// // In app
/// final fcmToken = await FCMService.instance.getFCMToken();
/// ```
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static FCMService? _instance;

  factory FCMService() {
    _instance ??= FCMService._internal();
    return _instance!;
  }

  FCMService._internal();

  static FCMService get instance => FCMService();

  // Callbacks for handling messages (kept for potential future use)
  // ignore: unused_field
  Function(RemoteMessage)? _onMessageCallback;
  // ignore: unused_field
  Function(RemoteMessage)? _onMessageOpenedCallback;

  /// Initialize Firebase Cloud Messaging
  ///
  /// This must be called early in app initialization (main.dart)
  /// before any FCM tokens are requested.
  ///
  /// Sets up:
  /// - Request notification permissions (iOS)
  /// - Background message handler
  /// - Foreground message handler
  /// - Notification open handler
  static Future<void> initialize() async {
    debugPrint('🔔 [FCM Service] Initializing Firebase Messaging...');

    try {
      // Request notification permissions (iOS only, Android 13+ requests at install)
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
          '🔔 [FCM Service] Notification permission status: ${settings.authorizationStatus}');

      // Set foreground notification presentation options (iOS)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

      debugPrint('✅ [FCM Service] Firebase Messaging initialized');
    } catch (e) {
      debugPrint('❌ [FCM Service] Initialization error: $e');
      rethrow;
    }
  }

  /// Background message handler
  /// 
  /// Called when:
  /// - App is terminated
  /// - App is in background
  /// - User taps notification from device panel
  ///
  /// Important: This is a top-level function, NOT a method
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    debugPrint('🔔 [FCM Service] Background message received: ${message.messageId}');
    debugPrint('🔔 [FCM Service] Message type: ${message.data['type']}');

    // Handle notification (you can show local notification here if needed)
    // or perform background tasks like syncing data
  }

  /// Get current FCM token
  ///
  /// Returns the device's FCM token or null if not available.
  /// FCM token is unique per device and used to send push notifications.
  ///
  /// Returns: 'dXXXXXXXXXXXXXXXXX...' (about 160 characters)
  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('🔔 [FCM Service] Current FCM token: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('❌ [FCM Service] Error getting FCM token: $e');
      return null;
    }
  }

  /// Store FCM token in Firestore for this user
  ///
  /// Called when:
  /// - User logs in
  /// - FCM token is refreshed (every few months)
  /// - App starts (to ensure token is fresh)
  ///
  /// Token is stored in: users/{userId}/fcmToken
  ///
  /// Parameters:
  ///   - userId: Current user ID
  ///   - token: FCM token (if null, fetches new one)
  Future<void> storeFCMToken({
    required String userId,
    String? token,
  }) async {
    try {
      // Get token if not provided
      token ??= await getFCMToken();

      if (token == null) {
        debugPrint('⚠️  [FCM Service] No FCM token available for user $userId');
        return;
      }

      // Store in Firestore
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
        'devicePlatform': defaultTargetPlatform.toString().split('.').last,
      });

      debugPrint('✅ [FCM Service] FCM token stored for user $userId');
    } catch (e) {
      debugPrint('❌ [FCM Service] Error storing FCM token: $e');
      // Don't rethrow - token storage is not critical
    }
  }

  /// Listen for FCM token refresh events
  ///
  /// FCM tokens can be refreshed:
  /// - After app uninstall/reinstall
  /// - Security-related updates
  /// - Periodically (every few months)
  ///
  /// This must be called to keep tokens up to date.
  ///
  /// Parameters:
  ///   - userId: Current user ID
  ///   - onTokenRefreshed: Callback when token changes
  void listenForTokenRefresh({
    required String userId,
    Function(String newToken)? onTokenRefreshed,
  }) {
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 [FCM Service] Token refreshed: ${newToken.substring(0, 20)}...');

      // Store new token immediately
      storeFCMToken(userId: userId, token: newToken);

      // Call callback if provided
      onTokenRefreshed?.call(newToken);
    }).onError((error) {
      debugPrint('❌ [FCM Service] Token refresh error: $error');
    });
  }

  /// Listen for messages when app is in foreground
  ///
  /// Used to show custom UI notifications while user is using app
  ///
  /// Parameters:
  ///   - onMessage: Callback when message received
  void listenForForegroundMessages(
    Function(RemoteMessage message) onMessage,
  ) {
    _onMessageCallback = onMessage;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM Service] Foreground message received: ${message.messageId}');
      debugPrint('🔔 [FCM Service] Type: ${message.data['type']}');

      // Call user's callback
      onMessage(message);
    });
  }

  /// Listen for notification open events
  ///
  /// Called when:
  /// - User taps notification while app is in foreground
  /// - User taps notification while app is in background
  /// - User taps notification after app was terminated
  ///
  /// Parameters:
  ///   - onMessageOpened: Callback with message data
  void listenForNotificationOpen(
    Function(RemoteMessage message) onMessageOpened,
  ) {
    _onMessageOpenedCallback = onMessageOpened;

    // Handle notification when app is resumed from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM Service] Notification opened: ${message.messageId}');
      debugPrint('🔔 [FCM Service] Route: ${message.data['route']}');

      onMessageOpened(message);
    });
  }

  /// Subscribe to a topic
  ///
  /// Topics are useful for sending notifications to groups of users.
  /// For example: 'job_seekers', 'employers', 'admins'
  ///
  /// Parameters:
  ///   - topic: Topic name (alphanumeric, lowercase)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ [FCM Service] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM Service] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  ///
  /// Parameters:
  ///   - topic: Topic name
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ [FCM Service] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM Service] Error unsubscribing from topic: $e');
    }
  }

  /// Check if notifications are enabled
  ///
  /// Returns: true if user has enabled notifications, false otherwise
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('❌ [FCM Service] Error checking notification status: $e');
      return false;
    }
  }

  /// Disable notifications for this device
  ///
  /// This removes all permissions but doesn't uninstall FCM.
  /// User can re-enable via system settings.
  Future<void> disableNotifications() async {
    try {
      await _messaging.deleteToken();
      debugPrint('✅ [FCM Service] Notifications disabled (token deleted)');
    } catch (e) {
      debugPrint('❌ [FCM Service] Error disabling notifications: $e');
    }
  }

  /// Get detailed notification settings
  ///
  /// Returns: NotificationSettings with detailed permission info
  Future<NotificationSettings> getNotificationSettings() async {
    return _messaging.getNotificationSettings();
  }

  /// Test send notification to this device
  ///
  /// Useful for testing during development.
  /// In production, notifications are sent from Cloud Functions.
  ///
  /// Requires: Cloud Messaging REST API enabled in Firebase Console
  Future<void> testSendNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    debugPrint('🧪 [FCM Service] Test notification would be sent to: $fcmToken');
    debugPrint('🧪 [FCM Service] Title: $title');
    debugPrint('🧪 [FCM Service] Body: $body');

    // In production, this would be called from Cloud Functions
    // For testing, you can use the Firebase Console to send test messages
  }
}

/// Extension method for RemoteMessage to easily access common fields
extension RemoteMessageExtension on RemoteMessage {
  String? get notificationType => data['type'];

  String? get jobId => data['jobId'];

  String? get userId => data['userId'];

  String? get route => data['route'];

  Map<String, dynamic> get customData {
    final Map<String, dynamic> result = {...data};
    result.removeWhere((k, v) => ['type', 'jobId', 'userId', 'route'].contains(k));
    return result;
  }
}
