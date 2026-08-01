import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/models/paper_task.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';
import 'package:retry/retry.dart';

class TaskRepository {
  final FirebaseDatabase _db;
  final NotificationRepository? _notificationRepository;
  static const int _pageSize = 50;

  TaskRepository({
    FirebaseDatabase? db,
    NotificationRepository? notificationRepository,
  })  : _db = db ?? FirebaseDatabase.instance,
        _notificationRepository = notificationRepository;

  DatabaseReference get _tasksRef => _db.ref('tasks');

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
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return tasks;
    });
  }

  Future<List<PaperTask>> getTasksForPapersPaginated(List<String> paperIds, {String? lastKey, int limit = _pageSize}) async {
    return retry(
      () => _fetchTasksPage(paperIds, lastKey: lastKey, limit: limit),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<List<PaperTask>> _fetchTasksPage(List<String> paperIds, {String? lastKey, int limit = _pageSize}) async {
    final snapshot = await _tasksRef.get();
    if (!snapshot.exists) return [];
    final data = safeCastMap(snapshot.value);
    final paperIdSet = paperIds.toSet();
    final allTasks = <PaperTask>[];
    for (final entry in data.entries) {
      final map = safeCastMap(entry.value);
      if (paperIdSet.contains(map['paperId'])) {
        allTasks.add(PaperTask.fromMap(entry.key, map));
      }
    }
    allTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    int startIndex = 0;
    if (lastKey != null) {
      startIndex = allTasks.indexWhere((t) => t.id == lastKey);
      if (startIndex < 0) startIndex = 0;
      startIndex += 1;
    }
    return allTasks.skip(startIndex).take(limit).toList();
  }

  Future<String> createTask(
    PaperTask task, {
    String? currentUserId,
    String? currentUserName,
    String? paperTitle,
  }) async {
    return retry(
      () async {
        final newRef = _tasksRef.push();
        await newRef.set(task.toMap());

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
      },
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<void> updateTask(PaperTask task) async {
    return retry(
      () => _tasksRef.child(task.id).update(task.toMap()),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

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
    await retry(
      () => _tasksRef.child(taskId).update(updateMap),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

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
    await retry(
      () => _tasksRef.child(taskId).update({'completed': completed}),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );

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

  Future<void> deleteTask(String taskId) async {
    await retry(
      () => _tasksRef.child(taskId).remove(),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<Map<String, int>> getTaskStats(String paperId) async {
    final snapshot =
        await retry(
      () => _tasksRef.orderByChild('paperId').equalTo(paperId).get(),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
    if (!snapshot.exists) return {'total': 0, 'completed': 0};
    final data = safeCastMap(snapshot.value);
    final total = data.length;
    final completed = data.values
        .where((v) => v is Map && v['completed'] == true)
        .length;
    return {'total': total, 'completed': completed};
  }
}

