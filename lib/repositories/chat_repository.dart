import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/chat_message.dart';
import 'package:paper_tracker/models/chat_room.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/utils/cache.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';

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

    // Read current unreadCount to increment
    final chatSnap = await _chatsRef.child(chatId).child('unreadCount').get();
    final currentUnread = (chatSnap.value as int?) ?? 0;

    await newMsgRef.set(messageToSave.toMap());
    await _chatsRef.child(chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      'unreadCount': currentUnread + 1,
    });
  }

  /// Mark all unread messages from others as read and reset unread count
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final snapshot = await _messagesRef.child(chatId).get();
    if (!snapshot.exists) return;
    final data = safeCastMap(snapshot.value);
    final updates = <String, dynamic>{};
    for (final entry in data.entries) {
      final msg = safeCastMap(entry.value);
      if (msg['senderId'] != currentUserId && msg['isRead'] != true) {
        updates['messages/$chatId/${entry.key}/isRead'] = true;
      }
    }
    if (updates.isNotEmpty) {
      updates['chats/$chatId/unreadCount'] = 0;
      await _db.ref().update(updates);
    }
  }

  /// Listen to messages in a specific chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _messagesRef.child(chatId).onValue.map((event) {
      if (!event.snapshot.exists) return [];
      
      final data = safeCastMap(event.snapshot.value);
      final messages = data.entries.map((e) {
        return ChatMessage.fromMap(
            safeCastMap(e.value), e.key);
      }).toList();
      
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  /// Listen to all chat rooms a user is part of using a denormalized index.
  Stream<List<ChatRoom>> getUserChatsStream(String userId) {
    return _db.ref('userChats/$userId').onValue.asyncMap((event) async {
      if (!event.snapshot.exists) return [];
      final chatIds = safeCastMap(event.snapshot.value);
      final futures = chatIds.keys.map((id) => _chatsRef.child(id).get());
      final snapshots = await Future.wait(futures);
      final chatRooms = <ChatRoom>[];
      for (final snap in snapshots) {
        if (snap.exists) {
          chatRooms.add(ChatRoom.fromMap(safeCastMap(snap.value), snap.key!));
        }
      }
      chatRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chatRooms;
    });
  }

  /// Create a new chat room or get existing one.
  /// Also writes to the userChats denormalized index for efficient querying.
  Future<ChatRoom> createOrGetChatRoom(String currentUserId, String otherUserId, String currentUserName, String otherUserName) async {
    // A predictable chat ID based on user IDs
    final participants = [currentUserId, otherUserId]..sort();
    final chatId = '${participants[0]}_${participants[1]}';
    
    final snapshot = await _chatsRef.child(chatId).get();
    
    if (snapshot.exists) {
      final data = safeCastMap(snapshot.value);
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
      
      // Write chat room + userChats index atomically
      await _chatsRef.child(chatId).set(newRoom.toMap());
      await _db.ref('userChats/$currentUserId/$chatId').set(true);
      await _db.ref('userChats/$otherUserId/$chatId').set(true);
      return newRoom;
    }
  }

  final TtlCache<List<UserModel>> _usersCache = TtlCache(ttlMinutes: 5);

  Future<List<UserModel>> getAllUsers({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _usersCache.value;
      if (cached != null) return cached;
    }

    final snapshot = await _db.ref('users').get();
    if (!snapshot.exists) return [];

    final results = <UserModel>[];
    final data = safeCastMap(snapshot.value);

    data.forEach((key, value) {
      final user = UserModel.fromMap(safeCastMap(value));
      results.add(user);
    });

    _usersCache.set(results);
    return results;
  }
}
