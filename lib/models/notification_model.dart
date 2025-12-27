import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification Model for in-app and push notifications
class NotificationModel {
  final String id;
  final String userId; // Recipient user ID
  final String type; // 'application', 'interview', 'approval', 'message', 'job_match', etc.
  final String title;
  final String body;
  final Map<String, dynamic>? data; // Additional data (jobId, applicationId, etc.)
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl; // Deep link or screen to navigate to

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.actionUrl,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      actionUrl: map['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'actionUrl': actionUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

/// Notification Types
class NotificationType {
  static const String jobApplication = 'job_application';
  static const String applicationStatus = 'application_status';
  static const String applicationSubmitted = 'application_submitted';
  static const String applicationApproved = 'application_approved';
  static const String applicationRejected = 'application_rejected';
  static const String interviewScheduled = 'interview_scheduled';
  static const String interviewReminder = 'interview_reminder';
  static const String jobApproval = 'job_approval';
  static const String jobPendingApproval = 'job_pending_approval';
  static const String jobPosted = 'job_posted';
  static const String jobRejected = 'job_rejected';
  static const String companyApproval = 'company_approval';
  static const String companyRejected = 'company_rejected';
  static const String companyKycSubmitted = 'company_kyc_submitted';
  static const String jobMatch = 'job_match';
  static const String candidateMatch = 'candidate_match';
  static const String message = 'message';
  static const String system = 'system';
}

