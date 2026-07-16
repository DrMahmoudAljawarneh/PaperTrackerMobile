import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/repositories/comment_repository.dart';
import 'package:paper_tracker/models/comment.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseDatabase mockDb;
  late CommentRepository repository;

  setUp(() {
    mockDb = MockFirebaseDatabase();
    repository = CommentRepository(db: mockDb);
  });

  group('CommentRepository', () {
    test('getCommentsForPaper returns stream of comments', () async {
      final commentsRef = MockDatabaseReference();
      final commentsQuery = MockDatabaseReference();

      when(() => mockDb.ref('comments')).thenReturn(commentsRef);
      when(() => commentsRef.orderByChild('paperId')).thenReturn(commentsQuery);
      when(() => commentsQuery.equalTo('paper1')).thenReturn(commentsQuery);

      final now = DateTime.now();
      final event = MockDatabaseEvent();
      final snapshot = MockDataSnapshot();
      when(() => event.snapshot).thenReturn(snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn({
        'comment1': {
          'paperId': 'paper1',
          'authorId': 'uid1',
          'authorName': 'User 1',
          'text': 'Great paper!',
          'createdAt': now.toIso8601String(),
        },
      });

      when(() => commentsQuery.onValue).thenAnswer((_) => Stream.value(event));

      final comments = await repository.getCommentsForPaper('paper1').first;

      expect(comments.length, 1);
      expect(comments.first.text, 'Great paper!');
    });

    test('addComment creates a comment', () async {
      final commentsRef = MockDatabaseReference();
      final newRef = MockDatabaseReference();

      when(() => mockDb.ref('comments')).thenReturn(commentsRef);
      when(() => commentsRef.push()).thenReturn(newRef);
      when(() => newRef.key).thenReturn('newCommentId');
      when(() => newRef.set(any())).thenAnswer((_) async {});

      final comment = Comment(
        id: '',
        paperId: 'paper1',
        authorId: 'uid1',
        authorName: 'User 1',
        text: 'Great paper!',
        createdAt: DateTime.now(),
      );

      final result = await repository.addComment(comment);
      expect(result, 'newCommentId');
    });

    test('deleteComment deletes', () async {
      final commentsRef = MockDatabaseReference();
      final commentRef = MockDatabaseReference();

      when(() => mockDb.ref('comments')).thenReturn(commentsRef);
      when(() => commentsRef.child('comment1')).thenReturn(commentRef);
      when(() => commentRef.remove()).thenAnswer((_) async {});

      await expectLater(
        repository.deleteComment('comment1'),
        completes,
      );
    });
  });
}
