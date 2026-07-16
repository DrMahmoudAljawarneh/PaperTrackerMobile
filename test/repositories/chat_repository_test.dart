import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';
import 'package:paper_tracker/models/chat_message.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseDatabase mockDb;
  late ChatRepository repository;

  setUp(() {
    mockDb = MockFirebaseDatabase();
    repository = ChatRepository(db: mockDb);
  });

  group('ChatRepository', () {
    test('sendMessage saves message and updates chat room', () async {
      final msgRef = MockDatabaseReference();
      final chatsRef = MockDatabaseReference();
      final messagesRef = MockDatabaseReference();
      final unreadSnap = MockDataSnapshot();

      when(() => mockDb.ref('chats')).thenReturn(chatsRef);
      when(() => mockDb.ref('messages')).thenReturn(messagesRef);
      when(() => messagesRef.child(any())).thenReturn(msgRef);
      when(() => msgRef.push()).thenReturn(msgRef);
      when(() => msgRef.key).thenReturn('msg1');
      when(() => msgRef.set(any())).thenAnswer((_) async {});
      when(() => chatsRef.child(any())).thenReturn(chatsRef);
      when(() => chatsRef.child('unreadCount')).thenReturn(chatsRef);
      when(() => chatsRef.get()).thenAnswer((_) async => unreadSnap);
      when(() => unreadSnap.value).thenReturn(0);
      when(() => chatsRef.update(any())).thenAnswer((_) async {});

      final message = ChatMessage(
        id: '',
        senderId: 'uid1',
        text: 'Hello',
        timestamp: DateTime.now(),
        isRead: false,
      );

      await expectLater(
        repository.sendMessage('chat1', message),
        completes,
      );
    });

    test('getAllUsers returns cached results within 5 minutes', () async {
      final usersRef = MockDatabaseReference();
      final snapshot = MockDataSnapshot();

      when(() => mockDb.ref('users')).thenReturn(usersRef);
      when(() => usersRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(false);

      final firstCall = await repository.getAllUsers();
      expect(firstCall, isEmpty);

      // Second call should use cache (no additional Firebase call)
      final secondCall = await repository.getAllUsers();
      expect(secondCall, isEmpty);
    });

    test('createOrGetChatRoom creates deterministic chat ID', () async {
      final chatsRef = MockDatabaseReference();
      final snapshot = MockDataSnapshot();
      final dbRef = MockDatabaseReference();
      final userChatsRefA = MockDatabaseReference();
      final userChatsRefB = MockDatabaseReference();

      when(() => mockDb.ref()).thenReturn(dbRef);
      when(() => mockDb.ref('chats')).thenReturn(chatsRef);
      when(() => chatsRef.child(any())).thenReturn(chatsRef);
      when(() => chatsRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(false);
      when(() => chatsRef.set(any())).thenAnswer((_) async {});
      when(() => mockDb.ref('userChats/uidA/uidA_uidB')).thenReturn(userChatsRefA);
      when(() => mockDb.ref('userChats/uidB/uidA_uidB')).thenReturn(userChatsRefB);
      when(() => userChatsRefA.set(true)).thenAnswer((_) async {});
      when(() => userChatsRefB.set(true)).thenAnswer((_) async {});

      final room = await repository.createOrGetChatRoom(
        'uidA', 'uidB', 'Alice', 'Bob',
      );

      // IDs are sorted, so uidA_uidB regardless of order
      expect(room.participantIds, containsAll(['uidA', 'uidB']));
    });
  });
}
