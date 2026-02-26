import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/chat_message.dart';
import 'package:paper_tracker/models/chat_room.dart';
import 'package:paper_tracker/models/user_model.dart';

class ChatRepository {
  final FirebaseDatabase _db;

  ChatRepository({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  DatabaseReference get _chatsRef => _db.ref('chats');
  DatabaseReference get _messagesRef => _db.ref('messages');

  /// Send a new message to a specific chat room
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    final newMsgRef = _messagesRef.child(chatId).push();
    final messageId = newMsgRef.key!;
    final messageToSave = message.copyWith(id: messageId);
    
    // Save message
    await newMsgRef.set(messageToSave.toMap());

    // Update chat room last message
    await _chatsRef.child(chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
    });
  }

  /// Listen to messages in a specific chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _messagesRef.child(chatId).onValue.map((event) {
      if (!event.snapshot.exists) return [];
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final messages = data.entries.map((e) {
        return ChatMessage.fromMap(
            Map<String, dynamic>.from(e.value as Map), e.key);
      }).toList();
      
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  /// Listen to all chat rooms a user is part of
  Stream<List<ChatRoom>> getUserChatsStream(String userId) {
    return _chatsRef.onValue.map((event) {
      if (!event.snapshot.exists) return [];
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final chatRooms = data.entries.map((e) {
        return ChatRoom.fromMap(e.value as Map, e.key);
      }).where((room) => room.participantIds.contains(userId)).toList();
      
      chatRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chatRooms;
    });
  }

  /// Create a new chat room or get existing one
  Future<ChatRoom> createOrGetChatRoom(String currentUserId, String otherUserId, String currentUserName, String otherUserName) async {
    // A predictable chat ID based on user IDs
    final participants = [currentUserId, otherUserId]..sort();
    final chatId = '${participants[0]}_${participants[1]}';
    
    final snapshot = await _chatsRef.child(chatId).get();
    
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      return ChatRoom.fromMap(data, chatId);
    } else {
      final newRoom = ChatRoom(
        id: chatId,
        participantIds: participants,
        participantNames: {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );
      
      await _chatsRef.child(chatId).set(newRoom.toMap());
      return newRoom;
    }
  }

  /// Fetch all users (for creating new chats)
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.ref('users').get();
    if (!snapshot.exists) return [];
    
    final results = <UserModel>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    data.forEach((key, value) {
      final user = UserModel.fromMap(Map<String, dynamic>.from(value));
      results.add(user);
    });
    
    return results;
  }
}
