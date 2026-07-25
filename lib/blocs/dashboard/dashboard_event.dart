import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  final String userId;
  final String userName;

  const DashboardLoadRequested(this.userId, this.userName);

  @override
  List<Object?> get props => [userId, userName];
}
