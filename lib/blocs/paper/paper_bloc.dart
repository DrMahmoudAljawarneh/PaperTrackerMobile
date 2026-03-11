import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';

class PaperBloc extends Bloc<PaperEvent, PaperState> {
  final PaperRepository _paperRepository;
  StreamSubscription<List<Paper>>? _papersSubscription;

  PaperBloc({required PaperRepository paperRepository})
      : _paperRepository = paperRepository,
        super(PaperInitial()) {
    on<PapersLoadRequested>(_onLoadRequested);
    on<PapersUpdated>(_onPapersUpdated);
    on<PaperCreateRequested>(_onCreateRequested);
    on<PaperUpdateRequested>(_onUpdateRequested);
    on<PaperDeleteRequested>(_onDeleteRequested);
    on<PaperStatusChanged>(_onStatusChanged);
  }

  Future<void> _onLoadRequested(
    PapersLoadRequested event,
    Emitter<PaperState> emit,
  ) async {
    emit(PaperLoading());
    _papersSubscription?.cancel();
    _papersSubscription = _paperRepository.getPapers(event.userId).listen(
      (papers) => add(PapersUpdated(papers)),
      onError: (error) => add(PapersUpdated(const [])),
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
      await _paperRepository.updateStatus(
        event.paperId,
        event.newStatus,
        currentUserId: event.currentUserId,
        currentUserName: event.currentUserName,
        paperTitle: event.paperTitle,
      );
    } catch (e) {
      emit(PaperError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _papersSubscription?.cancel();
    return super.close();
  }
}
