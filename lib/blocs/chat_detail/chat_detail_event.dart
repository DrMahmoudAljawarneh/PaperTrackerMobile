import 'package:equatable/equatable.dart';

abstract class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatMessages extends ChatDetailEvent {
  final String chatId;

  const LoadChatMessages(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendMessage extends ChatDetailEvent {
  final String chatId;
  final String senderId;
  final String text;

  const SendMessage({
    required this.chatId,
    required this.senderId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, senderId, text];
}
