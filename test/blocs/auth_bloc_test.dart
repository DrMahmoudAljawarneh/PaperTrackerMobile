import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test-uid';

  @override
  String? get displayName => 'Test User';

  @override
  String? get email => 'test@example.com';
}

void main() {
  late AuthRepository authRepository;
  late AuthBloc authBloc;
  late MockUser mockUser;

  setUp(() {
    authRepository = MockAuthRepository();
    mockUser = MockUser();
    authBloc = AuthBloc(authRepository: authRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when check finds logged-in user',
      build: () {
        when(() => authRepository.currentUser).thenReturn(mockUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when check finds no user',
      build: () {
        when(() => authRepository.currentUser).thenReturn(null);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on login success',
      build: () {
        when(() => authRepository.signInWithEmail(any(), any()))
            .thenAnswer((_) async => mockUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLoginRequested(
        email: 'test@example.com',
        password: 'password',
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on login failure',
      build: () {
        when(() => authRepository.signInWithEmail(any(), any()))
            .thenThrow(Exception('user-not-found'));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLoginRequested(
        email: 'missing@example.com',
        password: 'password',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on register success',
      build: () {
        when(() => authRepository.signUpWithEmail(any(), any(), any()))
            .thenAnswer((_) async => mockUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthRegisterRequested(
        email: 'new@example.com',
        password: 'password',
        displayName: 'New User',
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] on logout',
      build: () {
        when(() => authRepository.signOut()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'maps Firebase error codes to user-friendly messages',
      build: () {
        when(() => authRepository.signInWithEmail(any(), any()))
            .thenThrow(Exception('wrong-password'));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLoginRequested(
        email: 'test@example.com',
        password: 'wrong',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (e) => e.message,
          'error message',
          'Wrong password provided.',
        ),
      ],
    );
  });
}
