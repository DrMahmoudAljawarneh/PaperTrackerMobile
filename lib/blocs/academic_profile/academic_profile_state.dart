import 'package:equatable/equatable.dart';
import 'package:paper_tracker/models/orcid/orcid_record.dart';
import 'package:paper_tracker/models/orcid/orcid_work.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

abstract class AcademicProfileState extends Equatable {
  const AcademicProfileState();

  @override
  List<Object?> get props => [];
}

class AcademicProfileInitial extends AcademicProfileState {
  const AcademicProfileInitial();
}

class AcademicProfileLoading extends AcademicProfileState {
  const AcademicProfileLoading();
}

class AcademicProfileLoaded extends AcademicProfileState {
  final OrcidRecord record;
  final List<OrcidWork> filteredWorks;
  final bool isCacheRefresh;
  final DateTime lastUpdated;
  final OrcidToken? authToken;

  const AcademicProfileLoaded({
    required this.record,
    this.filteredWorks = const [],
    this.isCacheRefresh = false,
    required this.lastUpdated,
    this.authToken,
  });

  AcademicProfileLoaded copyWith({
    OrcidRecord? record,
    List<OrcidWork>? filteredWorks,
    bool? isCacheRefresh,
    DateTime? lastUpdated,
    OrcidToken? authToken,
  }) {
    return AcademicProfileLoaded(
      record: record ?? this.record,
      filteredWorks: filteredWorks ?? this.filteredWorks,
      isCacheRefresh: isCacheRefresh ?? this.isCacheRefresh,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      authToken: authToken ?? this.authToken,
    );
  }

  bool get isAuthorized => authToken != null && !authToken!.isExpired;

  @override
  List<Object?> get props => [
        record,
        filteredWorks,
        isCacheRefresh,
        lastUpdated,
        authToken,
      ];
}

class AcademicProfileError extends AcademicProfileState {
  final String message;
  final bool isOffline;

  const AcademicProfileError(this.message, {this.isOffline = false});

  @override
  List<Object?> get props => [message, isOffline];
}

class AcademicProfileNotAuthorized extends AcademicProfileState {
  final String? orcidId;
  final String? message;

  const AcademicProfileNotAuthorized({this.orcidId, this.message});

  @override
  List<Object?> get props => [orcidId, message];
}

class AcademicProfileAuthorizing extends AcademicProfileState {
  const AcademicProfileAuthorizing();
}

class AcademicProfileAuthorizationError extends AcademicProfileState {
  final String message;

  const AcademicProfileAuthorizationError(this.message);

  @override
  List<Object?> get props => [message];
}
