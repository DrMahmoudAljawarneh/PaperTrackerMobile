import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/services/notification_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
      NotificationService().setupFcm(userId: user.uid);
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user =
          await _authRepository.signInWithEmail(event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
        NotificationService().setupFcm(userId: user.uid);
      } else {
        emit(const AuthError('Login failed'));
      }
    } catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmail(
        event.email,
        event.password,
        event.displayName,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
        NotificationService().setupFcm(userId: user.uid);
      } else {
        emit(const AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordReset(event.email);
      emit(AuthPasswordResetSent(email: event.email));
    } catch (e) {
      emit(AuthError(_mapFirebaseError(e)));
    }
  }

  String _mapFirebaseError(dynamic e) {
    if (e.toString().contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (e.toString().contains('wrong-password')) {
      return 'Wrong password provided.';
    } else if (e.toString().contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    } else if (e.toString().contains('weak-password')) {
      return 'The password is too weak.';
    } else if (e.toString().contains('invalid-email')) {
      return 'The email address is invalid.';
    }
    return e.toString();
  }
}
