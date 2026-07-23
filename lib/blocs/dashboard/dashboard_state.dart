import 'package:equatable/equatable.dart';
import 'package:paper_tracker/models/paper.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalPapers;
  final int inProgressPapers;
  final int submittedPapers;
  final int publishedPapers;
  final List<Paper> upcomingDeadlines;
  final List<Paper> recentPapers;
  final Map<PaperStatus, int> statusDistribution;
  final List<Paper> papersNeedingAttention;
  final List<Paper> myAssignedPapers;

  const DashboardLoaded({
    required this.totalPapers,
    required this.inProgressPapers,
    required this.submittedPapers,
    required this.publishedPapers,
    required this.upcomingDeadlines,
    required this.recentPapers,
    this.statusDistribution = const {},
    this.papersNeedingAttention = const [],
    this.myAssignedPapers = const [],
  });

  @override
  List<Object?> get props => [
        totalPapers,
        inProgressPapers,
        submittedPapers,
        publishedPapers,
        upcomingDeadlines,
        recentPapers,
        statusDistribution,
        papersNeedingAttention,
        myAssignedPapers,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

