import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/task/task_bloc.dart';
import 'package:paper_tracker/blocs/task/task_event.dart';
import 'package:paper_tracker/blocs/task/task_state.dart';
import 'package:paper_tracker/models/paper_task.dart';
import 'package:paper_tracker/repositories/task_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class FakePaperTask extends Fake implements PaperTask {}

void main() {
  late TaskRepository taskRepository;
  late TaskBloc taskBloc;

  setUpAll(() {
    registerFallbackValue(FakePaperTask());
  });

  setUp(() {
    taskRepository = MockTaskRepository();
    taskBloc = TaskBloc(taskRepository: taskRepository);
  });

  tearDown(() {
    taskBloc.close();
  });

  group('TaskBloc', () {
    test('initial state is TaskInitial', () {
      expect(taskBloc.state, isA<TaskInitial>());
    });

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TasksLoaded] on load',
      build: () {
        when(() => taskRepository.getTasksForPaper(any()))
            .thenAnswer((_) => Stream.value([]));
        return taskBloc;
      },
      act: (bloc) => bloc.add(TasksLoadRequested('paper1')),
      expect: () => [
        isA<TaskLoading>(),
        isA<TasksLoaded>(),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits TaskError on create failure',
      build: () {
        when(() => taskRepository.createTask(
              any(),
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
              paperTitle: any(named: 'paperTitle'),
            )).thenThrow(Exception('Create failed'));
        return taskBloc;
      },
      act: (bloc) => bloc.add(TaskCreateRequested(
        PaperTask(
          id: '',
          paperId: 'paper1',
          title: 'New Task',
          assigneeId: '',
          completed: false,
          createdAt: DateTime.now(),
        ),
        currentUserId: 'uid1',
        currentUserName: 'User',
        paperTitle: 'Paper',
      )),
      expect: () => [isA<TaskError>()],
    );
  });
}
