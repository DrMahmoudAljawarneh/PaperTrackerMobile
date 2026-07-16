import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/paper_task.dart';

void main() {
  group('PaperTask', () {
    final now = DateTime.now();
    final task = PaperTask(
      id: 'task1',
      paperId: 'paper1',
      title: 'Write introduction',
      assigneeId: 'uid1',
      completed: false,
      dueDate: now.add(const Duration(days: 7)),
      createdAt: now,
    );

    test('toMap and fromMap round-trip', () {
      final map = task.toMap();
      final restored = PaperTask.fromMap('task1', map);
      expect(restored, task);
    });

    test('copyWith updates correctly', () {
      final updated = task.copyWith(completed: true);
      expect(updated.completed, true);
      expect(updated.title, task.title);
    });

    test('equatable works', () {
      final same = task.copyWith();
      expect(task, same);
    });
  });
}
