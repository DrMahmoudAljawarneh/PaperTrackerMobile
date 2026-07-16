import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/repositories/task_repository.dart';
import 'package:paper_tracker/models/paper_task.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseDatabase mockDb;
  late TaskRepository repository;

  setUp(() {
    mockDb = MockFirebaseDatabase();
    repository = TaskRepository(db: mockDb);
  });

  group('TaskRepository', () {
    test('getTasksForPaper returns stream of tasks', () async {
      final tasksRef = MockDatabaseReference();
      final tasksQuery = MockDatabaseReference();

      when(() => mockDb.ref('tasks')).thenReturn(tasksRef);
      when(() => tasksRef.orderByChild('paperId')).thenReturn(tasksQuery);
      when(() => tasksQuery.equalTo('paper1')).thenReturn(tasksQuery);

      final now = DateTime.now();
      final event = MockDatabaseEvent();
      final snapshot = MockDataSnapshot();
      when(() => event.snapshot).thenReturn(snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn({
        'task1': {
          'paperId': 'paper1',
          'title': 'Task 1',
          'assigneeId': 'uid1',
          'completed': false,
          'createdAt': now.toIso8601String(),
        },
        'task2': {
          'paperId': 'paper1',
          'title': 'Task 2',
          'assigneeId': 'uid2',
          'completed': true,
          'createdAt': now.toIso8601String(),
        },
      });

      when(() => tasksQuery.onValue).thenAnswer((_) => Stream.value(event));

      final tasks = await repository.getTasksForPaper('paper1').first;

      expect(tasks.length, 2);
    });

    test('createTask creates and returns task ID', () async {
      final tasksRef = MockDatabaseReference();
      final newRef = MockDatabaseReference();

      when(() => mockDb.ref('tasks')).thenReturn(tasksRef);
      when(() => tasksRef.push()).thenReturn(newRef);
      when(() => newRef.key).thenReturn('newTaskId');
      when(() => newRef.set(any())).thenAnswer((_) async {});

      final task = PaperTask(
        id: '',
        paperId: 'paper1',
        title: 'Test Task',
        createdAt: DateTime.now(),
      );

      final result = await repository.createTask(task);
      expect(result, 'newTaskId');
    });

    test('updateTask runs without error', () async {
      final tasksRef = MockDatabaseReference();
      final taskRef = MockDatabaseReference();

      when(() => mockDb.ref('tasks')).thenReturn(tasksRef);
      when(() => tasksRef.child('task1')).thenReturn(taskRef);
      when(() => taskRef.update(any())).thenAnswer((_) async {});

      final task = PaperTask(
        id: 'task1',
        paperId: 'paper1',
        title: 'Updated Task',
        createdAt: DateTime.now(),
      );

      await expectLater(
        repository.updateTask(task),
        completes,
      );
    });

    test('deleteTask runs without error', () async {
      final tasksRef = MockDatabaseReference();
      final taskRef = MockDatabaseReference();

      when(() => mockDb.ref('tasks')).thenReturn(tasksRef);
      when(() => tasksRef.child('task1')).thenReturn(taskRef);
      when(() => taskRef.remove()).thenAnswer((_) async {});

      await expectLater(
        repository.deleteTask('task1'),
        completes,
      );
    });

    test('toggleTask runs without error', () async {
      final tasksRef = MockDatabaseReference();
      final taskRef = MockDatabaseReference();

      when(() => mockDb.ref('tasks')).thenReturn(tasksRef);
      when(() => tasksRef.child('task1')).thenReturn(taskRef);
      when(() => taskRef.update(any())).thenAnswer((_) async {});

      await expectLater(
        repository.toggleTask('task1', true),
        completes,
      );
    });

    test('getTaskStats returns total/completed counts', () async {
      final tasksRef = MockDatabaseReference();
      final tasksQuery = MockDatabaseReference();

      when(() => mockDb.ref('tasks')).thenReturn(tasksRef);
      when(() => tasksRef.orderByChild('paperId')).thenReturn(tasksQuery);
      when(() => tasksQuery.equalTo('paper1')).thenReturn(tasksQuery);

      final snapshot = MockDataSnapshot();
      when(() => tasksQuery.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn({
        'task1': {'paperId': 'paper1', 'completed': true},
        'task2': {'paperId': 'paper1', 'completed': false},
        'task3': {'paperId': 'paper1', 'completed': true},
      });

      final stats = await repository.getTaskStats('paper1');

      expect(stats['total'], 3);
      expect(stats['completed'], 2);
    });
  });
}
