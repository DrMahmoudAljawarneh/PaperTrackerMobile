import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';
import 'package:retry/retry.dart';

class PaperRepository {
  final FirebaseDatabase _db;
  final NotificationRepository? _notificationRepository;
  static const int _pageSize = 50;

  PaperRepository({
    FirebaseDatabase? db,
    NotificationRepository? notificationRepository,
  })  : _db = db ?? FirebaseDatabase.instance,
        _notificationRepository = notificationRepository;

  DatabaseReference get _papersRef => _db.ref('papers');

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

      papers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return papers;
    });
  }

  Future<List<Paper>> getPapersPaginated(String userId, {String? lastKey, int limit = _pageSize}) async {
    return retry(
      () => _fetchPapersPage(userId, lastKey: lastKey, limit: limit),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<List<Paper>> _fetchPapersPage(String userId, {String? lastKey, int limit = _pageSize}) async {
    final snapshot = await _db.ref('papersByUser/$userId').get();
    if (!snapshot.exists) return <Paper>[];

    final paperIds = safeCastMap(snapshot.value);
    final allIds = paperIds.keys.toList();

    int startIndex = 0;
    if (lastKey != null) {
      startIndex = allIds.indexOf(lastKey) + 1;
      if (startIndex < 0) startIndex = 0;
    }

    final pageIds = allIds.skip(startIndex).take(limit).toList();
    if (pageIds.isEmpty) return <Paper>[];

    final futures = pageIds.map((id) => _papersRef.child(id).get());
    final snapshots = await Future.wait(futures);
    final papers = <Paper>[];

    for (final snapshot in snapshots) {
      if (snapshot.exists) {
        final data = safeCastMap(snapshot.value);
        papers.add(Paper.fromMap(snapshot.key!, data));
      }
    }

    papers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return papers;
  }

  Future<Paper?> getPaperById(String paperId) async {
    return retry(
      () => _papersRef.child(paperId).get().then((snapshot) {
        if (snapshot.exists) {
          final data = safeCastMap(snapshot.value);
          return Paper.fromMap(paperId, data);
        }
        return null;
      }),
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Stream<Paper?> streamPaper(String paperId) {
    return _papersRef.child(paperId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = safeCastMap(event.snapshot.value);
        return Paper.fromMap(paperId, data);
      }
      return null;
    });
  }

  Future<String> createPaper(
    Paper paper, {
    String? currentUserId,
    String? currentUserName,
  }) async {
    return retry(
      () async {
        final newRef = _papersRef.push();
        final paperId = newRef.key!;
        await newRef.set(paper.toMap());

        final updates = <String, dynamic>{};
        for (final authorId in paper.authorIds) {
          updates['papersByUser/$authorId/$paperId'] = true;
        }
        await _db.ref().update(updates);

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
      },
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<void> updatePaper(
    Paper paper, {
    String? currentUserId,
    String? currentUserName,
  }) async {
    return retry(
      () async {
        final oldSnapshot = await _papersRef.child(paper.id).get();
        List<String> oldAuthorIds = [];
        if (oldSnapshot.exists) {
          final oldData = safeCastMap(oldSnapshot.value);
          oldAuthorIds = List<String>.from(oldData['authorIds'] ?? []);
        }

        await _papersRef.child(paper.id).update(paper.toMap());

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
      },
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<void> deletePaper(String paperId) async {
    return retry(
      () async {
        final paperSnapshot = await _papersRef.child(paperId).get();
        final updates = <String, dynamic>{};

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

        if (paperSnapshot.exists) {
          final data = safeCastMap(paperSnapshot.value);
          final authorIds = safeCastStringList(data['authorIds']);
          for (final authorId in authorIds) {
            updates['papersByUser/$authorId/$paperId'] = null;
          }
        }

        updates['papers/$paperId'] = null;

        await _db.ref().update(updates);
      },
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<void> updateStatus(
    String paperId,
    PaperStatus status, {
    String? currentUserId,
    String? currentUserName,
    String? paperTitle,
  }) async {
    return retry(
      () async {
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
      },
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }

  Future<void> toggleFocusStatus(
    String paperId,
    bool isFocused, {
    String? currentUserId,
    String? currentUserName,
    String? paperTitle,
  }) async {
    return retry(
      () async {
        final now = DateTime.now();
        await _papersRef.child(paperId).update({
          'isFocused': isFocused,
          'focusedAt': isFocused ? now.toIso8601String() : null,
          'focusedByUserId': isFocused ? (currentUserId ?? '') : '',
          'updatedAt': now.toIso8601String(),
        });

        if (isFocused && _notificationRepository != null && currentUserId != null) {
          final paperSnapshot = await _papersRef.child(paperId).get();
          if (paperSnapshot.exists) {
            final data = safeCastMap(paperSnapshot.value);
            final authorIds = safeCastStringList(data['authorIds']);
            final title = paperTitle ?? (data['title'] as String? ?? 'Paper');

            await _notificationRepository.pushNotificationToMany(
              recipientIds: authorIds,
              senderId: currentUserId,
              senderName: currentUserName ?? '',
              title: '🎯 Paper Set to Focus Mode',
              message: '"$title" has been assigned to Team Focus Mode by ${currentUserName ?? 'a teammate'}',
              type: NotificationType.paperModified,
              relatedPaperId: paperId,
            );
          }
        }
      },
      maxAttempts: 3,
      retryIf: (e) => e is FirebaseException,
    );
  }
}

