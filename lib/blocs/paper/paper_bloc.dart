import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/models/status_history_entry.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/status_history_repository.dart';

class PaperBloc extends HydratedBloc<PaperEvent, PaperState> {
  final PaperRepository _paperRepository;
  final StatusHistoryRepository _statusHistoryRepository;
  StreamSubscription<List<Paper>>? _papersSubscription;
  String? _loadedUserId;

  PaperBloc({
    required PaperRepository paperRepository,
    required StatusHistoryRepository statusHistoryRepository,
  })  : _paperRepository = paperRepository,
        _statusHistoryRepository = statusHistoryRepository,
        super(PaperInitial()) {
    on<PapersLoadRequested>(_onLoadRequested);
    on<PapersUpdated>(_onPapersUpdated);
    on<PaperCreateRequested>(_onCreateRequested);
    on<PaperUpdateRequested>(_onUpdateRequested);
    on<PaperDeleteRequested>(_onDeleteRequested);
    on<PaperStatusChanged>(_onStatusChanged);
    on<PaperFocusToggled>(_onFocusToggled);
    on<_PapersLoadError>(_onPapersLoadError);
  }

  Future<void> _onFocusToggled(
    PaperFocusToggled event,
    Emitter<PaperState> emit,
  ) async {
    try {
      await _paperRepository.toggleFocusStatus(
        event.paperId,
        event.isFocused,
        currentUserId: event.currentUserId,
        currentUserName: event.currentUserName,
        paperTitle: event.paperTitle,
      );
    } catch (e) {
      emit(PaperError(e.toString()));
    }
  }

  Future<void> _onLoadRequested(
    PapersLoadRequested event,
    Emitter<PaperState> emit,
  ) async {
    // Skip if already subscribed for this user
    if (_loadedUserId == event.userId && state is PapersLoaded) return;
    _loadedUserId = event.userId;
    emit(PaperLoading());
    _papersSubscription?.cancel();
    _papersSubscription = _paperRepository.getPapers(event.userId).listen(
      (papers) => add(PapersUpdated(papers)),
      onError: (error) => add(_PapersLoadError(error.toString())),
    );
  }

  void _onPapersUpdated(
    PapersUpdated event,
    Emitter<PaperState> emit,
  ) {
    emit(PapersLoaded(event.papers));
  }

  Future<void> _onCreateRequested(
    PaperCreateRequested event,
    Emitter<PaperState> emit,
  ) async {
    try {
      await _paperRepository.createPaper(
        event.paper,
        currentUserId: event.currentUserId,
        currentUserName: event.currentUserName,
      );
    } catch (e) {
      emit(PaperError(e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    PaperUpdateRequested event,
    Emitter<PaperState> emit,
  ) async {
    try {
      await _paperRepository.updatePaper(
        event.paper,
        currentUserId: event.currentUserId,
        currentUserName: event.currentUserName,
      );
    } catch (e) {
      emit(PaperError(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    PaperDeleteRequested event,
    Emitter<PaperState> emit,
  ) async {
    try {
      await _paperRepository.deletePaper(event.paperId);
    } catch (e) {
      emit(PaperError(e.toString()));
    }
  }

  Future<void> _onStatusChanged(
    PaperStatusChanged event,
    Emitter<PaperState> emit,
  ) async {
    try {
      // Find the old status from current state
      PaperStatus? oldStatus;
      final currentState = state;
      if (currentState is PapersLoaded) {
        final paper = currentState.papers
            .where((p) => p.id == event.paperId)
            .firstOrNull;
        oldStatus = paper?.status;
      }

      await _paperRepository.updateStatus(
        event.paperId,
        event.newStatus,
        currentUserId: event.currentUserId,
        currentUserName: event.currentUserName,
        paperTitle: event.paperTitle,
      );

      // Write status history entry
      if (oldStatus != null && oldStatus != event.newStatus) {
        await _statusHistoryRepository.addEntry(
          event.paperId,
          StatusHistoryEntry(
            id: '',
            oldStatus: oldStatus,
            newStatus: event.newStatus,
            changedByUserId: event.currentUserId,
            changedByUserName: event.currentUserName,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      emit(PaperError(e.toString()));
    }
  }

  void _onPapersLoadError(
    _PapersLoadError event,
    Emitter<PaperState> emit,
  ) {
    emit(PaperError(event.message));
  }

  @override
  Future<void> close() {
    _papersSubscription?.cancel();
    return super.close();
  }

  @override
  PaperState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['type'] == 'PapersLoaded') {
        final data = json['data'] as List;
        return PapersLoaded(
          data.map((p) => Paper.fromMap(p['id'], p as Map<String, dynamic>)).toList(),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(PaperState state) {
    if (state is PapersLoaded) {
      return {
        'type': 'PapersLoaded',
        'data': state.papers.map((p) => p.toMap()..['id'] = p.id).toList(),
      };
    }
    return null;
  }
}

class _PapersLoadError extends PaperEvent {
  final String message;
  const _PapersLoadError(this.message);

  @override
  List<Object?> get props => [message];
}
