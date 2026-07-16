import 'package:equatable/equatable.dart';

enum TaskPriority { high, medium, low }

class PaperTask extends Equatable {
  final String id;
  final String paperId;
  final String title;
  final String assigneeId;
  final bool completed;
  final DateTime? dueDate;
  final TaskPriority priority;
  final int progress;
  final DateTime createdAt;

  const PaperTask({
    required this.id,
    required this.paperId,
    required this.title,
    this.assigneeId = '',
    this.completed = false,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.progress = 0,
    required this.createdAt,
  });

  PaperTask copyWith({
    String? id,
    String? paperId,
    String? title,
    String? assigneeId,
    bool? completed,
    DateTime? dueDate,
    TaskPriority? priority,
    int? progress,
    DateTime? createdAt,
  }) {
    return PaperTask(
      id: id ?? this.id,
      paperId: paperId ?? this.paperId,
      title: title ?? this.title,
      assigneeId: assigneeId ?? this.assigneeId,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paperId': paperId,
      'title': title,
      'assigneeId': assigneeId,
      'completed': completed,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaperTask.fromMap(String id, Map<String, dynamic> map) {
    return PaperTask(
      id: id,
      paperId: map['paperId'] ?? '',
      title: map['title'] ?? '',
      assigneeId: map['assigneeId'] ?? '',
      completed: map['completed'] ?? false,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, paperId, title, assigneeId, completed, dueDate, priority, progress, createdAt];
}
