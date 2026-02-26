import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationEvent {
  final String userId;

  const NotificationsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NotificationsUpdated extends NotificationEvent {
  final List<dynamic> notifications;

  const NotificationsUpdated(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class NotificationMarkAsRead extends NotificationEvent {
  final String userId;
  final String notificationId;

  const NotificationMarkAsRead({
    required this.userId,
    required this.notificationId,
  });

  @override
  List<Object?> get props => [userId, notificationId];
}

class NotificationMarkAllAsRead extends NotificationEvent {
  final String userId;

  const NotificationMarkAllAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NotificationDelete extends NotificationEvent {
  final String userId;
  final String notificationId;

  const NotificationDelete({
    required this.userId,
    required this.notificationId,
  });

  @override
  List<Object?> get props => [userId, notificationId];
}

class NotificationClearAll extends NotificationEvent {
  final String userId;

  const NotificationClearAll(this.userId);

  @override
  List<Object?> get props => [userId];
}
