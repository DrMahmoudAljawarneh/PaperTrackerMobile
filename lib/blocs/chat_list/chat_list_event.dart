import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatsRequested extends ChatListEvent {
  final String userId;

  const LoadChatsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateChatRequested extends ChatListEvent {
  final String currentUserId;
  final String otherUserId;
  final String currentUserName;
  final String otherUserName;

  const CreateChatRequested({
    required this.currentUserId,
    required this.otherUserId,
    required this.currentUserName,
    required this.otherUserName,
  });

  @override
  List<Object?> get props =>
      [currentUserId, otherUserId, currentUserName, otherUserName];
}
