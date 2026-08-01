import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/config/router.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/screens/auth/login_screen.dart';
import 'package:paper_tracker/screens/dashboard/dashboard_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Auth Flow Integration Tests', () {
    testWidgets('login screen renders and dispatches login request on submit',
        (tester) async {
      final authRepository = MockAuthRepository();
      when(() => authRepository.signInWithEmail(any(), any()))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepository),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      verify(() => authRepository.signInWithEmail(
            'test@example.com',
            'password123',
          )).called(1);
    });

    testWidgets('unauthenticated user is redirected to login', (tester) async {
      final authRepository = MockAuthRepository();
      when(() => authRepository.currentUser).thenReturn(null);

      final authBloc = AuthBloc(authRepository: authRepository);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>(
          create: (_) => authBloc,
          child: MaterialApp.router(
            routerConfig: createRouter(authBloc),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });
  });
}
