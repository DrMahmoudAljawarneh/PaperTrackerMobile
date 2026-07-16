import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/notification_model.dart';

void main() {
  group('NotificationType', () {
    test('has 7 values', () {
      expect(NotificationType.values.length, 7);
    });

    test('each type has non-empty label and icon', () {
      for (final type in NotificationType.values) {
        expect(type.label, isNotEmpty);
        expect(type.icon, isNotEmpty);
      }
    });
  });

  group('NotificationModel', () {
    final now = DateTime.now();
    final notification = NotificationModel(
      id: 'notif1',
      recipientId: 'uid1',
      senderId: 'uid2',
      senderName: 'Bob',
      title: 'New Comment',
      message: 'Bob commented on your paper',
      type: NotificationType.commentAdded,
      relatedPaperId: 'paper1',
      isRead: false,
      createdAt: now,
    );

    test('toMap and fromMap round-trip', () {
      final map = notification.toMap();
      final restored = NotificationModel.fromMap('notif1', map);
      expect(restored.id, notification.id);
      expect(restored.title, notification.title);
      expect(restored.type, notification.type);
      expect(restored.isRead, false);
    });

    test('copyWith updates correctly', () {
      final read = notification.copyWith(isRead: true);
      expect(read.isRead, true);
    });

    test('equatable works', () {
      final same = notification.copyWith();
      expect(notification, same);
    });
  });
}
