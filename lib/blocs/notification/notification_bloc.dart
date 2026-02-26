import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_event.dart';
import 'package:paper_tracker/blocs/notification/notification_state.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/services/notification_service.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  final NotificationService _notificationService;
  StreamSubscription<List<NotificationModel>>? _subscription;

  /// Track IDs we've already shown local alerts for, so we don't re-fire
  /// on every stream update.
  final Set<String> _shownNotificationIds = {};

  NotificationBloc({
    required NotificationRepository notificationRepository,
    required NotificationService notificationService,
  })  : _notificationRepository = notificationRepository,
        _notificationService = notificationService,
        super(NotificationInitial()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationsUpdated>(_onUpdated);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationDelete>(_onDelete);
    on<NotificationClearAll>(_onClearAll);
  }

  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    _subscription?.cancel();
    _subscription =
        _notificationRepository.getNotifications(event.userId).listen(
      (notifications) {
        add(NotificationsUpdated(notifications));
      },
      onError: (error) {
        add(const NotificationsUpdated([]));
      },
    );
  }

  void _onUpdated(
    NotificationsUpdated event,
    Emitter<NotificationState> emit,
  ) {
    final notifications = event.notifications.cast<NotificationModel>();
    final unreadCount = notifications.where((n) => !n.isRead).length;

    // Fire local OS notifications for any new unread items
    for (final n in notifications) {
      if (!n.isRead && !_shownNotificationIds.contains(n.id)) {
        _shownNotificationIds.add(n.id);
        _notificationService.showNotification(
          id: n.id.hashCode,
          title: '${n.type.icon} ${n.title}',
          body: n.message,
          payload: n.relatedPaperId,
        );
      }
    }

    emit(NotificationsLoaded(
      notifications: notifications,
      unreadCount: unreadCount,
    ));
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _notificationRepository.markAsRead(
        event.userId, event.notificationId);
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _notificationRepository.markAllAsRead(event.userId);
  }

  Future<void> _onDelete(
    NotificationDelete event,
    Emitter<NotificationState> emit,
  ) async {
    await _notificationRepository.deleteNotification(
        event.userId, event.notificationId);
  }

  Future<void> _onClearAll(
    NotificationClearAll event,
    Emitter<NotificationState> emit,
  ) async {
    _shownNotificationIds.clear();
    await _notificationRepository.clearAll(event.userId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
