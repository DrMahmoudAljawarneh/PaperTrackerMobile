import 'package:equatable/equatable.dart';
import 'package:paper_tracker/models/paper.dart';

abstract class PaperEvent extends Equatable {
  const PaperEvent();

  @override
  List<Object?> get props => [];
}

class PapersLoadRequested extends PaperEvent {
  final String userId;

  const PapersLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PaperCreateRequested extends PaperEvent {
  final Paper paper;

  const PaperCreateRequested(this.paper);

  @override
  List<Object?> get props => [paper];
}

class PaperUpdateRequested extends PaperEvent {
  final Paper paper;

  const PaperUpdateRequested(this.paper);

  @override
  List<Object?> get props => [paper];
}

class PaperDeleteRequested extends PaperEvent {
  final String paperId;

  const PaperDeleteRequested(this.paperId);

  @override
  List<Object?> get props => [paperId];
}

class PaperStatusChanged extends PaperEvent {
  final String paperId;
  final PaperStatus newStatus;

  const PaperStatusChanged({required this.paperId, required this.newStatus});

  @override
  List<Object?> get props => [paperId, newStatus];
}

class PapersUpdated extends PaperEvent {
  final List<Paper> papers;

  const PapersUpdated(this.papers);

  @override
  List<Object?> get props => [papers];
}
