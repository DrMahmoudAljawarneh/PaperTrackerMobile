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
  final String? currentUserId;
  final String? currentUserName;
  final String? paperTitle;

  const TaskCreateRequested(
    this.task, {
    this.currentUserId,
    this.currentUserName,
    this.paperTitle,
  });

  @override
  List<Object?> get props => [task, currentUserId, currentUserName, paperTitle];
}

class TaskToggleRequested extends TaskEvent {
  final String taskId;
  final bool completed;
  final String? currentUserId;
  final String? currentUserName;
  final String? paperTitle;
  final String? paperId;
  final String? taskTitle;
  final String? assigneeId;

  const TaskToggleRequested({
    required this.taskId,
    required this.completed,
    this.currentUserId,
    this.currentUserName,
    this.paperTitle,
    this.paperId,
    this.taskTitle,
    this.assigneeId,
  });

  @override
  List<Object?> get props => [
        taskId,
        completed,
        currentUserId,
        currentUserName,
        paperTitle,
        paperId,
        taskTitle,
        assigneeId,
      ];
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
