import 'package:equatable/equatable.dart';

abstract class AcademicProfileEvent extends Equatable {
  const AcademicProfileEvent();

  @override
  List<Object?> get props => [];
}

class AcademicProfileLoadRequested extends AcademicProfileEvent {
  final String orcidId;
  final bool forceRefresh;

  const AcademicProfileLoadRequested(
    this.orcidId, {
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [orcidId, forceRefresh];
}

class AcademicProfileRefreshRequested extends AcademicProfileEvent {
  final String orcidId;

  const AcademicProfileRefreshRequested(this.orcidId);

  @override
  List<Object?> get props => [orcidId];
}

class AcademicProfileClearCache extends AcademicProfileEvent {
  const AcademicProfileClearCache();
}

class AcademicProfileUpdateOrcidId extends AcademicProfileEvent {
  final String orcidId;

  const AcademicProfileUpdateOrcidId(this.orcidId);

  @override
  List<Object?> get props => [orcidId];
}

class OrcidAuthorizeRequested extends AcademicProfileEvent {
  final String? orcidId;

  const OrcidAuthorizeRequested({this.orcidId});
}

class OrcidDisconnectRequested extends AcademicProfileEvent {
  const OrcidDisconnectRequested();
}

class CheckOrcidAuthorization extends AcademicProfileEvent {
  const CheckOrcidAuthorization();
}
