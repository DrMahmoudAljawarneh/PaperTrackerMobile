import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_event.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_state.dart';
import 'package:paper_tracker/models/chat_message.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatRepository _chatRepository;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  ChatDetailBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatDetailInitial()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessage>(_onSendMessage);
  }

  void _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(ChatDetailLoading());
    await _messagesSubscription?.cancel();
    
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
        id: '', // Will be set by repository
        senderId: event.senderId,
        text: event.text,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      await _chatRepository.sendMessage(event.chatId, message);
    } catch (e) {
      // It's tricky to emit an error state here because the stream is active,
      // but we could emit an error and then quickly revert back, or simply
      // handle message send failures visually inside the UI differently.
      // For now, we'll assume it succeeds or fails silently from the State's perspective,
      // as the stream listener is the ultimate source of truth.
      emit(ChatDetailError('Failed to send message: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
