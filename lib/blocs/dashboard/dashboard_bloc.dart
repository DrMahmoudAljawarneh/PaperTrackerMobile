import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final PaperRepository _paperRepository;

  DashboardBloc({required PaperRepository paperRepository})
      : _paperRepository = paperRepository,
        super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await emit.forEach<List<Paper>>(
      _paperRepository.getPapers(event.userId),
      onData: (papers) {
        final now = DateTime.now();
        final upcoming = papers
            .where((p) =>
                p.deadline != null &&
                p.deadline!.isAfter(now) &&
                p.status != PaperStatus.published &&
                p.status != PaperStatus.rejected)
            .toList()
          ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

        final inProgress = papers.where((p) =>
            p.status == PaperStatus.drafting ||
            p.status == PaperStatus.writing ||
            p.status == PaperStatus.internalReview ||
            p.status == PaperStatus.revision);

        final submitted = papers.where((p) =>
            p.status == PaperStatus.submitted ||
            p.status == PaperStatus.underReview);

        final published =
            papers.where((p) => p.status == PaperStatus.published);

        final recent = List<Paper>.from(papers)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return DashboardLoaded(
          totalPapers: papers.length,
          inProgressPapers: inProgress.length,
          submittedPapers: submitted.length,
          publishedPapers: published.length,
          upcomingDeadlines: upcoming.take(5).toList(),
          recentPapers: recent.take(5).toList(),
        );
      },
      onError: (error, stackTrace) => DashboardError(error.toString()),
    );
  }
}
