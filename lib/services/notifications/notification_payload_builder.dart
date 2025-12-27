import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Notification Payload Builder
/// Builds notification details for different notification types
class NotificationPayloadBuilder {
  /// Build NotificationDetails from type and data
  static NotificationDetails buildFromType(
    String type,
    Map<String, dynamic> data,
  ) {
    return switch (type) {
      'new_job_match' => _buildJobMatchNotification(data),
      'chat_message' => _buildChatNotification(data),
      'application_status' => _buildApplicationNotification(data),
      'tender_alert' => _buildTenderNotification(data),
      'admin_announcement' => _buildAdminNotification(data),
      'payment_confirmation' => _buildPaymentNotification(data),
      'profile_view' => _buildProfileViewNotification(data),
      'connection_request' => _buildConnectionNotification(data),
      'job_closing_soon' => _buildJobClosingNotification(data),
      _ => _buildDefaultNotification(data),
    };
  }

  static NotificationDetails _buildJobMatchNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'jobs_channel',
        'Job Matches',
        channelDescription: 'New job matches from recommended for you',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF2196F3),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildChatNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'New messages and chat activity',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF4CAF50),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildApplicationNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'applications_channel',
        'Application Status',
        channelDescription: 'Job application status updates',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFFFF9800),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildTenderNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'tenders_channel',
        'Tender & Gig Notifications',
        channelDescription: 'Tender and gig match notifications',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFFF44336),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildAdminNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'admin_channel',
        'Admin Announcements',
        channelDescription: 'Important announcements from administrators',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF9C27B0),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildPaymentNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'payments_channel',
        'Payment Notifications',
        channelDescription: 'Payment confirmations and financial updates',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFFFFC107),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildProfileViewNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'social_channel',
        'Social Notifications',
        channelDescription: 'Profile views and connection requests',
        importance: Importance.low,
        priority: Priority.low,
        color: Color(0xFF9E9E9E),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      ),
    );
  }

  static NotificationDetails _buildConnectionNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'social_channel',
        'Social Notifications',
        channelDescription: 'Profile views and connection requests',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF009688),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildJobClosingNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'jobs_channel',
        'Job Matches',
        channelDescription: 'New job matches from recommended for you',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFFF44336),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildDefaultNotification(
    Map<String, dynamic> data,
  ) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'Important',
        channelDescription: 'Important notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}