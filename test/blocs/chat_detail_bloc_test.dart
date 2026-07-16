import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_bloc.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_event.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_state.dart';
import 'package:paper_tracker/models/chat_message.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class FakeChatMessage extends Fake implements ChatMessage {}

void main() {
  late ChatRepository chatRepository;
  late ChatDetailBloc chatDetailBloc;

  setUpAll(() {
    registerFallbackValue(FakeChatMessage());
  });

  setUp(() {
    chatRepository = MockChatRepository();
    chatDetailBloc = ChatDetailBloc(chatRepository: chatRepository);
  });

  tearDown(() {
    chatDetailBloc.close();
  });

  group('ChatDetailBloc', () {
    test('initial state is ChatDetailInitial', () {
      expect(chatDetailBloc.state, isA<ChatDetailInitial>());
    });

    blocTest<ChatDetailBloc, ChatDetailState>(
      'emits [ChatDetailLoading, ChatDetailLoaded] on load',
      build: () {
        when(() => chatRepository.getMessagesStream(any()))
            .thenAnswer((_) => Stream.value([]));
        when(() => chatRepository.markMessagesAsRead(any(), any()))
            .thenAnswer((_) async {});
        return chatDetailBloc;
      },
      act: (bloc) => bloc.add(LoadChatMessages('chat1', 'uid1')),
      expect: () => [
        isA<ChatDetailLoading>(),
        isA<ChatDetailLoaded>(),
      ],
    );

    blocTest<ChatDetailBloc, ChatDetailState>(
      'sends message successfully',
      build: () {
        when(() => chatRepository.sendMessage(any(), any()))
            .thenAnswer((_) async {});
        return chatDetailBloc;
      },
      act: (bloc) => bloc.add(SendMessage(
        chatId: 'chat1',
        senderId: 'uid1',
        text: 'Hello!',
      )),
      expect: () => [],
    );

    blocTest<ChatDetailBloc, ChatDetailState>(
      'handles send failure silently',
      build: () {
        when(() => chatRepository.sendMessage(any(), any()))
            .thenThrow(Exception('Send failed'));
        return chatDetailBloc;
      },
      act: (bloc) => bloc.add(SendMessage(
        chatId: 'chat1',
        senderId: 'uid1',
        text: 'Hello!',
      )),
      expect: () => [],
    );
  });
}
