import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';

class PaperRepository {
  final FirebaseDatabase _db;
  final NotificationRepository? _notificationRepository;

  PaperRepository({
    FirebaseDatabase? db,
    NotificationRepository? notificationRepository,
  })  : _db = db ?? FirebaseDatabase.instance,
        _notificationRepository = notificationRepository;

  DatabaseReference get _papersRef => _db.ref('papers');

  /// Stream papers where the current user is an author.
  /// Uses a denormalized index at papersByUser/{userId} for efficient lookups.
  Stream<List<Paper>> getPapers(String userId) {
    return _db.ref('papersByUser/$userId').onValue.asyncMap((event) async {
      if (!event.snapshot.exists) return <Paper>[];

      final paperIds = Map<String, dynamic>.from(event.snapshot.value as Map);
      final papers = <Paper>[];

      for (final paperId in paperIds.keys) {
        final paperSnapshot = await _papersRef.child(paperId).get();
        if (paperSnapshot.exists) {
          final data = Map<String, dynamic>.from(paperSnapshot.value as Map);
          papers.add(Paper.fromMap(paperId, data));
        }
      }

      // Sort by updatedAt descending (client-side)
      papers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return papers;
    });
  }

  /// Get a single paper by ID
  Future<Paper?> getPaperById(String paperId) async {
    final snapshot = await _papersRef.child(paperId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return Paper.fromMap(paperId, data);
    }
    return null;
  }

  /// Stream a single paper by ID
  Stream<Paper?> streamPaper(String paperId) {
    return _papersRef.child(paperId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return Paper.fromMap(paperId, data);
      }
      return null;
    });
  }

  /// Create a new paper
  Future<String> createPaper(Paper paper) async {
    final newRef = _papersRef.push();
    final paperId = newRef.key!;
    await newRef.set(paper.toMap());

    // Write to the denormalized index for each author
    final updates = <String, dynamic>{};
    for (final authorId in paper.authorIds) {
      updates['papersByUser/$authorId/$paperId'] = true;
    }
    await _db.ref().update(updates);

    return paperId;
  }

  /// Update an existing paper and sync the papersByUser index.
  /// Pass [currentUserId] and [currentUserName] to notify newly added collaborators.
  Future<void> updatePaper(
    Paper paper, {
    String? currentUserId,
    String? currentUserName,
  }) async {
    // Get the old authorIds before updating
    final oldSnapshot = await _papersRef.child(paper.id).get();
    List<String> oldAuthorIds = [];
    if (oldSnapshot.exists) {
      final oldData = Map<String, dynamic>.from(oldSnapshot.value as Map);
      oldAuthorIds = List<String>.from(oldData['authorIds'] ?? []);
    }

    await _papersRef.child(paper.id).update(paper.toMap());

    // Sync papersByUser index: add new collaborators, remove old ones
    final newAuthorIds = paper.authorIds;
    final added = newAuthorIds.where((id) => !oldAuthorIds.contains(id)).toList();
    final removed = oldAuthorIds.where((id) => !newAuthorIds.contains(id));

    final updates = <String, dynamic>{};
    for (final uid in added) {
      updates['papersByUser/$uid/${paper.id}'] = true;
    }
    for (final uid in removed) {
      updates['papersByUser/$uid/${paper.id}'] = null;
    }
    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }

    // Notify newly added collaborators
    if (added.isNotEmpty &&
        _notificationRepository != null &&
        currentUserId != null) {
      await _notificationRepository!.pushNotificationToMany(
        recipientIds: added,
        senderId: currentUserId,
        senderName: currentUserName ?? '',
        title: 'Added to Paper',
        message: 'You were added as a collaborator on "${paper.title}"',
        type: NotificationType.collaboratorAdded,
        relatedPaperId: paper.id,
      );
    }
  }

  /// Delete a paper and its related data
  Future<void> deletePaper(String paperId) async {
    // First get the paper to know which authors to clean up
    final paperSnapshot = await _papersRef.child(paperId).get();

    // Delete tasks for this paper
    final tasksSnapshot = await _db
        .ref('tasks')
        .orderByChild('paperId')
        .equalTo(paperId)
        .get();
    if (tasksSnapshot.exists) {
      final tasks = Map<String, dynamic>.from(tasksSnapshot.value as Map);
      for (final taskId in tasks.keys) {
        await _db.ref('tasks/$taskId').remove();
      }
    }

    // Delete comments for this paper
    final commentsSnapshot = await _db
        .ref('comments')
        .orderByChild('paperId')
        .equalTo(paperId)
        .get();
    if (commentsSnapshot.exists) {
      final comments =
          Map<String, dynamic>.from(commentsSnapshot.value as Map);
      for (final commentId in comments.keys) {
        await _db.ref('comments/$commentId').remove();
      }
    }

    // Remove from papersByUser index
    if (paperSnapshot.exists) {
      final data = Map<String, dynamic>.from(paperSnapshot.value as Map);
      final authorIds = List<String>.from(data['authorIds'] ?? []);
      for (final authorId in authorIds) {
        await _db.ref('papersByUser/$authorId/$paperId').remove();
      }
    }

    // Delete the paper itself
    await _papersRef.child(paperId).remove();
  }

  /// Update only the status of a paper and notify all contributors.
  Future<void> updateStatus(
    String paperId,
    PaperStatus status, {
    String? currentUserId,
    String? currentUserName,
    String? paperTitle,
  }) async {
    // Fetch the paper to get authorIds for notifications
    final paperSnapshot = await _papersRef.child(paperId).get();
    List<String> authorIds = [];
    if (paperSnapshot.exists) {
      final data = Map<String, dynamic>.from(paperSnapshot.value as Map);
      authorIds = List<String>.from(data['authorIds'] ?? []);
    }

    await _papersRef.child(paperId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Notify all contributors about the status change
    if (authorIds.isNotEmpty &&
        _notificationRepository != null &&
        currentUserId != null) {
      await _notificationRepository!.pushNotificationToMany(
        recipientIds: authorIds,
        senderId: currentUserId,
        senderName: currentUserName ?? '',
        title: 'Status Changed',
        message:
            '"${paperTitle ?? 'Paper'}" status changed to ${status.label}',
        type: NotificationType.statusChanged,
        relatedPaperId: paperId,
      );
    }
  }
}

