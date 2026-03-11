import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/notification/notification_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_event.dart';
import 'package:paper_tracker/blocs/notification/notification_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton.icon(
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Read All'),
                  onPressed: () {
                    context
                        .read<NotificationBloc>()
                        .add(NotificationMarkAllAsRead(userId));
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                context
                    .read<NotificationBloc>()
                    .add(NotificationClearAll(userId));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 18, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }
            return _buildNotificationList(context, state.notifications, userId);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll be notified about comments,\ntask assignments, and collaborations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
      BuildContext context, List<NotificationModel> notifications, String userId) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => Divider(
        color: AppTheme.dividerColor.withOpacity(0.3),
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () {
            // Mark as read
            if (!notification.isRead) {
              context.read<NotificationBloc>().add(
                    NotificationMarkAsRead(
                      userId: userId,
                      notificationId: notification.id,
                    ),
                  );
            }
            // Navigate to paper detail if there's a related paper
            if (notification.relatedPaperId.isNotEmpty) {
              context.push('/papers/${notification.relatedPaperId}');
            }
          },
          onDismissed: () {
            context.read<NotificationBloc>().add(
                  NotificationDelete(
                    userId: userId,
                    notificationId: notification.id,
                  ),
                );
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  Color _typeColor() {
    switch (notification.type) {
      case NotificationType.collaboratorAdded:
        return AppTheme.accentColor;
      case NotificationType.commentAdded:
        return AppTheme.primaryColor;
      case NotificationType.taskAssigned:
        return AppTheme.warningColor;
      case NotificationType.taskCompleted:
        return AppTheme.successColor;
      case NotificationType.statusChanged:
        return const Color(0xFFF97316);
      case NotificationType.paperCreated:
        return AppTheme.successColor;
      case NotificationType.paperModified:
        return AppTheme.primaryColor;
    }
  }

  IconData _typeIcon() {
    switch (notification.type) {
      case NotificationType.collaboratorAdded:
        return Icons.person_add_rounded;
      case NotificationType.commentAdded:
        return Icons.chat_bubble_rounded;
      case NotificationType.taskAssigned:
        return Icons.assignment_ind_rounded;
      case NotificationType.taskCompleted:
        return Icons.task_alt_rounded;
      case NotificationType.statusChanged:
        return Icons.swap_horiz_rounded;
      case NotificationType.paperCreated:
        return Icons.note_add_rounded;
      case NotificationType.paperModified:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor.withOpacity(0.2),
        child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
      ),
      onDismissed: (_) => onDismissed(),
      child: Material(
        color: notification.isRead
            ? Colors.transparent
            : AppTheme.primaryColor.withOpacity(0.04),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (notification.senderName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'by ${notification.senderName}',
                          style: TextStyle(
                            color: color.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Unread dot
                if (!notification.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dateTime);
  }
}
