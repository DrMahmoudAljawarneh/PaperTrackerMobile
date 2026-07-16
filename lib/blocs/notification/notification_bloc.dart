import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_event.dart';
import 'package:paper_tracker/blocs/notification/notification_state.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/services/notification_service.dart';
import 'package:paper_tracker/utils/notification_prefs.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  final NotificationService _notificationService;
  StreamSubscription<List<NotificationModel>>? _subscription;

  final Set<String> _shownNotificationIds = {};
  static const int _maxShownIds = 200;

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
    on<_NotificationLoadError>(_onLoadError);
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
        add(_NotificationLoadError(error.toString()));
      },
    );
  }

  Future<void> _onUpdated(
    NotificationsUpdated event,
    Emitter<NotificationState> emit,
  ) async {
    final notifications = event.notifications.cast<NotificationModel>();
    final prefs = await NotificationPrefs.getAll();
    final filtered =
        notifications.where((n) => prefs[n.type] ?? true).toList();
    final unreadCount = filtered.where((n) => !n.isRead).length;

    final recent = filtered.length > 20
        ? filtered.sublist(0, 20)
        : filtered;
    for (final n in recent) {
      if (!n.isRead && !_shownNotificationIds.contains(n.id)) {
        _shownNotificationIds.add(n.id);
        if (_shownNotificationIds.length > _maxShownIds) {
          final excess = _shownNotificationIds.length - _maxShownIds;
          final toRemove = _shownNotificationIds.take(excess).toList();
          toRemove.forEach(_shownNotificationIds.remove);
        }
        _notificationService.showNotification(
          id: n.id.hashCode,
          title: '${n.type.icon} ${n.title}',
          body: n.message,
          payload: n.relatedPaperId,
        );
      }
    }

    emit(NotificationsLoaded(
      notifications: filtered,
      unreadCount: unreadCount,
    ));
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAsRead(
          event.userId, event.notificationId);
    } catch (_) {}
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAllAsRead(event.userId);
    } catch (_) {}
  }

  Future<void> _onDelete(
    NotificationDelete event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteNotification(
          event.userId, event.notificationId);
    } catch (_) {}
  }

  Future<void> _onClearAll(
    NotificationClearAll event,
    Emitter<NotificationState> emit,
  ) async {
    _shownNotificationIds.clear();
    try {
      await _notificationRepository.clearAll(event.userId);
    } catch (_) {}
  }

  void _onLoadError(
    _NotificationLoadError event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationError(event.message));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class _NotificationLoadError extends NotificationEvent {
  final String message;
  const _NotificationLoadError(this.message);

  @override
  List<Object?> get props => [message];
}
