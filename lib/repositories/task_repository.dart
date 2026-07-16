import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/models/paper_task.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';

class TaskRepository {
  final FirebaseDatabase _db;
  final NotificationRepository? _notificationRepository;

  TaskRepository({
    FirebaseDatabase? db,
    NotificationRepository? notificationRepository,
  })  : _db = db ?? FirebaseDatabase.instance,
        _notificationRepository = notificationRepository;

  DatabaseReference get _tasksRef => _db.ref('tasks');

  /// Stream tasks for a specific paper
  Stream<List<PaperTask>> getTasksForPaper(String paperId) {
    return _tasksRef
        .orderByChild('paperId')
        .equalTo(paperId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <PaperTask>[];
      final data = safeCastMap(event.snapshot.value);
      final tasks = data.entries
          .map((e) =>
              PaperTask.fromMap(e.key, safeCastMap(e.value)))
          .toList();
      // Sort by createdAt ascending (client-side)
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return tasks;
    });
  }

  /// Create a new task. Pass [currentUserId], [currentUserName], and [paperTitle]
  /// to notify the assignee.
  Future<String> createTask(
    PaperTask task, {
    String? currentUserId,
    String? currentUserName,
    String? paperTitle,
  }) async {
    final newRef = _tasksRef.push();
    await newRef.set(task.toMap());

    // Notify the assignee if one is set
    if (_notificationRepository != null &&
        task.assigneeId.isNotEmpty &&
        currentUserId != null &&
        task.assigneeId != currentUserId) {
      await _notificationRepository.pushNotificationToMany(
        recipientIds: [task.assigneeId],
        senderId: currentUserId,
        senderName: currentUserName ?? '',
        title: 'Task Assigned',
        message: paperTitle != null
            ? 'You were assigned "${task.title}" on "$paperTitle"'
            : 'You were assigned "${task.title}"',
        type: NotificationType.taskAssigned,
        relatedPaperId: task.paperId,
      );
    }

    return newRef.key!;
  }

  /// Update a task
  Future<void> updateTask(PaperTask task) async {
    await _tasksRef.child(task.id).update(task.toMap());
  }

  /// Update specific fields of a task without overwriting others
  Future<void> updateTaskFields(
    String taskId, {
    required String title,
    required String assigneeId,
    DateTime? dueDate,
    String? priority,
    int? progress,
  }) async {
    final updateMap = <String, dynamic>{
      'title': title,
      'assigneeId': assigneeId,
    };
    if (dueDate != null) updateMap['dueDate'] = dueDate.toIso8601String();
    if (priority != null) updateMap['priority'] = priority;
    if (progress != null) updateMap['progress'] = progress;
    await _tasksRef.child(taskId).update(updateMap);
  }

  /// Toggle task completion. Pass [currentUserId], [currentUserName], and [paperTitle]
  /// to notify when a task is completed.
  Future<void> toggleTask(
    String taskId,
    bool completed, {
    String? currentUserId,
    String? currentUserName,
    String? paperTitle,
    String? paperId,
    String? taskTitle,
    String? assigneeId,
  }) async {
    await _tasksRef.child(taskId).update({'completed': completed});

    // If task was just completed, notify task owner / assignee
    if (completed &&
        _notificationRepository != null &&
        assigneeId != null &&
        assigneeId.isNotEmpty &&
        currentUserId != null &&
        assigneeId != currentUserId) {
      await _notificationRepository.pushNotificationToMany(
        recipientIds: [assigneeId],
        senderId: currentUserId,
        senderName: currentUserName ?? '',
        title: 'Task Completed',
        message: paperTitle != null
            ? '"${taskTitle ?? 'A task'}" was completed on "$paperTitle"'
            : '"${taskTitle ?? 'A task'}" was completed',
        type: NotificationType.taskCompleted,
        relatedPaperId: paperId ?? '',
      );
    }
  }

  /// Get all tasks for a list of paper IDs (one-shot fetch)
  Future<List<PaperTask>> getTasksForPapers(List<String> paperIds) async {
    final snapshot = await _tasksRef.get();
    if (!snapshot.exists) return [];
    final data = safeCastMap(snapshot.value);
    final paperIdSet = paperIds.toSet();
    final tasks = <PaperTask>[];
    for (final entry in data.entries) {
      final map = safeCastMap(entry.value);
      if (paperIdSet.contains(map['paperId'])) {
        tasks.add(PaperTask.fromMap(entry.key, map));
      }
    }
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.child(taskId).remove();
  }

  /// Get count of completed tasks for a paper
  Future<Map<String, int>> getTaskStats(String paperId) async {
    final snapshot =
        await _tasksRef.orderByChild('paperId').equalTo(paperId).get();
    if (!snapshot.exists) return {'total': 0, 'completed': 0};
    final data = safeCastMap(snapshot.value);
    final total = data.length;
    final completed = data.values
        .where((v) => v is Map && v['completed'] == true)
        .length;
    return {'total': total, 'completed': completed};
  }
}

