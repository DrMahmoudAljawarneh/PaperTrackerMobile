import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/status_history_repository.dart';
import 'package:paper_tracker/screens/papers/papers_list_screen.dart';
import 'package:paper_tracker/widgets/shimmer_loading.dart';

class MockPaperRepository extends Mock implements PaperRepository {}

class MockStatusHistoryRepository extends Mock
    implements StatusHistoryRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

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

  group('PapersListScreen Widget Tests', () {
    Widget buildScreen({bool dispatchLoad = false}) {
      final paperRepository = MockPaperRepository();
      when(() => paperRepository.getPapers(any()))
          .thenAnswer((_) => Stream<List<Paper>>.empty());
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: MockAuthRepository()),
          ),
          BlocProvider(
            create: (_) => PaperBloc(
              paperRepository: paperRepository,
              statusHistoryRepository: MockStatusHistoryRepository(),
            )..add(dispatchLoad ? PapersLoadRequested('test-user') : PapersUpdated(const [])),
          ),
        ],
        child: const MaterialApp(
          home: PapersListScreen(),
        ),
      );
    }

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(buildScreen(dispatchLoad: true));
      await tester.pump();

      expect(find.byType(ShimmerLoading), findsWidgets);
    });

    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders FAB for adding papers', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });
  });
}
