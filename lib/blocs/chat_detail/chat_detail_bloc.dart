import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_event.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_state.dart';
import 'package:paper_tracker/models/chat_message.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatRepository _chatRepository;

  ChatDetailBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatDetailInitial()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(ChatDetailLoading());
    _chatRepository.markMessagesAsRead(event.chatId, event.currentUserId);
    await emit.forEach<List<ChatMessage>>(
      _chatRepository.getMessagesStream(event.chatId),
      onData: (messages) => ChatDetailLoaded(messages),
      onError: (error, stackTrace) =>
          ChatDetailError(error.toString()),
    );
  }

  void _onSendMessage(
    SendMessage event,
    Emitter<ChatDetailState> emit,
  ) async {
    try {
      final message = ChatMessage(
        id: '',
        senderId: event.senderId,
        text: event.text,
        timestamp: DateTime.now(),
        isRead: false,
      );
      await _chatRepository.sendMessage(event.chatId, message);
    } catch (e) {
      debugPrint('Failed to send message: $e');
    }
  }
}
