import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:freelance_app/models/notification_model.dart';
import 'package:freelance_app/services/cache/firestore_cache_service.dart';
import 'package:freelance_app/services/notifications/notification_channel_setup.dart';

/// Comprehensive Notification Service
/// Handles both push notifications (FCM) and email notifications (Brevo)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    // Initialize notification channels (Android)
    await NotificationChannelSetup.initialize();

    // Request permission for notifications
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
      
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _saveFCMToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } else {
      debugPrint('❌ Notification permission denied');
    }
  }

  /// Save FCM token to user document
  Future<void> _saveFCMToken(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Save the current FCM token onto the currently authenticated user.
  /// Call this after login/sign-up so notifications work immediately.
  Future<void> syncTokenToCurrentUser() async {
    final token = _fcmToken ?? await _messaging.getToken();
    if (token == null) return;
    _fcmToken = token;
    await _saveFCMToken(token);
  }

  /// Handle foreground messages (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground notification received: ${message.notification?.title}');
    // You can show in-app notification here
  }

  /// Handle background messages (app opened from notification)
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('📬 Background notification opened: ${message.notification?.title}');
    // Navigate to relevant screen based on notification data
    final data = message.data;
    final type = data['type'] as String?;
    
    if (type == 'message') {
      // Navigation will be handled by the app's routing system
      // The data['chatId'] can be used to navigate to specific chat
      debugPrint('📬 Message notification - chatId: ${data['chatId']}');
    }
  }

  /// Send notification to user (both push and in-app)
  /// Now includes email sending via Brevo when sendEmail=true
  Future<bool> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? actionUrl,
    bool sendEmail = false,
    String? emailRecipient,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
        actionUrl: actionUrl,
      );
      
      // Write notification to Firestore (always do this)
      final notificationDoc = await _firestore
          .collection('notifications')
          .add(notification.toMap());
      
      debugPrint('✅ Notification created: ${notificationDoc.id}');
      
      // Send email if requested
      if (sendEmail) {
        await _sendEmailNotification(
          userId: userId,
          type: type,
          title: title,
          body: body,
          data: data,
          emailRecipient: emailRecipient,
        );
      }
      
      // Send FCM push notification if available
      await _sendFCMNotification(userId, type, data ?? {});
      
      return true;
    } catch (e) {
      debugPrint('❌ Notification write failed: $e');
      return false;
    }
  }

  /// Send FCM push notification via Cloud Messaging
  /// 
  /// Retrieves user's FCM token from Firestore, sends push notification with proper formatting.
  /// Uses NotificationPayloadBuilder for consistent device panel formatting across all types.
  /// 
  /// **Notification Types Supported**:
  /// - new_job_match: New matching job (80%+)
  /// - job_closing_soon: Job deadline reminder
  /// - application_status: Application reviewed
  /// - chat_message: New message from user
  /// - tender_alert: New tender match
  /// - admin_announcement: Platform announcement
  /// - payment_confirmation: Payment received
  /// - profile_view: Profile viewed
  /// - connection_request: Connection request
  /// 
  /// **Data Map Contents**:
  /// - type (String): Notification type identifier (from list above)
  /// - For job notifications: jobId, jobTitle, matchScore/hoursLeft
  /// - For chat: userId, userName, messagePreview
  /// - For payments: amount, fromUser, transactionId
  /// - And more depending on type (see NotificationRouter for mapping)
  Future<void> _sendFCMNotification(
    String userId,
    String type,
    Map<String, dynamic> data,
  ) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ No FCM token for user $userId, skipping push');
        return;
      }

      // Ensure data has the notification type
      data['type'] = type;

      // Send via Cloud Function (sendFCMNotification)
      // This function handles the actual FCM send on backend
      final callable = _functions.httpsCallable('sendFCMNotification');
      final result = await callable.call({
        'token': fcmToken,
        'type': type,
        'data': data,
      });

      final isSuccess = (result.data is Map) && (result.data['ok'] == true);
      if (isSuccess) {
        debugPrint('📱 FCM sent successfully to user $userId (type: $type)');
      } else {
        debugPrint('⚠️ FCM send returned non-ok status for user $userId');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ FCM function failed: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('⚠️ Error sending FCM notification: $e');
      // Don't throw - it's not critical if FCM fails, we still have in-app notifications
    }
  }

  /// Send email notification via Brevo
  /// Retrieves user email from cache (1h TTL), generates HTML template, and calls sendTransactionalEmail Cloud Function
  Future<void> _sendEmailNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? emailRecipient,
  }) async {
    try {
      // Get user email from cache first (1 hour TTL)
      String? userEmail = emailRecipient;
      if (userEmail == null || userEmail.isEmpty) {
        final cacheService = FirestoreCacheService();
        
        // Try cache first
        Map<String, dynamic>? cachedUser = cacheService.getCachedDoc(
          collection: 'users',
          docId: userId,
          ttl: Duration(hours: 1),
        );
        
        if (cachedUser != null) {
          userEmail = cachedUser['email'] as String?;
          debugPrint('✅ User email from cache for $userId');
        } else {
          // Cache miss, fetch from Firestore
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data();
          userEmail = userData?['email'] as String?;
          
          // Cache the user document
          if (userData != null) {
            cacheService.cacheDoc(
              collection: 'users',
              docId: userId,
              data: userData,
            );
          }
        }
      }

      if (userEmail == null || userEmail.isEmpty) {
        debugPrint('⚠️ No email found for user $userId, skipping email send');
        return;
      }

      // Generate email HTML template based on notification type
      final htmlContent = _generateEmailTemplate(
        type: type,
        title: title,
        body: body,
        data: data,
      );

      // Call sendTransactionalEmail Cloud Function
      final callable = _functions.httpsCallable('sendTransactionalEmail');
      final result = await callable.call({
        'toEmail': userEmail,
        'subject': title,
        'htmlContent': htmlContent,
        'textContent': body,
      });

      final isSuccess = (result.data is Map) && (result.data['ok'] == true);
      if (isSuccess) {
        debugPrint('📧 Email sent successfully to $userEmail for $type');
      } else {
        debugPrint('⚠️ Email send returned non-ok status for $userEmail');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Email function failed: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('❌ Error sending notification email: $e');
    }
  }

  /// Generate HTML email template based on notification type
  String _generateEmailTemplate({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    const baseStyle = '''
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
      .container { max-width: 600px; margin: 0 auto; padding: 20px; }
      .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
      .content { background: #fff; padding: 30px; border: 1px solid #e0e0e0; border-top: none; }
      .footer { background: #f5f5f5; padding: 20px; text-align: center; color: #666; font-size: 12px; border-radius: 0 0 8px 8px; }
      .button { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
      .alert { padding: 15px; border-radius: 6px; margin: 20px 0; }
      .alert-success { background: #d4edda; border-left: 4px solid #28a745; color: #155724; }
      .alert-info { background: #d1ecf1; border-left: 4px solid #17a2b8; color: #0c5460; }
    </style>
    ''';

    final contentHtml = switch (type) {
      'company_approval' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">🎉 Approved!</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com/dashboard" class="button">Go to Dashboard</a>
        </div>
      ''',
      'job_approval' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">✅ Job Approved!</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com/dashboard" class="button">View Job</a>
        </div>
      ''',
      'interview_scheduled' => '''
        <div class="alert alert-info">
          <h2 style="margin-top: 0;">📅 Interview Scheduled</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          ${data?['meetingLink'] != null ? '<p><strong>Meeting Link:</strong> <a href="${data!['meetingLink']}">Join Interview</a></p>' : ''}
          ${data?['location'] != null ? '<p><strong>Location:</strong> ${data!['location']}</p>' : ''}
          <a href="https://botsjobsconnect.com/interviews" class="button">View Details</a>
        </div>
      ''',
      'application_received' => '''
        <div class="alert alert-info">
          <h2 style="margin-top: 0;">📋 New Application</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com/applications" class="button">Review</a>
        </div>
      ''',
      'application_rejected' => '''
        <div class="alert alert-info">
          <h2 style="margin-top: 0;">📝 Application Update</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          ${data != null && data.containsKey('notes') && (data['notes'] as String?)?.isNotEmpty == true ? '<p><strong>Feedback:</strong> ${data['notes']}</p>' : ''}
          <p>Don't worry! Keep applying and improving your skills. We have many other opportunities available.</p>
          <a href="https://botsjobsconnect.com/search" class="button">View More Jobs</a>
        </div>
      ''',
      'tender_applied' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">✅ Tender Application Submitted</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <p>The tender owner will review your application and contact you if they wish to proceed.</p>
          <a href="https://botsjobsconnect.com/tenders" class="button">View Tender Status</a>
        </div>
      ''',
      'tender_application_received' => '''
        <div class="alert alert-info">
          <h2 style="margin-top: 0;">📬 New Tender Application</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com/tenders/applications" class="button">Review Application</a>
        </div>
      ''',
      'profile_updated' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">✅ Profile Updated</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com/profile" class="button">View Profile</a>
        </div>
      ''',
      'interview_scheduled_employer' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">✅ Interview Scheduled</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com/interviews" class="button">View Details</a>
        </div>
      ''',
      'email_changed_security' => '''
        <div class="alert" style="background: #fff3cd; border-left: 4px solid #ffc107; color: #856404;">
          <h2 style="margin-top: 0;">⚠️ Security Alert</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <p style="margin: 15px 0;"><strong>If you did not make this change, please <a href="https://botsjobsconnect.com/security">secure your account immediately</a>.</strong></p>
        </div>
      ''',      'wallet_credit' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">💰 Wallet Credited</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com/wallet" class="button">View Wallet</a>
        </div>
      ''',
      'company_welcome' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">🎉 Welcome!</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <p>Your company profile has been created. To start posting jobs, please complete the verification process:</p>
          <ol>
            <li>Update your company profile with all details</li>
            <li>Submit documents for verification</li>
            <li>Wait for admin approval (24-48 hours)</li>
          </ol>
          <a href="https://botsjobsconnect.com/profile" class="button">Complete Profile</a>
        </div>
      ''',
      'rating_requested' => '''
        <div class="alert alert-info">
          <h2 style="margin-top: 0;">⭐ Rate Your Experience</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <p>Your feedback helps us maintain a trusted community and helps the other party improve their service.</p>
          <a href="https://botsjobsconnect.com/ratings" class="button">Submit Rating</a>
        </div>
      ''',
      'rating_received' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">⭐ You Received a Rating!</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <p>This rating helps showcase your reputation and the quality of your work to future employers or job seekers.</p>
          <a href="https://botsjobsconnect.com/profile" class="button">View Your Ratings</a>
        </div>
      ''',
      'job_completed' => '''
        <div class="alert alert-success">
          <h2 style="margin-top: 0;">✅ Job Completed</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <p>All positions for this job have been filled successfully. Thank you for using BotsJobsConnect!</p>
          <a href="https://botsjobsconnect.com/dashboard" class="button">View Dashboard</a>
        </div>
      ''',
      _ => '''
        <div class="alert alert-info">
          <h2>📬 Notification</h2>
          <p><strong>$title</strong></p>
          <p>$body</p>
          <a href="https://botsjobsconnect.com" class="button">View in App</a>
        </div>
      ''',
    };

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      $baseStyle
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>BotsJobsConnect</h1>
          <p>Your professional job marketplace</p>
        </div>
        <div class="content">
          $contentHtml
        </div>
        <div class="footer">
          <p>© 2025 BotsJobsConnect. All rights reserved.</p>
          <p><a href="https://botsjobsconnect.com">Visit our website</a> | <a href="https://botsjobsconnect.com/settings">Manage notifications</a></p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != userId) {
      return Stream.value(const <NotificationModel>[]);
    }
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get unread count
  Stream<int> getUnreadCount(String userId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != userId) {
      return Stream.value(0);
    }
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != userId) {
      return;
    }
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background notification: ${message.notification?.title}');
}

