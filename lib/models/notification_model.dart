import 'package:equatable/equatable.dart';

enum NotificationType {
  collaboratorAdded,
  commentAdded,
  taskAssigned,
  taskCompleted,
  statusChanged;

  String get label {
    switch (this) {
      case NotificationType.collaboratorAdded:
        return 'Collaborator Added';
      case NotificationType.commentAdded:
        return 'New Comment';
      case NotificationType.taskAssigned:
        return 'Task Assigned';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.statusChanged:
        return 'Status Changed';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.collaboratorAdded:
        return '👥';
      case NotificationType.commentAdded:
        return '💬';
      case NotificationType.taskAssigned:
        return '📋';
      case NotificationType.taskCompleted:
        return '✅';
      case NotificationType.statusChanged:
        return '🔄';
    }
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String title;
  final String message;
  final NotificationType type;
  final String relatedPaperId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    this.senderName = '',
    required this.title,
    required this.message,
    required this.type,
    this.relatedPaperId = '',
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? senderName,
    String? title,
    String? message,
    NotificationType? type,
    String? relatedPaperId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedPaperId: relatedPaperId ?? this.relatedPaperId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'title': title,
      'message': message,
      'type': type.name,
      'relatedPaperId': relatedPaperId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.commentAdded,
      ),
      relatedPaperId: map['relatedPaperId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        recipientId,
        senderId,
        senderName,
        title,
        message,
        type,
        relatedPaperId,
        isRead,
        createdAt,
      ];
}
