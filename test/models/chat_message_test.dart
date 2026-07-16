import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    final now = DateTime.now();
    final message = ChatMessage(
      id: 'm1',
      senderId: 'uid1',
      text: 'Hello!',
      timestamp: now,
      isRead: false,
    );

    test('toMap and fromMap round-trip', () {
      final map = message.toMap();
      final restored = ChatMessage.fromMap(map, 'm1');
      expect(restored.id, message.id);
      expect(restored.senderId, message.senderId);
      expect(restored.text, message.text);
      expect(restored.isRead, message.isRead);
    });

    test('copyWith updates id', () {
      final withId = message.copyWith(id: 'm2');
      expect(withId.id, 'm2');
    });

    test('equatable works', () {
      expect(message, message.copyWith());
    });
  });
}
