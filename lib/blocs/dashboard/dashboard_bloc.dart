import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';

class DashboardBloc extends HydratedBloc<DashboardEvent, DashboardState> {
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

  DashboardLoaded _compute(List<Paper> papers, String userId, String userName) {
    final now = DateTime.now();

    // Assigned focus papers: ONLY Team Focus Active OR Currently Assigned To You
    final assignedRaw = papers.where((p) =>
        p.isFocused ||
        (p.currentlyWith.isNotEmpty && p.currentlyWith == userName)).toList()
      ..sort((a, b) {
        // Manually focused papers take top priority
        if (a.isFocused != b.isFocused) {
          return a.isFocused ? -1 : 1;
        }

        if (a.isFocused && b.isFocused) {
          if (a.focusedAt != null && b.focusedAt != null) {
            return b.focusedAt!.compareTo(a.focusedAt!);
          }
        }

        // Priority order: high (0) < medium (1) < low (2)
        final pComp = a.priority.index.compareTo(b.priority.index);
        if (pComp != 0) return pComp;

        // If same priority, compare deadlines (nearest first)
        if (a.deadline != null && b.deadline != null) {
          return a.deadline!.compareTo(b.deadline!);
        } else if (a.deadline != null) {
          return -1;
        } else if (b.deadline != null) {
          return 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

    final assigned = assignedRaw.take(4).toList();

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
      myAssignedPapers: assigned,
    );
  }

  String _currentUserId = '';
  String _currentUserName = '';

  void _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) {
    _currentUserId = event.userId;
    _currentUserName = event.userName;
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
    final key = Object.hashAll([_currentUserId, ...papers.map((p) => p.updatedAt.millisecondsSinceEpoch)]);
    final cached = _lastCached;
    if (key == _lastCacheKey && cached is DashboardLoaded) {
      emit(cached);
      return;
    }
    _lastCacheKey = key;
    final newState = _compute(papers, _currentUserId, _currentUserName);
    _lastCached = newState;
    _lastCacheKey = key;
    emit(newState);
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

  @override
  DashboardState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['type'] == 'DashboardLoaded') {
        final data = json['data'] as Map<String, dynamic>;
        
        final distMap = (data['statusDistribution'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            PaperStatus.values.firstWhere((e) => e.name == k, orElse: () => PaperStatus.idea),
            v as int,
          )
        );

        return DashboardLoaded(
          totalPapers: data['totalPapers'] as int,
          inProgressPapers: data['inProgressPapers'] as int,
          submittedPapers: data['submittedPapers'] as int,
          publishedPapers: data['publishedPapers'] as int,
          upcomingDeadlines: (data['upcomingDeadlines'] as List)
              .map((p) => Paper.fromMap(p['id'], p as Map<String, dynamic>))
              .toList(),
          recentPapers: (data['recentPapers'] as List)
              .map((p) => Paper.fromMap(p['id'], p as Map<String, dynamic>))
              .toList(),
          statusDistribution: distMap,
          papersNeedingAttention: (data['papersNeedingAttention'] as List)
              .map((p) => Paper.fromMap(p['id'], p as Map<String, dynamic>))
              .toList(),
          myAssignedPapers: (data['myAssignedPapers'] as List)
              .map((p) => Paper.fromMap(p['id'], p as Map<String, dynamic>))
              .toList(),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(DashboardState state) {
    if (state is DashboardLoaded) {
      final distMap = state.statusDistribution.map(
        (k, v) => MapEntry(k.name, v),
      );

      return {
        'type': 'DashboardLoaded',
        'data': {
          'totalPapers': state.totalPapers,
          'inProgressPapers': state.inProgressPapers,
          'submittedPapers': state.submittedPapers,
          'publishedPapers': state.publishedPapers,
          'upcomingDeadlines': state.upcomingDeadlines.map((p) => p.toMap()..['id'] = p.id).toList(),
          'recentPapers': state.recentPapers.map((p) => p.toMap()..['id'] = p.id).toList(),
          'statusDistribution': distMap,
          'papersNeedingAttention': state.papersNeedingAttention.map((p) => p.toMap()..['id'] = p.id).toList(),
          'myAssignedPapers': state.myAssignedPapers.map((p) => p.toMap()..['id'] = p.id).toList(),
        }
      };
    }
    return null;
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
