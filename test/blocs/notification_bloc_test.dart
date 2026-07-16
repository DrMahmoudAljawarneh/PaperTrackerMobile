import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/notification/notification_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_event.dart';
import 'package:paper_tracker/blocs/notification/notification_state.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late NotificationRepository notificationRepository;
  late NotificationService notificationService;
  late NotificationBloc notificationBloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notificationRepository = MockNotificationRepository();
    notificationService = MockNotificationService();
    // Default: any showNotification call returns a void future
    when(
      () => notificationService.showNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    notificationBloc = NotificationBloc(
      notificationRepository: notificationRepository,
      notificationService: notificationService,
    );
  });

  tearDown(() {
    notificationBloc.close();
  });

  group('NotificationBloc', () {
    test('initial state is NotificationInitial', () {
      expect(notificationBloc.state, isA<NotificationInitial>());
    });

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationLoading, NotificationsLoaded] on load',
      build: () {
        when(() => notificationRepository.getNotifications(any()))
            .thenAnswer((_) => Stream.value([]));
        return notificationBloc;
      },
      act: (bloc) => bloc.add(NotificationsLoadRequested('uid1')),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationsLoaded>(),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'correctly computes unread count',
      build: () {
        final now = DateTime.now();
        final notifications = [
          NotificationModel(
            id: 'n1',
            recipientId: 'uid1',
            senderId: 'uid2',
            senderName: 'Bob',
            title: 'Read',
            message: 'Already read',
            type: NotificationType.commentAdded,
            relatedPaperId: 'p1',
            isRead: true,
            createdAt: now,
          ),
          NotificationModel(
            id: 'n2',
            recipientId: 'uid1',
            senderId: 'uid2',
            senderName: 'Bob',
            title: 'Unread',
            message: 'Not read yet',
            type: NotificationType.collaboratorAdded,
            relatedPaperId: 'p1',
            isRead: false,
            createdAt: now,
          ),
        ];
        when(() => notificationRepository.getNotifications(any()))
            .thenAnswer((_) => Stream.value(notifications));
        return notificationBloc;
      },
      act: (bloc) => bloc.add(NotificationsLoadRequested('uid1')),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationsLoaded>().having(
          (s) => s.unreadCount,
          'unreadCount',
          1,
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'fires local notification for new unread items',
      build: () {
        final now = DateTime.now();
        final notifications = [
          NotificationModel(
            id: 'n1',
            recipientId: 'uid1',
            senderId: 'uid2',
            senderName: 'Bob',
            title: 'New',
            message: 'Fresh notification',
            type: NotificationType.taskAssigned,
            relatedPaperId: 'p1',
            isRead: false,
            createdAt: now,
          ),
        ];
        when(() => notificationRepository.getNotifications(any()))
            .thenAnswer((_) => Stream.value(notifications));
        return notificationBloc;
      },
      act: (bloc) => bloc.add(NotificationsLoadRequested('uid1')),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationsLoaded>(),
      ],
      verify: (bloc) {
        verify(
          () => notificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );
  });
}
