import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/status_history_repository.dart';
import 'package:paper_tracker/screens/paper_detail/paper_detail_screen.dart';

class MockPaperRepository extends Mock implements PaperRepository {}

class MockStatusHistoryRepository extends Mock
    implements StatusHistoryRepository {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hydrated_test');
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(tempDir.path),
    );
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup; Hive may still hold a lock on Windows.
    }
    HydratedBloc.storage = null;
  });

  group('PaperDetailScreen Widget Tests', () {
    testWidgets('renders paper not found message when paper does not exist',
        (tester) async {
      final paperRepository = MockPaperRepository();
      when(() => paperRepository.streamPaper(any()))
          .thenAnswer((_) => Stream<Paper?>.value(null));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            RepositoryProvider<PaperRepository>.value(value: paperRepository),
            BlocProvider(
              create: (_) => PaperBloc(
                paperRepository: paperRepository,
                statusHistoryRepository: MockStatusHistoryRepository(),
              ),
            ),
          ],
          child: const MaterialApp(
            home: PaperDetailScreen(paperId: 'nonexistent'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paper not found'), findsOneWidget);
    });

    testWidgets('renders loading indicator while fetching paper', (tester) async {
      final paperRepository = MockPaperRepository();
      final streamController = StreamController<Paper?>();
      addTearDown(streamController.close);
      when(() => paperRepository.getPapers(any()))
          .thenAnswer((_) => Stream<List<Paper>>.empty());
      when(() => paperRepository.streamPaper(any()))
          .thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            RepositoryProvider<PaperRepository>.value(value: paperRepository),
            BlocProvider(
              create: (_) => PaperBloc(
                paperRepository: paperRepository,
                statusHistoryRepository: MockStatusHistoryRepository(),
              )..add(PapersLoadRequested('test-user')),
            ),
          ],
          child: const MaterialApp(
            home: PaperDetailScreen(paperId: 'test-paper-id'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
