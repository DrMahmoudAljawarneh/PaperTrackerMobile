import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/models/notification_model.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseDatabase mockDb;
  late NotificationRepository repository;

  setUp(() {
    mockDb = MockFirebaseDatabase();
    repository = NotificationRepository(db: mockDb);
  });

  group('NotificationRepository', () {
    test('getNotifications returns stream of notifications', () async {
      final notifRef = MockDatabaseReference();
      final notifQuery = MockDatabaseReference();

      when(() => mockDb.ref('notifications/uid1')).thenReturn(notifRef);
      when(() => notifRef.orderByChild('createdAt')).thenReturn(notifQuery);

      final now = DateTime.now();
      final event = MockDatabaseEvent();
      final snapshot = MockDataSnapshot();
      when(() => event.snapshot).thenReturn(snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn({
        'notif1': {
          'recipientId': 'uid1',
          'senderId': 'uid2',
          'senderName': 'User 2',
          'title': 'Test Notification',
          'message': 'Test message',
          'type': 'commentAdded',
          'relatedPaperId': 'paper1',
          'isRead': false,
          'createdAt': now.toIso8601String(),
        },
      });

      when(() => notifQuery.onValue).thenAnswer((_) => Stream.value(event));

      final notifications = await repository.getNotifications('uid1').first;

      expect(notifications.length, 1);
      expect(notifications.first.title, 'Test Notification');
    });

    test('getUnreadCount returns stream of counts', () async {
      final notifRef = MockDatabaseReference();
      final notifQuery = MockDatabaseReference();

      when(() => mockDb.ref('notifications/uid1')).thenReturn(notifRef);
      when(() => notifRef.orderByChild('createdAt')).thenReturn(notifQuery);

      final now = DateTime.now();
      final event = MockDatabaseEvent();
      final snapshot = MockDataSnapshot();
      when(() => event.snapshot).thenReturn(snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn({
        'notif1': {
          'recipientId': 'uid1',
          'senderId': 'uid2',
          'senderName': 'User 2',
          'title': 'Read',
          'message': 'Read notification',
          'type': 'commentAdded',
          'relatedPaperId': 'paper1',
          'isRead': true,
          'createdAt': now.toIso8601String(),
        },
        'notif2': {
          'recipientId': 'uid1',
          'senderId': 'uid2',
          'senderName': 'User 2',
          'title': 'Unread',
          'message': 'Unread notification',
          'type': 'taskAssigned',
          'relatedPaperId': 'paper1',
          'isRead': false,
          'createdAt': now.toIso8601String(),
        },
      });

      when(() => notifQuery.onValue).thenAnswer((_) => Stream.value(event));

      final count = await repository.getUnreadCount('uid1').first;

      expect(count, 1);
    });

    test('pushNotification adds a notification', () async {
      final notifRef = MockDatabaseReference();
      final newRef = MockDatabaseReference();

      when(() => mockDb.ref('notifications/uid1')).thenReturn(notifRef);
      when(() => notifRef.push()).thenReturn(newRef);
      when(() => newRef.set(any())).thenAnswer((_) async {});

      final notification = NotificationModel(
        id: '',
        recipientId: 'uid1',
        senderId: 'uid2',
        title: 'Test',
        message: 'Test message',
        type: NotificationType.commentAdded,
        createdAt: DateTime.now(),
      );

      await expectLater(
        repository.pushNotification(notification),
        completes,
      );
    });

    test('markAsRead marks as read', () async {
      final childRef = MockDatabaseReference();

      when(() => mockDb.ref('notifications/uid1/notif1')).thenReturn(childRef);
      when(() => childRef.update(any())).thenAnswer((_) async {});

      await expectLater(
        repository.markAsRead('uid1', 'notif1'),
        completes,
      );
    });

    test('deleteNotification deletes', () async {
      final notifRef = MockDatabaseReference();

      when(() => mockDb.ref('notifications/uid1/notif1')).thenReturn(notifRef);
      when(() => notifRef.remove()).thenAnswer((_) async {});

      await expectLater(
        repository.deleteNotification('uid1', 'notif1'),
        completes,
      );
    });

    test('clearAll clears all', () async {
      final notifRef = MockDatabaseReference();

      when(() => mockDb.ref('notifications/uid1')).thenReturn(notifRef);
      when(() => notifRef.remove()).thenAnswer((_) async {});

      await expectLater(
        repository.clearAll('uid1'),
        completes,
      );
    });
  });
}
