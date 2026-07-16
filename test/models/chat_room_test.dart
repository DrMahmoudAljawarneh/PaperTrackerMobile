import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/chat_room.dart';

void main() {
  group('ChatRoom', () {
    final now = DateTime.now();
    final room = ChatRoom(
      id: 'uid1_uid2',
      participantIds: ['uid1', 'uid2'],
      participantNames: {'uid1': 'Alice', 'uid2': 'Bob'},
      lastMessage: 'Hello!',
      lastMessageTime: now,
      unreadCount: 0,
    );

    test('toMap and fromMap round-trip', () {
      final map = room.toMap();
      final restored = ChatRoom.fromMap(map, 'uid1_uid2');
      expect(restored.id, room.id);
      expect(restored.participantIds, room.participantIds);
      expect(restored.lastMessage, room.lastMessage);
    });

    test('getOtherUserId returns the other participant', () {
      expect(room.getOtherUserId('uid1'), 'uid2');
      expect(room.getOtherUserId('uid2'), 'uid1');
    });

    test('getOtherUserName returns the other participant name', () {
      expect(room.getOtherUserName('uid1'), 'Bob');
      expect(room.getOtherUserName('uid2'), 'Alice');
    });

    test('equatable works', () {
      expect(room, room.copyWith());
    });
  });
}
