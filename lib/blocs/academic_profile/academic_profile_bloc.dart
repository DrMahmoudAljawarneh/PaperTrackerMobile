import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_event.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_state.dart';
import 'package:paper_tracker/repositories/academic_profile_repository.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

class AcademicProfileBloc
    extends Bloc<AcademicProfileEvent, AcademicProfileState> {
  final AcademicProfileRepository _repository;

  AcademicProfileBloc({required AcademicProfileRepository repository})
      : _repository = repository,
        super(const AcademicProfileInitial()) {
    on<AcademicProfileLoadRequested>(_onLoadRequested);
    on<AcademicProfileRefreshRequested>(_onRefreshRequested);
    on<AcademicProfileClearCache>(_onClearCache);
    on<AcademicProfileUpdateOrcidId>(_onUpdateOrcidId);
    on<OrcidDisconnectRequested>(_onDisconnect);
    on<CheckOrcidAuthorization>(_onCheckAuthorization);
  }

  Future<void> _onLoadRequested(
    AcademicProfileLoadRequested event,
    Emitter<AcademicProfileState> emit,
  ) async {
    emit(const AcademicProfileLoading());

    try {
      final token = await OrcidAuthService.getStoredToken();
      final orcidId = event.orcidId.isNotEmpty ? event.orcidId : (token?.orcidId ?? '');

      final hasAuth = await OrcidAuthService.hasValidToken();
      print('DEBUG BLOC: _onLoadRequested: hasAuth=$hasAuth, orcidId=$orcidId');
      if (!hasAuth || orcidId.isEmpty) {
        emit(AcademicProfileNotAuthorized(
          orcidId: orcidId,
          message: 'Connect your ORCID account to view your full profile.',
        ));
        return;
      }

      final record = event.forceRefresh
          ? await _repository.fetchProfileFresh(orcidId)
          : await _repository.fetchProfile(orcidId);

      emit(AcademicProfileLoaded(
        record: record,
        lastUpdated: DateTime.now(),
        filteredWorks: record.works,
        authToken: token,
      ));

      _fetchSupplementaryMetrics(orcidId);
    } on DioException catch (e) {
      print('DEBUG BLOC: DioException in _onLoadRequested: $e');
      _handleError(emit, e);
    } catch (e, s) {
      print('DEBUG BLOC: Exception in _onLoadRequested: $e');
      print(s);
      emit(AcademicProfileError(
        e.toString(),
        isOffline: e.toString().contains('SocketException'),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    AcademicProfileRefreshRequested event,
    Emitter<AcademicProfileState> emit,
  ) async {
    if (state is AcademicProfileLoaded) {
      emit((state as AcademicProfileLoaded).copyWith(isCacheRefresh: true));
    }

    try {
      final token = await OrcidAuthService.getStoredToken();
      final orcidId = event.orcidId.isNotEmpty ? event.orcidId : (token?.orcidId ?? '');

      final hasAuth = await OrcidAuthService.hasValidToken();
      print('DEBUG BLOC: _onRefreshRequested: hasAuth=$hasAuth, orcidId=$orcidId');
      if (!hasAuth || orcidId.isEmpty) {
        emit(AcademicProfileNotAuthorized(
          orcidId: orcidId,
          message: 'ORCID authorization expired. Please reconnect.',
        ));
        return;
      }

      final record = await _repository.fetchProfileFresh(orcidId);
      emit(AcademicProfileLoaded(
        record: record,
        lastUpdated: DateTime.now(),
        filteredWorks: record.works,
        authToken: token,
      ));

      _fetchSupplementaryMetrics(orcidId);
    } on DioException catch (e) {
      print('DEBUG BLOC: DioException in _onRefreshRequested: $e');
      _handleError(emit, e);
    } catch (e, s) {
      print('DEBUG BLOC: Exception in _onRefreshRequested: $e');
      print(s);
      emit(AcademicProfileError(
        e.toString(),
        isOffline: e.toString().contains('SocketException'),
      ));
    }
  }

  Future<void> _onClearCache(
    AcademicProfileClearCache event,
    Emitter<AcademicProfileState> emit,
  ) async {
    await _repository.clearAllCache();
    emit(const AcademicProfileInitial());
  }

  void _onUpdateOrcidId(
    AcademicProfileUpdateOrcidId event,
    Emitter<AcademicProfileState> emit,
  ) {
    add(AcademicProfileLoadRequested(event.orcidId));
  }

  Future<void> _onDisconnect(
    OrcidDisconnectRequested event,
    Emitter<AcademicProfileState> emit,
  ) async {
    await OrcidAuthService.disconnect();
    await _repository.clearAllCache();
    emit(const AcademicProfileInitial());
  }

  Future<void> _onCheckAuthorization(
    CheckOrcidAuthorization event,
    Emitter<AcademicProfileState> emit,
  ) async {
    final hasAuth = await OrcidAuthService.hasValidToken();
    print('DEBUG BLOC: _onCheckAuthorization: hasAuth=$hasAuth');
    if (!hasAuth) {
      final token = await OrcidAuthService.getStoredToken();
      emit(AcademicProfileNotAuthorized(
        orcidId: token?.orcidId,
        message: 'Your ORCID session has expired. Please authorize again.',
      ));
    }
  }

  Future<void> _fetchSupplementaryMetrics(String orcidId) async {}

  void _handleError(Emitter<AcademicProfileState> emit, DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        emit(const AcademicProfileError('Connection timed out. Please try again.'));
        break;
      case DioExceptionType.connectionError:
        emit(const AcademicProfileError(
          'No internet connection. Please check your network.',
          isOffline: true,
        ));
        break;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        if (status == 401 || status == 403) {
          emit(const AcademicProfileError(
            'Authorization expired or invalid. Please re-connect your ORCID account.',
          ));
        } else if (status == 404) {
          emit(const AcademicProfileError(
            'No ORCID profile found for this iD.',
          ));
        } else if (status == 429) {
          emit(const AcademicProfileError(
            'Too many requests. Please try again later.',
          ));
        } else {
          emit(AcademicProfileError('Server error (HTTP $status). Please try again.'));
        }
        break;
      default:
        emit(AcademicProfileError(
          e.message ?? 'An unexpected error occurred.',
        ));
    }
  }
}
