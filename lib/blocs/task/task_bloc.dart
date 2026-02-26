import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/task/task_event.dart';
import 'package:paper_tracker/blocs/task/task_state.dart';
import 'package:paper_tracker/models/paper_task.dart';
import 'package:paper_tracker/repositories/task_repository.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;
  StreamSubscription<List<PaperTask>>? _tasksSubscription;

  TaskBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(TaskInitial()) {
    on<TasksLoadRequested>(_onLoadRequested);
    on<TasksUpdated>(_onTasksUpdated);
    on<TaskCreateRequested>(_onCreateRequested);
    on<TaskToggleRequested>(_onToggleRequested);
    on<TaskDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    _tasksSubscription?.cancel();
    _tasksSubscription =
        _taskRepository.getTasksForPaper(event.paperId).listen(
      (tasks) => add(TasksUpdated(tasks)),
      onError: (error) => add(const TasksUpdated([])),
    );
  }

  void _onTasksUpdated(
    TasksUpdated event,
    Emitter<TaskState> emit,
  ) {
    emit(TasksLoaded(event.tasks));
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.createTask(
        event.task,
        currentUserId: event.currentUserId,
        currentUserName: event.currentUserName,
        paperTitle: event.paperTitle,
      );
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onToggleRequested(
    TaskToggleRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.toggleTask(
        event.taskId,
        event.completed,
        currentUserId: event.currentUserId,
        currentUserName: event.currentUserName,
        paperTitle: event.paperTitle,
        paperId: event.paperId,
        taskTitle: event.taskTitle,
        assigneeId: event.assigneeId,
      );
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    TaskDeleteRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.deleteTask(event.taskId);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
