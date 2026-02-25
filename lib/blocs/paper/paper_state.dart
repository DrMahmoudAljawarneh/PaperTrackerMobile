import 'package:equatable/equatable.dart';
import 'package:paper_tracker/models/paper.dart';

abstract class PaperState extends Equatable {
  const PaperState();

  @override
  List<Object?> get props => [];
}

class PaperInitial extends PaperState {}

class PaperLoading extends PaperState {}

class PapersLoaded extends PaperState {
  final List<Paper> papers;

  const PapersLoaded(this.papers);

  @override
  List<Object?> get props => [papers];
}

class PaperError extends PaperState {
  final String message;

  const PaperError(this.message);

  @override
  List<Object?> get props => [message];
}
