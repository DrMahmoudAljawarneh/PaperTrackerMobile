import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/screens/auth/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _wrap(Widget child) {
  return BlocProvider<AuthBloc>(
    create: (_) => AuthBloc(authRepository: MockAuthRepository()),
    child: MaterialApp(home: child),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders navigation to register screen', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('renders forgot password link', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      expect(find.text('Forgot Password?'), findsOneWidget);
    });
  });
}
