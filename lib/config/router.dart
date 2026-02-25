import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/screens/auth/login_screen.dart';
import 'package:paper_tracker/screens/auth/register_screen.dart';
import 'package:paper_tracker/screens/dashboard/dashboard_screen.dart';
import 'package:paper_tracker/screens/papers/papers_list_screen.dart';
import 'package:paper_tracker/screens/papers/add_edit_paper_screen.dart';
import 'package:paper_tracker/screens/paper_detail/paper_detail_screen.dart';
import 'package:paper_tracker/screens/shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/papers',
            builder: (context, state) => const PapersListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/papers/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddEditPaperScreen(),
      ),
      GoRoute(
        path: '/papers/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final paperId = state.pathParameters['id']!;
          return AddEditPaperScreen(paperId: paperId);
        },
      ),
      GoRoute(
        path: '/papers/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final paperId = state.pathParameters['id']!;
          return PaperDetailScreen(paperId: paperId);
        },
      ),
    ],
  );
}

// Helper to convert Bloc stream into a Listenable for GoRouter
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
