import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_bloc.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';

class MockPaperRepository extends Mock implements PaperRepository {}

void main() {
  late PaperRepository paperRepository;
  late DashboardBloc dashboardBloc;

  setUp(() {
    paperRepository = MockPaperRepository();
    dashboardBloc = DashboardBloc(paperRepository: paperRepository);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(dashboardBloc.state, isA<DashboardInitial>());
    });

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] with computed stats',
      build: () {
        final now = DateTime.now();
        final papers = [
          Paper(
            id: 'p1',
            title: 'Published Paper',
            status: PaperStatus.published,
            leadAuthorId: 'uid1',
            createdAt: now,
            updatedAt: now,
          ),
          Paper(
            id: 'p2',
            title: 'Drafting Paper',
            status: PaperStatus.drafting,
            leadAuthorId: 'uid1',
            createdAt: now,
            updatedAt: now,
          ),
          Paper(
            id: 'p3',
            title: 'Rejected Paper',
            status: PaperStatus.rejected,
            leadAuthorId: 'uid1',
            createdAt: now,
            updatedAt: now,
          ),
          Paper(
            id: 'p4',
            title: 'Overdue Paper',
            status: PaperStatus.drafting,
            leadAuthorId: 'uid1',
            deadline: now.subtract(const Duration(days: 1)),
            createdAt: now,
            updatedAt: now,
          ),
        ];
        when(() => paperRepository.getPapers(any()))
            .thenAnswer((_) => Stream.value(papers));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(DashboardLoadRequested('uid1')),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.totalPapers,
          'totalPapers',
          4,
        ).having(
          (s) => s.publishedPapers,
          'publishedPapers',
          1,
        ).having(
          (s) => s.papersNeedingAttention.length,
          'needsAttention count',
          2, // rejected + overdue
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'handles empty paper list',
      build: () {
        when(() => paperRepository.getPapers(any()))
            .thenAnswer((_) => Stream.value([]));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(DashboardLoadRequested('uid1')),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.totalPapers,
          'totalPapers',
          0,
        ),
      ],
    );
  });
}
