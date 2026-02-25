import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/paper_task.dart';

class TaskRepository {
  final FirebaseDatabase _db;

  TaskRepository({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  DatabaseReference get _tasksRef => _db.ref('tasks');

  /// Stream tasks for a specific paper
  Stream<List<PaperTask>> getTasksForPaper(String paperId) {
    return _tasksRef
        .orderByChild('paperId')
        .equalTo(paperId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <PaperTask>[];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final tasks = data.entries
          .map((e) =>
              PaperTask.fromMap(e.key, Map<String, dynamic>.from(e.value)))
          .toList();
      // Sort by createdAt ascending (client-side)
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return tasks;
    });
  }

  /// Create a new task
  Future<String> createTask(PaperTask task) async {
    final newRef = _tasksRef.push();
    await newRef.set(task.toMap());
    return newRef.key!;
  }

  /// Update a task
  Future<void> updateTask(PaperTask task) async {
    await _tasksRef.child(task.id).update(task.toMap());
  }

  /// Toggle task completion
  Future<void> toggleTask(String taskId, bool completed) async {
    await _tasksRef.child(taskId).update({'completed': completed});
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
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final total = data.length;
    final completed = data.values
        .where((v) => (v as Map)['completed'] == true)
        .length;
    return {'total': total, 'completed': completed};
  }
}
