import 'package:equatable/equatable.dart';
import 'package:paper_tracker/models/paper_task.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TaskEvent {
  final String paperId;

  const TasksLoadRequested(this.paperId);

  @override
  List<Object?> get props => [paperId];
}

class TaskCreateRequested extends TaskEvent {
  final PaperTask task;

  const TaskCreateRequested(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskToggleRequested extends TaskEvent {
  final String taskId;
  final bool completed;

  const TaskToggleRequested({required this.taskId, required this.completed});

  @override
  List<Object?> get props => [taskId, completed];
}

class TaskDeleteRequested extends TaskEvent {
  final String taskId;

  const TaskDeleteRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TasksUpdated extends TaskEvent {
  final List<PaperTask> tasks;

  const TasksUpdated(this.tasks);

  @override
  List<Object?> get props => [tasks];
}
