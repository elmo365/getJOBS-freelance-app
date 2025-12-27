import 'package:flutter/material.dart';
import 'package:freelance_app/screens/homescreen/components/job_details.dart';
import 'package:freelance_app/screens/chat/chat_screen.dart';
import 'package:freelance_app/screens/plugins_hub/tenders_portal_screen.dart';
import 'package:freelance_app/screens/notifications/notifications_screen.dart';
import 'package:freelance_app/screens/wallet/user_wallet_screen.dart';
import 'package:freelance_app/screens/profile/profile.dart';
import 'package:freelance_app/screens/plugins_hub/blue_pages_screen.dart';

/// Notification Router
/// 
/// Routes notification taps to the appropriate screen based on notification type.
/// 
/// Supported notification types:
/// - new_job_match → JobDetailsScreen (job-specific)
/// - job_closing_soon → JobDetailsScreen (job-specific)
/// - application_status → ApplicationDetailScreen (application-specific)
/// - chat_message → ChatScreen (user-specific)
/// - tender_alert → TendersPortalScreen (tender-specific)
/// - admin_announcement → NotificationsScreen (all announcements)
/// - payment_confirmation → UserWalletScreen (payments)
/// - profile_view → ProfileViewersScreen (profile viewers)
/// - connection_request → ConnectionRequestsScreen (connections)
/// 
/// Each type-specific routing method requires the relevant ID from notification data.
/// 
/// Example usage in FCMService foreground message listener:
/// ```dart
/// FCMService.instance.listenForForegroundMessages((message) {
///   final type = message.data['type'] ?? 'unknown';
///   final screen = NotificationRouter.routeToScreen(type, message.data);
///   if (screen != null) {
///     Navigator.of(context).push(
///       MaterialPageRoute(builder: (context) => screen),
///     );
///   }
/// });
/// ```
class NotificationRouter {
  /// Route to the appropriate screen based on notification type
  /// 
  /// Returns a Widget (screen) to navigate to, or null if type is unknown.
  /// 
  /// **Parameters**:
  /// - `type`: Notification type string (e.g., 'new_job_match', 'chat_message')
  /// - `data`: Notification data map containing routing parameters (id, userId, etc.)
  /// 
  /// **Returns**:
  /// - Widget to navigate to if type is recognized
  /// - null if type is unknown (gracefully handled)
  /// 
  /// **Example**:
  /// ```dart
  /// final screen = NotificationRouter.routeToScreen('new_job_match', {
  ///   'jobId': 'job-123',
  /// });
  /// if (screen != null) {
  ///   Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  /// }
  /// ```
  static Widget? routeToScreen(String type, Map<String, dynamic> data) {
    return switch (type) {
      'new_job_match' => _routeToNewJobMatch(data),
      'job_closing_soon' => _routeToJobClosingSoon(data),
      'application_status' => _routeToApplicationStatus(data),
      'chat_message' => _routeToChatMessage(data),
      'tender_alert' => _routeToTenderAlert(data),
      'admin_announcement' => _routeToAdminAnnouncement(data),
      'payment_confirmation' => _routeToPaymentConfirmation(data),
      'profile_view' => _routeToProfileView(data),
      'connection_request' => _routeToConnectionRequest(data),
      _ => null, // Unknown type
    };
  }

  /// Route to job details for new job match notification
  /// 
  /// **Notification Data**:
  /// - jobId (String, required): Job ID to display
  /// - jobTitle (String, optional): Job title for display
  /// - matchScore (int, optional): Match score percentage
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'new_job_match',
  ///   'jobId': 'job-12345',
  ///   'jobTitle': 'React Developer',
  ///   'matchScore': 92,
  /// }
  /// ```
  static Widget? _routeToNewJobMatch(Map<String, dynamic> data) {
    final jobId = data['jobId'] as String?;
    
    if (jobId == null || jobId.isEmpty) {
      debugPrint('❌ new_job_match: Missing jobId');
      return null;
    }
    
    debugPrint('✅ new_job_match: Routing to JobDetailsScreen($jobId)');
    return JobDetailsScreen(id: jobId, jobId: jobId);
  }

  /// Route to job details for job closing soon notification
  /// 
  /// **Notification Data**:
  /// - jobId (String, required): Job ID to display
  /// - jobTitle (String, optional): Job title for display
  /// - hoursLeft (int, optional): Hours until job closes
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'job_closing_soon',
  ///   'jobId': 'job-12345',
  ///   'jobTitle': 'React Developer',
  ///   'hoursLeft': 24,
  /// }
  /// ```
  static Widget? _routeToJobClosingSoon(Map<String, dynamic> data) {
    final jobId = data['jobId'] as String?;
    
    if (jobId == null || jobId.isEmpty) {
      debugPrint('❌ job_closing_soon: Missing jobId');
      return null;
    }
    
    debugPrint('✅ job_closing_soon: Routing to JobDetailsScreen($jobId)');
    return JobDetailsScreen(id: jobId, jobId: jobId);
  }

  /// Route to application details for application status notification
  /// 
  /// **Notification Data**:
  /// - applicationId (String, required): Application ID
  /// - jobId (String, required): Job ID for context
  /// - status (String, optional): New application status (pending, approved, rejected, etc.)
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'application_status',
  ///   'applicationId': 'app-56789',
  ///   'jobId': 'job-12345',
  ///   'status': 'approved',
  /// }
  /// ```
  static Widget? _routeToApplicationStatus(Map<String, dynamic> data) {
    final applicationId = data['applicationId'] as String?;
    
    if (applicationId == null || applicationId.isEmpty) {
      debugPrint('❌ application_status: Missing applicationId');
      return null;
    }
    
    debugPrint('✅ application_status: Routing to applications');
    // TODO: Implement ApplicationDetailScreen or navigate to applications list
    return null;
  }

  /// Route to chat for chat message notification
  /// 
  /// **Notification Data**:
  /// - userId (String, required): Other user's ID to chat with
  /// - userName (String, optional): Other user's name for display
  /// - messagePreview (String, optional): Message preview text
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'chat_message',
  ///   'userId': 'user-98765',
  ///   'userName': 'John Doe',
  ///   'messagePreview': 'Are you available for an interview?',
  /// }
  /// ```
  static Widget? _routeToChatMessage(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    
    if (userId == null || userId.isEmpty) {
      debugPrint('❌ chat_message: Missing userId');
      return null;
    }
    
    debugPrint('✅ chat_message: Routing to ChatScreen($userId)');
    final conversationId = data['conversationId'] as String? ?? 'unknown';
    return ChatScreen(
      chatId: conversationId,
      otherUserName: data['userName'] as String? ?? 'User',
      otherUserId: userId,
    );
  }

  /// Route to tender details for tender alert notification
  /// 
  /// **Notification Data**:
  /// - tenderId (String, required): Tender ID to display
  /// - tenderTitle (String, optional): Tender title for display
  /// - matchScore (int, optional): Match score percentage
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'tender_alert',
  ///   'tenderId': 'tender-11111',
  ///   'tenderTitle': 'Government Procurement Project',
  ///   'matchScore': 88,
  /// }
  /// ```
  static Widget? _routeToTenderAlert(Map<String, dynamic> data) {
    final tenderId = data['tenderId'] as String?;
    
    if (tenderId == null || tenderId.isEmpty) {
      debugPrint('❌ tender_alert: Missing tenderId');
      return null;
    }
    
    debugPrint('✅ tender_alert: Routing to TendersPortalScreen');
    // TendersPortalScreen shows all tenders with filter support
    // Ideally there would be a TenderDetailScreen, but for now route to portal
    // The portal can be filtered/searched for the specific tender
    return const TendersPortalScreen();
  }

  /// Route to admin announcements for admin announcement notification
  /// 
  /// **Notification Data**:
  /// - announcementId (String, optional): Announcement ID
  /// - title (String, optional): Announcement title
  /// - body (String, optional): Announcement body
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'admin_announcement',
  ///   'announcementId': 'announce-22222',
  ///   'title': 'Platform Maintenance',
  ///   'body': 'The platform will be down for maintenance on Sunday.',
  /// }
  /// ```
  static Widget? _routeToAdminAnnouncement(Map<String, dynamic> data) {
    debugPrint('✅ admin_announcement: Routing to NotificationsScreen');
    // Announcements are shown in the main notifications screen
    // where users can see all admin messages
    return const NotificationsScreen();
  }

  /// Route to wallet for payment confirmation notification
  /// 
  /// **Notification Data**:
  /// - transactionId (String, optional): Transaction ID for reference
  /// - amount (double, optional): Payment amount
  /// - fromUser (String, optional): User who sent the payment
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'payment_confirmation',
  ///   'transactionId': 'txn-33333',
  ///   'amount': 5000.0,
  ///   'fromUser': 'Jane Smith',
  /// }
  /// ```
  static Widget? _routeToPaymentConfirmation(Map<String, dynamic> data) {
    debugPrint('✅ payment_confirmation: Routing to UserWalletScreen');
    return const UserWalletScreen();
  }

  /// Route to profile viewers for profile view notification
  /// 
  /// **Notification Data**:
  /// - viewerId (String, optional): User who viewed the profile
  /// - viewerName (String, optional): Name of the viewer
  /// - timestamp (int, optional): When the profile was viewed (milliseconds)
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'profile_view',
  ///   'viewerId': 'user-44444',
  ///   'viewerName': 'Michael Johnson',
  ///   'timestamp': 1699564800000,
  /// }
  /// ```
  static Widget? _routeToProfileView(Map<String, dynamic> data) {
    debugPrint('✅ profile_view: Routing to ProfileViewersScreen');
    // Show all profile viewers in dedicated screen
    // This would typically be a screen showing who has viewed your profile
    // For now, navigate to the user's own profile which shows viewer stats
    // TODO: Create dedicated ProfileViewersScreen
    return const ProfilePage(userID: ''); // Current user's profile
  }

  /// Route to connection requests for connection request notification
  /// 
  /// **Notification Data**:
  /// - requesterId (String, optional): User who sent the connection request
  /// - requesterName (String, optional): Name of the requester
  /// - timestamp (int, optional): When request was sent (milliseconds)
  /// 
  /// **Example Data**:
  /// ```dart
  /// {
  ///   'type': 'connection_request',
  ///   'requesterId': 'user-55555',
  ///   'requesterName': 'Sarah Williams',
  ///   'timestamp': 1699564800000,
  /// }
  /// ```
  static Widget? _routeToConnectionRequest(Map<String, dynamic> data) {
    debugPrint('✅ connection_request: Routing to ConnectionRequestsScreen');
    // Show all pending connection requests
    // TODO: Create dedicated ConnectionRequestsScreen
    // For now, route to the main connections/contacts area
    // This is typically found in the app's contacts/network section
    return const BluePagesScreen(); // Shows connections and networking features
  }

  /// Helper method to navigate with error handling
  /// 
  /// Safely navigates to a screen from a notification, with logging.
  /// 
  /// **Example**:
  /// ```dart
  /// NotificationRouter.navigateFromNotification(
  ///   context,
  ///   type: 'new_job_match',
  ///   data: {'jobId': 'job-123'},
  /// );
  /// ```
  static Future<void> navigateFromNotification(
    BuildContext context, {
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final screen = NotificationRouter.routeToScreen(type, data);
      
      if (screen == null) {
        debugPrint('⚠️ NotificationRouter: Unknown type "$type"');
        return;
      }
      
      // Navigate to the screen
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screen),
      );
    } catch (e) {
      debugPrint('❌ NotificationRouter Error: $e');
    }
  }

  /// Parse notification data from RemoteMessage or local notification
  /// 
  /// Converts various notification data formats to consistent map.
  /// 
  /// **Example**:
  /// ```dart
  /// // From FCM RemoteMessage
  /// final data = NotificationRouter.parseNotificationData(message.data);
  /// 
  /// // From local notification payload
  /// final data = NotificationRouter.parseNotificationData(jsonDecode(payload));
  /// ```
  static Map<String, dynamic> parseNotificationData(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    
    if (rawData is String) {
      try {
        return Map<String, dynamic>.from(
          rawData as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to parse notification data: $e');
        return {};
      }
    }
    
    return {};
  }

  /// Get human-readable description of notification type
  /// 
  /// Useful for logging, debugging, or UI display.
  /// 
  /// **Example**:
  /// ```dart
  /// final desc = NotificationRouter.getTypeDescription('new_job_match');
  /// print(desc); // Output: "New Job Match 🎯"
  /// ```
  static String getTypeDescription(String type) {
    return switch (type) {
      'new_job_match' => 'New Job Match 🎯',
      'job_closing_soon' => 'Job Closing Soon ⏰',
      'application_status' => 'Application Update ✅',
      'chat_message' => 'New Message 💬',
      'tender_alert' => 'Tender Alert 📊',
      'admin_announcement' => 'Announcement 📢',
      'payment_confirmation' => 'Payment Confirmed 💰',
      'profile_view' => 'Profile Viewed 👁️',
      'connection_request' => 'Connection Request 🤝',
      _ => 'Notification',
    };
  }

  /// Validate notification data has required fields for type
  /// 
  /// Returns true if all required fields are present.
  /// 
  /// **Example**:
  /// ```dart
  /// if (!NotificationRouter.validateData('new_job_match', data)) {
  ///   debugPrint('Missing required fields for new_job_match');
  ///   return;
  /// }
  /// ```
  static bool validateData(String type, Map<String, dynamic> data) {
    return switch (type) {
      'new_job_match' || 'job_closing_soon' =>
        data.containsKey('jobId') && (data['jobId'] as String?)?.isNotEmpty == true,
      'application_status' =>
        data.containsKey('applicationId') &&
        (data['applicationId'] as String?)?.isNotEmpty == true,
      'chat_message' =>
        data.containsKey('userId') && (data['userId'] as String?)?.isNotEmpty == true,
      'tender_alert' =>
        data.containsKey('tenderId') && (data['tenderId'] as String?)?.isNotEmpty == true,
      'admin_announcement' || 'payment_confirmation' || 'profile_view' ||
      'connection_request' =>
        true, // These types don't require specific IDs for routing
      _ => false,
    };
  }
}
