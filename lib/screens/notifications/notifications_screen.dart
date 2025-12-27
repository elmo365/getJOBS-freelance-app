import 'package:flutter/material.dart';
import 'package:freelance_app/models/notification_model.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/screens/chat/chat_list_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  final _authService = FirebaseAuthService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: LoadingWidget(message: 'Loading notifications...')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'notifications',
      child: Scaffold(
      appBar: AppAppBar(
        title: 'Notifications',
        variant: AppBarVariant.primary,
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(_userId!),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count > 0) {
                return MicroInteractions.scaleOnTap(
                  onTap: () => _markAllAsRead(),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: AppDesignSystem.paddingS,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                      borderRadius: AppDesignSystem.borderRadiusM,
                    ),
                    child: Badge(
                      label: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Icon(
                        Icons.mark_email_read,
                        color: colorScheme.tertiary,
                        size: 22,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget(message: 'Loading notifications...'));
          }

          if (snapshot.hasError) {
            return Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Error loading notifications',
                message: snapshot.error.toString(),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                message: 'You\'ll see important updates here when you receive job applications, interview invitations, and more.',
              ),
            );
          }

          return ListView.builder(
            padding: AppDesignSystem.paddingM,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onDismiss: () => _deleteNotification(notification.id),
              );
            },
          );
        },
      ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Navigate based on type
    if (notification.actionUrl != null) {
      // Handle deep linking
      Navigator.pushNamed(context, notification.actionUrl!);
    } else {
      // Default navigation based on type
      switch (notification.type) {
        case NotificationType.message:
          // Navigate to chat inbox (message list)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatListScreen(),
            ),
          );
          break;
        case NotificationType.jobApplication:
        case NotificationType.applicationStatus:
          // Navigate to applications screen
          break;
        case NotificationType.interviewScheduled:
          // Navigate to interviews screen
          break;
        case NotificationType.jobMatch:
          // Navigate to job matches screen
          break;
        default:
          break;
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_userId != null) {
      await _notificationService.markAllAsRead(_userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    await _notificationService.deleteNotification(id);
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type, colorScheme);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorScheme.error,
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      child: AppCard(
        variant: notification.isRead 
            ? SurfaceVariant.standard 
            : SurfaceVariant.elevated,
        margin: const EdgeInsets.only(bottom: 16),
        backgroundColor: notification.isRead
            ? null
            : colorScheme.tertiaryContainer.withValues(alpha: 0.1),
        onTap: onTap,
        padding: AppDesignSystem.paddingM,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: notification.isRead 
                                ? FontWeight.w600 
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    timeago.format(notification.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case NotificationType.jobApplication:
        return '📝';
      case NotificationType.applicationStatus:
        return '📊';
      case NotificationType.interviewScheduled:
        return '📅';
      case NotificationType.interviewReminder:
        return '⏰';
      case NotificationType.jobApproval:
        return '✅';
      case NotificationType.companyApproval:
        return '🏢';
      case NotificationType.jobMatch:
        return '🎯';
      case NotificationType.candidateMatch:
        return '👤';
      case NotificationType.message:
        return '💬';
      default:
        return '🔔';
    }
  }

  Color _getNotificationColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.jobApplication:
      case NotificationType.applicationStatus:
        return colorScheme.tertiary;
      case NotificationType.interviewScheduled:
      case NotificationType.interviewReminder:
        return colorScheme.secondary;
      case NotificationType.jobApproval:
      case NotificationType.companyApproval:
        return colorScheme.primary;
      case NotificationType.jobMatch:
      case NotificationType.candidateMatch:
        return colorScheme.secondary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}

