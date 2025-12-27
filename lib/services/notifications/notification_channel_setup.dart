import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Notification Channels Setup
///
/// Android Oreo (API level 26) and above require notification channels.
/// Channels determine how notifications behave, sound, vibration, etc.
///
/// Channels created:
/// 1. high_importance_channel - Critical notifications
/// 2. jobs_channel - Job match and job-related notifications
/// 3. chat_channel - Chat and messaging notifications
/// 4. applications_channel - Application status notifications
/// 5. payments_channel - Payment and financial notifications
class NotificationChannelSetup {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification channels for Android
  ///
  /// Must be called in main() before showing any notifications
  static Future<void> initialize() async {
    debugPrint('🔔 [Notification Channels] Initializing...');

    try {
      // Initialize plugin
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          debugPrint('🔔 [Notification] Tapped: ${response.payload}');
        },
      );

      // Create Android channels
      await _createAndroidChannels();

      debugPrint('✅ [Notification Channels] Initialized successfully');
    } catch (e) {
      debugPrint('❌ [Notification Channels] Error: $e');
      rethrow;
    }
  }

  /// Create all Android notification channels
  ///
  /// Android requires channels to be created before sending notifications
  static Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      debugPrint('⚠️  [Notification Channels] Android plugin not available');
      return;
    }

    // Channel 1: High Importance (critical notifications)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Critical notifications that require immediate attention',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: high_importance_channel');

    // Channel 2: Jobs (new job matches, job closing soon)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'jobs_channel',
        'Job Notifications',
        description: 'New job matches and job-related updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: jobs_channel');

    // Channel 3: Chat (new messages)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'chat_channel',
        'Chat Notifications',
        description: 'New messages and chat activity',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: chat_channel');

    // Channel 4: Applications (application status updates)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'applications_channel',
        'Application Status',
        description: 'Job application status updates',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: applications_channel');

    // Channel 5: Payments (payment confirmations)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'payments_channel',
        'Payment Notifications',
        description: 'Payment confirmations and financial updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: payments_channel');

    // Channel 6: Admin (admin announcements)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'admin_channel',
        'Admin Announcements',
        description: 'Important announcements from administrators',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: admin_channel');

    // Channel 7: Social (profile views, connection requests)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'social_channel',
        'Social Notifications',
        description: 'Profile views and connection requests',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: social_channel');

    // Channel 8: Tenders & Hustles (tender and gig notifications)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'tenders_channel',
        'Tender & Gig Notifications',
        description: 'Tender and gig match notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    debugPrint('✅ Created: tenders_channel');
  }

  /// Get channel ID for notification type
  ///
  /// Maps notification type to appropriate Android channel
  static String getChannelIdForType(String notificationType) {
    return switch (notificationType) {
      'new_job_match' => 'jobs_channel',
      'job_closing_soon' => 'jobs_channel',
      'application_status' => 'applications_channel',
      'application_approved' => 'applications_channel',
      'application_rejected' => 'applications_channel',
      'chat_message' => 'chat_channel',
      'chat_group_message' => 'chat_channel',
      'tender_alert' => 'tenders_channel',
      'tender_match' => 'tenders_channel',
      'gig_alert' => 'tenders_channel',
      'gig_match' => 'tenders_channel',
      'payment_confirmation' => 'payments_channel',
      'payment_received' => 'payments_channel',
      'admin_announcement' => 'admin_channel',
      'system_update' => 'admin_channel',
      'profile_view' => 'social_channel',
      'connection_request' => 'social_channel',
      _ => 'high_importance_channel', // Default to high importance
    };
  }

  /// Show a local notification
  ///
  /// Useful for testing and for showing notifications in foreground
  ///
  /// Parameters:
  ///   - title: Notification title
  ///   - body: Notification body text
  ///   - type: Notification type (determines channel)
  static Future<void> showNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final channelId = getChannelIdForType(type);

      await _plugin.show(
        0, // Notification ID (0 for test, use unique ID in production)
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            getChannelNameForType(type),
            channelDescription: getChannelDescriptionForType(type),
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      debugPrint('✅ [Notification] Shown: $title');
    } catch (e) {
      debugPrint('❌ [Notification] Error showing: $e');
    }
  }

  /// Get channel name for notification type
  static String getChannelNameForType(String type) {
    return switch (type) {
      'new_job_match' => 'Job Notifications',
      'job_closing_soon' => 'Job Notifications',
      'application_status' => 'Application Status',
      'chat_message' => 'Chat Notifications',
      'tender_alert' => 'Tender & Gig Notifications',
      'payment_confirmation' => 'Payment Notifications',
      'admin_announcement' => 'Admin Announcements',
      'profile_view' => 'Social Notifications',
      'connection_request' => 'Social Notifications',
      _ => 'Notifications',
    };
  }

  /// Get channel description for notification type
  static String getChannelDescriptionForType(String type) {
    return switch (type) {
      'new_job_match' => 'Job matches and new opportunities',
      'job_closing_soon' => 'Reminders about closing job deadlines',
      'application_status' => 'Updates on your job applications',
      'chat_message' => 'Messages from other users',
      'tender_alert' => 'Tender and gig opportunities',
      'payment_confirmation' => 'Payment and financial updates',
      'admin_announcement' => 'Important platform announcements',
      'profile_view' => 'When someone views your profile',
      'connection_request' => 'New connection requests',
      _ => 'App notifications',
    };
  }

  /// Cancel a notification
  ///
  /// Parameters:
  ///   - id: Notification ID to cancel
  static Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint('✅ [Notification] Cancelled: $id');
    } catch (e) {
      debugPrint('❌ [Notification] Error cancelling: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      debugPrint('✅ [Notification] All cancelled');
    } catch (e) {
      debugPrint('❌ [Notification] Error cancelling all: $e');
    }
  }

  /// Get the plugin instance
  ///
  /// Use this to directly interact with FlutterLocalNotificationsPlugin
  /// if you need advanced features not exposed by this wrapper
  static FlutterLocalNotificationsPlugin get plugin => _plugin;
}
