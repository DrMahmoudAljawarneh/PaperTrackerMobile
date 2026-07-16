import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';

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

      final paperIds = safeCastMap(event.snapshot.value);
      final futures = paperIds.keys.map((id) => _papersRef.child(id).get());
      final snapshots = await Future.wait(futures);
      final papers = <Paper>[];

      for (final snapshot in snapshots) {
        if (snapshot.exists) {
          final data = safeCastMap(snapshot.value);
          papers.add(Paper.fromMap(snapshot.key!, data));
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
      final data = safeCastMap(snapshot.value);
      return Paper.fromMap(paperId, data);
    }
    return null;
  }

  /// Stream a single paper by ID
  Stream<Paper?> streamPaper(String paperId) {
    return _papersRef.child(paperId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = safeCastMap(event.snapshot.value);
        return Paper.fromMap(paperId, data);
      }
      return null;
    });
  }

  /// Create a new paper
  Future<String> createPaper(
    Paper paper, {
    String? currentUserId,
    String? currentUserName,
  }) async {
    final newRef = _papersRef.push();
    final paperId = newRef.key!;
    await newRef.set(paper.toMap());

    // Write to the denormalized index for each author
    final updates = <String, dynamic>{};
    for (final authorId in paper.authorIds) {
      updates['papersByUser/$authorId/$paperId'] = true;
    }
    await _db.ref().update(updates);

    // Notify co-authors that they've been added to a new paper
    if (paper.authorIds.length > 1 &&
        _notificationRepository != null &&
        currentUserId != null) {
      await _notificationRepository.pushNotificationToMany(
        recipientIds: paper.authorIds,
        senderId: currentUserId,
        senderName: currentUserName ?? '',
        title: 'New Paper Created',
        message: 'You were added to a new paper: "${paper.title}"',
        type: NotificationType.paperCreated,
        relatedPaperId: paperId,
      );
    }

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
      final oldData = safeCastMap(oldSnapshot.value);
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
      await _notificationRepository.pushNotificationToMany(
        recipientIds: added,
        senderId: currentUserId,
        senderName: currentUserName ?? '',
        title: 'Added to Paper',
        message: 'You were added as a collaborator on "${paper.title}"',
        type: NotificationType.collaboratorAdded,
        relatedPaperId: paper.id,
      );
    }

    // Notify existing co-authors that the paper was modified
    final existingAuthors =
        paper.authorIds.where((id) => !added.contains(id)).toList();
    if (existingAuthors.isNotEmpty &&
        _notificationRepository != null &&
        currentUserId != null) {
      await _notificationRepository.pushNotificationToMany(
        recipientIds: existingAuthors,
        senderId: currentUserId,
        senderName: currentUserName ?? '',
        title: 'Paper Modified',
        message: '"${paper.title}" has been updated',
        type: NotificationType.paperModified,
        relatedPaperId: paper.id,
      );
    }
  }

  /// Delete a paper and its related data using a single atomic batch write.
  Future<void> deletePaper(String paperId) async {
    final paperSnapshot = await _papersRef.child(paperId).get();
    final updates = <String, dynamic>{};

    // Gather tasks to delete
    final tasksSnapshot = await _db
        .ref('tasks')
        .orderByChild('paperId')
        .equalTo(paperId)
        .get();
    if (tasksSnapshot.exists) {
      final tasks = safeCastMap(tasksSnapshot.value);
      for (final taskId in tasks.keys) {
        updates['tasks/$taskId'] = null;
      }
    }

    // Gather comments to delete
    final commentsSnapshot = await _db
        .ref('comments')
        .orderByChild('paperId')
        .equalTo(paperId)
        .get();
    if (commentsSnapshot.exists) {
      final comments = safeCastMap(commentsSnapshot.value);
      for (final commentId in comments.keys) {
        updates['comments/$commentId'] = null;
      }
    }

    // Gather index entries to remove
    if (paperSnapshot.exists) {
      final data = safeCastMap(paperSnapshot.value);
      final authorIds = safeCastStringList(data['authorIds']);
      for (final authorId in authorIds) {
        updates['papersByUser/$authorId/$paperId'] = null;
      }
    }

    // Delete the paper itself
    updates['papers/$paperId'] = null;

    await _db.ref().update(updates);
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
      final data = safeCastMap(paperSnapshot.value);
      authorIds = safeCastStringList(data['authorIds']);
    }

    await _papersRef.child(paperId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Notify all contributors about the status change
    if (authorIds.isNotEmpty &&
        _notificationRepository != null &&
        currentUserId != null) {
      await _notificationRepository.pushNotificationToMany(
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

