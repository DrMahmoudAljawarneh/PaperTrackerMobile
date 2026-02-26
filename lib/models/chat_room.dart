import 'package:equatable/equatable.dart';

class ChatRoom extends Equatable {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  ChatRoom copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
    };
  }

  factory ChatRoom.fromMap(Map<dynamic, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'] as int)
          : DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
  
  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId, orElse: () => currentUserId);
  }
  
  String getOtherUserName(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    return participantNames[otherUserId] ?? 'Unknown User';
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        participantNames,
        lastMessage,
        lastMessageTime,
        unreadCount,
      ];
}
