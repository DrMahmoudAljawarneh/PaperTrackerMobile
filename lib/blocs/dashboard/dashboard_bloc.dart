import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/task_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final PaperRepository _paperRepository;
  final TaskRepository _taskRepository;

  DashboardBloc({
    required PaperRepository paperRepository,
    required TaskRepository taskRepository,
  })  : _paperRepository = paperRepository,
        _taskRepository = taskRepository,
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

        // Upcoming deadlines
        final upcoming = papers
            .where((p) =>
                p.deadline != null &&
                p.deadline!.isAfter(now) &&
                p.status != PaperStatus.published &&
                p.status != PaperStatus.rejected)
            .toList()
          ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

        // Status counts
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

        // Status distribution
        final distribution = <PaperStatus, int>{};
        for (final paper in papers) {
          distribution[paper.status] =
              (distribution[paper.status] ?? 0) + 1;
        }

        // Recent papers
        final recent = List<Paper>.from(papers)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        // Papers needing attention (overdue, revision, rejected)
        final needsAttention = papers.where((p) {
          if (p.status == PaperStatus.rejected) return true;
          if (p.status == PaperStatus.revision) return true;
          if (p.deadline != null &&
              p.deadline!.isBefore(now) &&
              p.status != PaperStatus.published) return true;
          return false;
        }).toList();

        // Aggregate task stats across all papers
        int totalTasks = 0;
        int completedTasks = 0;

        return DashboardLoaded(
          totalPapers: papers.length,
          inProgressPapers: inProgress.length,
          submittedPapers: submitted.length,
          publishedPapers: published.length,
          upcomingDeadlines: upcoming.take(5).toList(),
          recentPapers: recent.take(5).toList(),
          statusDistribution: distribution,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          papersNeedingAttention: needsAttention,
        );
      },
      onError: (error, stackTrace) => DashboardError(error.toString()),
    );
  }
}

