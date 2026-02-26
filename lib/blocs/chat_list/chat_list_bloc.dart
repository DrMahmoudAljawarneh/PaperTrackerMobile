import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_event.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_state.dart';
import 'package:paper_tracker/models/chat_room.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _chatRepository;
  StreamSubscription<List<ChatRoom>>? _chatsSubscription;

  ChatListBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatListInitial()) {
    on<LoadChatsRequested>(_onLoadChatsRequested);
    on<CreateChatRequested>(_onCreateChatRequested);
  }

  void _onLoadChatsRequested(
    LoadChatsRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(ChatListLoading());
    await _chatsSubscription?.cancel();
    
    // We use emit.forEach to listen to the stream from our repository
    await emit.forEach<List<ChatRoom>>(
      _chatRepository.getUserChatsStream(event.userId),
      onData: (chats) => ChatListLoaded(chats),
      onError: (error, stackTrace) =>
          ChatListError(error.toString()),
    );
  }

  void _onCreateChatRequested(
    CreateChatRequested event,
    Emitter<ChatListState> emit,
  ) async {
    try {
      final chatRoom = await _chatRepository.createOrGetChatRoom(
        event.currentUserId,
        event.otherUserId,
        event.currentUserName,
        event.otherUserName,
      );
      emit(ChatCreationSuccess(chatRoom));
      // Optionally reload chats, though Stream should handle this automatically
    } catch (e) {
      emit(ChatListError('Failed to create chat: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}
