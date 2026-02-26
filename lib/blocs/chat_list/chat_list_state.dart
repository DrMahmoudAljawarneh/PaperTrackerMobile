import 'package:equatable/equatable.dart';
import 'package:paper_tracker/models/chat_room.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<ChatRoom> chats;

  const ChatListLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatCreationSuccess extends ChatListState {
  final ChatRoom chat;

  const ChatCreationSuccess(this.chat);

  @override
  List<Object?> get props => [chat];
}
