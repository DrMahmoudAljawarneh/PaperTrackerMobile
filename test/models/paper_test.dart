import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/paper.dart';

void main() {
  group('PaperStatus', () {
    test('has 10 values', () {
      expect(PaperStatus.values.length, 10);
    });

    test('each status has a non-empty label and emoji', () {
      for (final status in PaperStatus.values) {
        expect(status.label, isNotEmpty);
        expect(status.emoji, isNotEmpty);
      }
    });
  });

  group('PaperPriority', () {
    test('has 3 values', () {
      expect(PaperPriority.values.length, 3);
    });

    test('each priority has a non-empty label', () {
      for (final priority in PaperPriority.values) {
        expect(priority.label, isNotEmpty);
      }
    });
  });

  group('Paper', () {
    final now = DateTime.now();
    final base = Paper(
      id: 'paper1',
      title: 'Test Paper',
      abstract_: 'An abstract',
      status: PaperStatus.drafting,
      priority: PaperPriority.high,
      authorIds: ['uid1', 'uid2'],
      authors: ['Alice', 'Bob'],
      leadAuthorId: 'uid1',
      targetVenue: 'Test Conf',
      deadline: now.add(const Duration(days: 30)),
      tags: ['ml', 'nlp'],
      currentlyWith: 'Reviewers',
      createdAt: now,
      updatedAt: now,
    );

    test('copyWith preserves unchanged fields', () {
      final copy = base.copyWith(title: 'New Title');
      expect(copy.title, 'New Title');
      expect(copy.id, base.id);
      expect(copy.status, base.status);
    });

    test('toMap and fromMap round-trip', () {
      final map = base.toMap();
      final restored = Paper.fromMap('paper1', map);
      expect(restored, base);
    });

    test('equatable works', () {
      final same = base.copyWith();
      expect(base, same);
      expect(base.hashCode, same.hashCode);
    });

    test('toMap contains all keys', () {
      final map = base.toMap();
      expect(map, containsPair('title', 'Test Paper'));
      expect(map, containsPair('status', 'drafting'));
      expect(map, containsPair('priority', 'high'));
      expect(map, containsPair('leadAuthorId', 'uid1'));
    });

    test('fromMap handles missing fields gracefully', () {
      final restored = Paper.fromMap('p1', {'title': 'Minimal'});
      expect(restored.title, 'Minimal');
      expect(restored.status, PaperStatus.idea);
      expect(restored.priority, PaperPriority.medium);
      expect(restored.authorIds, isEmpty);
    });
  });
}
