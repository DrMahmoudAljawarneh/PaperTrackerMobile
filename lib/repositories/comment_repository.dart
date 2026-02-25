import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/comment.dart';

class CommentRepository {
  final FirebaseDatabase _db;

  CommentRepository({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

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

  /// Add a new comment to a paper
  Future<String> addComment(Comment comment) async {
    final newRef = _commentsRef.push();
    await newRef.set(comment.toMap());
    return newRef.key!;
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _commentsRef.child(commentId).remove();
  }
}
