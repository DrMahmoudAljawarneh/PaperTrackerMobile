import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/notification/notification_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_event.dart';
import 'package:paper_tracker/blocs/notification/notification_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/widgets/shimmer_loading.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:paper_tracker/services/notification_service.dart';
import 'package:paper_tracker/utils/time_utils.dart';

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
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Notifications'),
                    content: const Text(
                        'Are you sure you want to clear all notifications? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context
                              .read<NotificationBloc>()
                              .add(NotificationClearAll(userId));
                        },
                        child: Text(
                          'Clear All',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    const Text('Clear All'),
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
            return _buildNotificationsShimmer();
          }

          final notifications = state is NotificationsLoaded ? state.notifications : <NotificationModel>[];

          return Column(
            children: [
              const _WebPermissionBanner(),
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState(context)
                    : _buildNotificationList(context, notifications, userId),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified about comments,\ntask assignments, and collaborations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
      BuildContext context, List<NotificationModel> notifications, String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<NotificationBloc>()
            .add(NotificationsLoadRequested(userId));
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => Divider(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildNotificationsShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon leading shimmer
            ShimmerLoading(width: 44, height: 44, borderRadius: 12),
            SizedBox(width: 12),
            // Message lines shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLoading(width: 120, height: 16, borderRadius: 4),
                      ShimmerLoading(width: 50, height: 14, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 8),
                  ShimmerLoading(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 4),
                  ShimmerLoading(width: 200, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
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
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
        child: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error),
      ),
      onDismissed: (_) => onDismissed(),
      child: Material(
        color: notification.isRead
            ? Colors.transparent
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
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
                    color: color.withValues(alpha: 0.12),
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
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
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
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                      ),
                      if (notification.senderName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'by ${notification.senderName}',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.8),
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
                      color: Theme.of(context).colorScheme.primary,
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

  String _formatTimeAgo(DateTime dateTime) => timeAgo(dateTime, short: true);
}

class _WebPermissionBanner extends StatefulWidget {
  const _WebPermissionBanner();

  @override
  State<_WebPermissionBanner> createState() => _WebPermissionBannerState();
}

class _WebPermissionBannerState extends State<_WebPermissionBanner> {
  String _permission = 'unsupported';
  bool _supported = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  void _checkPermission() {
    final ns = NotificationService();
    setState(() {
      _supported = ns.isWebNotificationSupported;
      _permission = ns.webNotificationPermission;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_supported || _permission == 'granted') {
      return const SizedBox.shrink();
    }

    final isDenied = _permission == 'denied';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDenied
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDenied
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDenied
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                color: isDenied ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDenied
                      ? 'Notifications Blocked'
                      : 'Enable Web Notifications',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isDenied
                ? 'Web notifications are blocked in your browser settings. Please enable them in your browser URL bar or site settings to get real-time updates.'
                : 'Get browser push notifications when collaborators edit papers, assign you tasks, or leave comments.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
          if (!isDenied) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService().initialize();
                  _checkPermission();
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text('Enable Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


