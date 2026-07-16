import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/comment.dart';

void main() {
  group('Comment', () {
    final now = DateTime.now();
    final comment = Comment(
      id: 'c1',
      paperId: 'paper1',
      authorId: 'uid1',
      authorName: 'Alice',
      text: 'Great work!',
      createdAt: now,
    );

    test('toMap and fromMap round-trip', () {
      final map = comment.toMap();
      final restored = Comment.fromMap('c1', map);
      expect(restored.id, comment.id);
      expect(restored.text, comment.text);
      expect(restored.authorId, comment.authorId);
    });

    test('equatable works', () {
      final same = Comment(
        id: 'c1',
        paperId: 'paper1',
        authorId: 'uid1',
        authorName: 'Alice',
        text: 'Great work!',
        createdAt: now,
      );
      expect(comment, same);
    });

    test('toMap contains required fields', () {
      final map = comment.toMap();
      expect(map['paperId'], 'paper1');
      expect(map['text'], 'Great work!');
    });
  });
}
