import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/status_history_repository.dart';

class MockPaperRepository extends Mock implements PaperRepository {}

class MockStatusHistoryRepository extends Mock
    implements StatusHistoryRepository {}

class FakePaper extends Fake implements Paper {}

void main() {
  late PaperRepository paperRepository;
  late StatusHistoryRepository statusHistoryRepository;
  late PaperBloc paperBloc;

  setUpAll(() {
    registerFallbackValue(FakePaper());
  });

  setUp(() {
    paperRepository = MockPaperRepository();
    statusHistoryRepository = MockStatusHistoryRepository();
    paperBloc = PaperBloc(
      paperRepository: paperRepository,
      statusHistoryRepository: statusHistoryRepository,
    );
  });

  tearDown(() {
    paperBloc.close();
  });

  group('PaperBloc', () {
    test('initial state is PaperInitial', () {
      expect(paperBloc.state, isA<PaperInitial>());
    });

    blocTest<PaperBloc, PaperState>(
      'emits [PaperLoading, PapersLoaded] on successful load',
      build: () {
        final papers = [
          Paper(
            id: 'p1',
            title: 'Paper 1',
            leadAuthorId: 'uid1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        when(() => paperRepository.getPapers(any()))
            .thenAnswer((_) => Stream.value(papers));
        return paperBloc;
      },
      act: (bloc) => bloc.add(PapersLoadRequested('uid1')),
      expect: () => [
        isA<PaperLoading>(),
        isA<PapersLoaded>(),
      ],
    );

    blocTest<PaperBloc, PaperState>(
      'emits PaperError on create failure',
      build: () {
        when(() => paperRepository.createPaper(
              any(),
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
            )).thenThrow(Exception('Create failed'));
        return paperBloc;
      },
      act: (bloc) => bloc.add(PaperCreateRequested(
        Paper(
          id: '',
          title: 'New',
          leadAuthorId: 'uid1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        currentUserId: 'uid1',
        currentUserName: 'User',
      )),
      expect: () => [isA<PaperError>()],
    );

    blocTest<PaperBloc, PaperState>(
      'emits PaperError on update failure',
      build: () {
        when(() => paperRepository.updatePaper(
              any(),
              currentUserId: any(named: 'currentUserId'),
              currentUserName: any(named: 'currentUserName'),
            )).thenThrow(Exception('Update failed'));
        return paperBloc;
      },
      act: (bloc) => bloc.add(PaperUpdateRequested(
        Paper(
          id: 'p1',
          title: 'Updated',
          leadAuthorId: 'uid1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        currentUserId: 'uid1',
        currentUserName: 'User',
      )),
      expect: () => [isA<PaperError>()],
    );
  });
}
