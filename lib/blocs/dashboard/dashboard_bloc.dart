import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final PaperRepository _paperRepository;
  StreamSubscription<List<Paper>>? _papersSubscription;

  DashboardState? _lastCached;
  int _lastCacheKey = 0;

  DashboardBloc({
    required PaperRepository paperRepository,
  })  : _paperRepository = paperRepository,
        super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<_DashboardPapersUpdated>(_onPapersUpdated);
    on<_DashboardPapersError>(_onPapersError);
  }

  DashboardLoaded _compute(List<Paper> papers) {
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

    final distribution = <PaperStatus, int>{};
    for (final paper in papers) {
      distribution[paper.status] =
          (distribution[paper.status] ?? 0) + 1;
    }

    final recent = List<Paper>.from(papers)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final needsAttention = papers.where((p) {
      if (p.status == PaperStatus.rejected) return true;
      if (p.status == PaperStatus.revision) return true;
      if (p.deadline != null &&
          p.deadline!.isBefore(now) &&
          p.status != PaperStatus.published) {
        return true;
      }
      return false;
    }).toList();

    return DashboardLoaded(
      totalPapers: papers.length,
      inProgressPapers: inProgress.length,
      submittedPapers: submitted.length,
      publishedPapers: published.length,
      upcomingDeadlines: upcoming.take(5).toList(),
      recentPapers: recent.take(5).toList(),
      statusDistribution: distribution,
      papersNeedingAttention: needsAttention,
    );
  }

  void _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) {
    emit(DashboardLoading());
    _papersSubscription?.cancel();
    _papersSubscription = _paperRepository.getPapers(event.userId).listen(
      (papers) => add(_DashboardPapersUpdated(papers)),
      onError: (error) => add(_DashboardPapersError(error.toString())),
    );
  }

  void _onPapersUpdated(
    _DashboardPapersUpdated event,
    Emitter<DashboardState> emit,
  ) {
    final papers = event.papers;
    final key = Object.hashAll(papers.map((p) => p.updatedAt.millisecondsSinceEpoch));
    final cached = _lastCached;
    if (key == _lastCacheKey && cached is DashboardLoaded) {
      emit(cached);
      return;
    }
    _lastCacheKey = key;
    final result = _compute(papers);
    _lastCached = result;
    emit(result);
  }

  void _onPapersError(
    _DashboardPapersError event,
    Emitter<DashboardState> emit,
  ) {
    emit(DashboardError(event.message));
  }

  @override
  Future<void> close() {
    _papersSubscription?.cancel();
    return super.close();
  }
}

class _DashboardPapersUpdated extends DashboardEvent {
  final List<Paper> papers;
  const _DashboardPapersUpdated(this.papers);

  @override
  List<Object?> get props => papers;
}

class _DashboardPapersError extends DashboardEvent {
  final String message;
  const _DashboardPapersError(this.message);

  @override
  List<Object?> get props => [message];
}
