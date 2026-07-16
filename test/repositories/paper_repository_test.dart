import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/models/paper.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseDatabase mockDb;
  late PaperRepository repository;

  setUp(() {
    mockDb = MockFirebaseDatabase();
    repository = PaperRepository(db: mockDb);
  });

  group('PaperRepository', () {
    test('getPapers returns stream of paper lists', () async {
      final papersByUserRef = MockDatabaseReference();
      final papersRef = MockDatabaseReference();
      final paper1Ref = MockDatabaseReference();
      final paper2Ref = MockDatabaseReference();

      when(() => mockDb.ref('papersByUser/uid1')).thenReturn(papersByUserRef);
      when(() => mockDb.ref('papers')).thenReturn(papersRef);
      when(() => papersRef.child('paper1')).thenReturn(paper1Ref);
      when(() => papersRef.child('paper2')).thenReturn(paper2Ref);

      final now = DateTime.now();
      final paper1Data = {
        'title': 'Paper 1',
        'abstract': 'Abstract 1',
        'status': 'idea',
        'priority': 'medium',
        'authorIds': ['uid1'],
        'authors': ['User 1'],
        'leadAuthorId': 'uid1',
        'targetVenue': '',
        'tags': <String>[],
        'currentlyWith': '',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      final paper2Data = {
        'title': 'Paper 2',
        'abstract': 'Abstract 2',
        'status': 'drafting',
        'priority': 'high',
        'authorIds': ['uid1'],
        'authors': ['User 1'],
        'leadAuthorId': 'uid1',
        'targetVenue': '',
        'tags': <String>[],
        'currentlyWith': '',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final paper1Snapshot = MockDataSnapshot();
      when(() => paper1Ref.get()).thenAnswer((_) async => paper1Snapshot);
      when(() => paper1Snapshot.exists).thenReturn(true);
      when(() => paper1Snapshot.key).thenReturn('paper1');
      when(() => paper1Snapshot.value).thenReturn(paper1Data);

      final paper2Snapshot = MockDataSnapshot();
      when(() => paper2Ref.get()).thenAnswer((_) async => paper2Snapshot);
      when(() => paper2Snapshot.exists).thenReturn(true);
      when(() => paper2Snapshot.key).thenReturn('paper2');
      when(() => paper2Snapshot.value).thenReturn(paper2Data);

      final indexSnapshot = MockDataSnapshot();
      when(() => indexSnapshot.exists).thenReturn(true);
      when(() => indexSnapshot.value).thenReturn({'paper1': true, 'paper2': true});

      final event = MockDatabaseEvent();
      when(() => event.snapshot).thenReturn(indexSnapshot);

      when(() => papersByUserRef.onValue).thenAnswer((_) => Stream.value(event));

      final papers = await repository.getPapers('uid1').first;

      expect(papers.length, 2);
      expect(papers.any((p) => p.id == 'paper1'), isTrue);
      expect(papers.any((p) => p.id == 'paper2'), isTrue);
    });

    test('getPaperById returns a paper when exists', () async {
      final papersRef = MockDatabaseReference();
      final paperRef = MockDatabaseReference();

      when(() => mockDb.ref('papers')).thenReturn(papersRef);
      when(() => papersRef.child('paper1')).thenReturn(paperRef);

      final snapshot = MockDataSnapshot();
      when(() => paperRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.key).thenReturn('paper1');
      when(() => snapshot.value).thenReturn({
        'title': 'Test Paper',
        'abstract': '',
        'status': 'idea',
        'priority': 'medium',
        'authorIds': ['uid1'],
        'authors': ['User 1'],
        'leadAuthorId': 'uid1',
        'targetVenue': '',
        'tags': <String>[],
        'currentlyWith': '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final paper = await repository.getPaperById('paper1');
      expect(paper, isNotNull);
      expect(paper!.id, 'paper1');
      expect(paper.title, 'Test Paper');
    });

    test('getPaperById returns null when not exists', () async {
      final papersRef = MockDatabaseReference();
      final paperRef = MockDatabaseReference();

      when(() => mockDb.ref('papers')).thenReturn(papersRef);
      when(() => papersRef.child('paper2')).thenReturn(paperRef);

      final snapshot = MockDataSnapshot();
      when(() => paperRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(false);

      final paper = await repository.getPaperById('paper2');
      expect(paper, isNull);
    });

    test('createPaper creates and returns a paper ID', () async {
      final papersRef = MockDatabaseReference();
      final newRef = MockDatabaseReference();
      final rootRef = MockDatabaseReference();

      when(() => mockDb.ref('papers')).thenReturn(papersRef);
      when(() => mockDb.ref()).thenReturn(rootRef);
      when(() => papersRef.push()).thenReturn(newRef);
      when(() => newRef.key).thenReturn('newPaperId');
      when(() => newRef.set(any())).thenAnswer((_) async {});
      when(() => rootRef.update(any())).thenAnswer((_) async {});

      final paper = Paper(
        id: '',
        title: 'New Paper',
        authorIds: ['uid1'],
        authors: ['User 1'],
        leadAuthorId: 'uid1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await repository.createPaper(paper);
      expect(result, 'newPaperId');
    });

    test('deletePaper runs without error', () async {
      final papersRef = MockDatabaseReference();
      final paperRef = MockDatabaseReference();
      final tasksRef = MockDatabaseReference();
      final tasksQuery = MockDatabaseReference();
      final commentsRef = MockDatabaseReference();
      final commentsQuery = MockDatabaseReference();
      final rootRef = MockDatabaseReference();

      when(() => mockDb.ref('papers')).thenReturn(papersRef);
      when(() => mockDb.ref('tasks')).thenReturn(tasksRef);
      when(() => mockDb.ref('comments')).thenReturn(commentsRef);
      when(() => mockDb.ref()).thenReturn(rootRef);
      when(() => papersRef.child('paper1')).thenReturn(paperRef);

      final paperSnapshot = MockDataSnapshot();
      when(() => paperRef.get()).thenAnswer((_) async => paperSnapshot);
      when(() => paperSnapshot.exists).thenReturn(true);
      when(() => paperSnapshot.value).thenReturn({
        'authorIds': ['uid1'],
        'title': 'Test',
      });

      when(() => tasksRef.orderByChild('paperId')).thenReturn(tasksQuery);
      when(() => tasksQuery.equalTo('paper1')).thenReturn(tasksQuery);
      final tasksSnapshot = MockDataSnapshot();
      when(() => tasksQuery.get()).thenAnswer((_) async => tasksSnapshot);
      when(() => tasksSnapshot.exists).thenReturn(false);

      when(() => commentsRef.orderByChild('paperId')).thenReturn(commentsQuery);
      when(() => commentsQuery.equalTo('paper1')).thenReturn(commentsQuery);
      final commentsSnapshot = MockDataSnapshot();
      when(() => commentsQuery.get()).thenAnswer((_) async => commentsSnapshot);
      when(() => commentsSnapshot.exists).thenReturn(false);

      when(() => rootRef.update(any())).thenAnswer((_) async {});

      await expectLater(
        repository.deletePaper('paper1'),
        completes,
      );
    });

    test('updateStatus runs without error', () async {
      final papersRef = MockDatabaseReference();
      final paperRef = MockDatabaseReference();

      when(() => mockDb.ref('papers')).thenReturn(papersRef);
      when(() => papersRef.child('paper1')).thenReturn(paperRef);

      final snapshot = MockDataSnapshot();
      when(() => paperRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn({'authorIds': ['uid1']});
      when(() => paperRef.update(any())).thenAnswer((_) async {});

      await expectLater(
        repository.updateStatus('paper1', PaperStatus.drafting),
        completes,
      );
    });
  });
}
