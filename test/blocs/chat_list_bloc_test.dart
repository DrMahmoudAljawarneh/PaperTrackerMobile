import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_bloc.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_event.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_state.dart';
import 'package:paper_tracker/models/chat_room.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late ChatRepository chatRepository;
  late ChatListBloc chatListBloc;

  setUp(() {
    chatRepository = MockChatRepository();
    chatListBloc = ChatListBloc(chatRepository: chatRepository);
  });

  tearDown(() {
    chatListBloc.close();
  });

  group('ChatListBloc', () {
    test('initial state is ChatListInitial', () {
      expect(chatListBloc.state, isA<ChatListInitial>());
    });

    blocTest<ChatListBloc, ChatListState>(
      'emits [ChatListLoading, ChatListLoaded] on load',
      build: () {
        when(() => chatRepository.getUserChatsStream(any()))
            .thenAnswer((_) => Stream.value([]));
        return chatListBloc;
      },
      act: (bloc) => bloc.add(LoadChatsRequested('uid1')),
      expect: () => [
        isA<ChatListLoading>(),
        isA<ChatListLoaded>(),
      ],
    );

    blocTest<ChatListBloc, ChatListState>(
      'emits ChatCreationSuccess on create chat',
      build: () {
        when(() => chatRepository.createOrGetChatRoom(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => ChatRoom(
              id: 'uid1_uid2',
              participantIds: ['uid1', 'uid2'],
              participantNames: {'uid1': 'A', 'uid2': 'B'},
              lastMessage: '',
              lastMessageTime: DateTime.now(),
            ));
        return chatListBloc;
      },
      act: (bloc) => bloc.add(CreateChatRequested(
        currentUserId: 'uid1',
        otherUserId: 'uid2',
        currentUserName: 'Alice',
        otherUserName: 'Bob',
      )),
      expect: () => [isA<ChatCreationSuccess>()],
    );

    blocTest<ChatListBloc, ChatListState>(
      'emits ChatListError on create failure',
      build: () {
        when(() => chatRepository.createOrGetChatRoom(
              any(),
              any(),
              any(),
              any(),
            )).thenThrow(Exception('Failed'));
        return chatListBloc;
      },
      act: (bloc) => bloc.add(CreateChatRequested(
        currentUserId: 'uid1',
        otherUserId: 'uid2',
        currentUserName: 'Alice',
        otherUserName: 'Bob',
      )),
      expect: () => [isA<ChatListError>()],
    );
  });
}
