import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/comment.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';

class CommentRepository {
  final FirebaseDatabase _db;
  final NotificationRepository? _notificationRepository;

  CommentRepository({
    FirebaseDatabase? db,
    NotificationRepository? notificationRepository,
  })  : _db = db ?? FirebaseDatabase.instance,
        _notificationRepository = notificationRepository;

  DatabaseReference get _commentsRef => _db.ref('comments');

  /// Stream comments for a specific paper, ordered by creation time
  Stream<List<Comment>> getCommentsForPaper(String paperId) {
    return _commentsRef
        .orderByChild('paperId')
        .equalTo(paperId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <Comment>[];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final comments = data.entries
          .map((e) =>
              Comment.fromMap(e.key, Map<String, dynamic>.from(e.value)))
          .toList();
      // Sort by createdAt ascending (client-side)
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    });
  }

  /// Add a new comment to a paper and notify collaborators.
  /// Pass [paperAuthorIds] and [paperTitle] to send notifications.
  Future<String> addComment(
    Comment comment, {
    List<String> paperAuthorIds = const [],
    String paperTitle = '',
  }) async {
    final newRef = _commentsRef.push();
    await newRef.set(comment.toMap());

    // Notify all collaborators except the comment author
    if (_notificationRepository != null && paperAuthorIds.isNotEmpty) {
      await _notificationRepository!.pushNotificationToMany(
        recipientIds: paperAuthorIds,
        senderId: comment.authorId,
        senderName: comment.authorName,
        title: 'New Comment',
        message: paperTitle.isNotEmpty
            ? '${comment.authorName} commented on "$paperTitle"'
            : '${comment.authorName} left a comment',
        type: NotificationType.commentAdded,
        relatedPaperId: comment.paperId,
      );
    }

    return newRef.key!;
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _commentsRef.child(commentId).remove();
  }
}

