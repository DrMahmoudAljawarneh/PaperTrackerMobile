import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/screens/auth/login_screen.dart';
import 'package:paper_tracker/screens/auth/register_screen.dart';
import 'package:paper_tracker/screens/auth/forgot_password_screen.dart';
import 'package:paper_tracker/screens/dashboard/dashboard_screen.dart';
import 'package:paper_tracker/screens/dashboard/calendar_screen.dart';
import 'package:paper_tracker/screens/tasks/global_tasks_screen.dart';
import 'package:paper_tracker/screens/papers/papers_list_screen.dart';
import 'package:paper_tracker/screens/papers/add_edit_paper_screen.dart';
import 'package:paper_tracker/screens/paper_detail/paper_detail_screen.dart';
import 'package:paper_tracker/screens/chat/chat_list_screen.dart';
import 'package:paper_tracker/screens/chat/chat_detail_screen.dart';
import 'package:paper_tracker/screens/notifications/notifications_screen.dart';
import 'package:paper_tracker/screens/profile/profile_screen.dart';
import 'package:paper_tracker/screens/shell_screen.dart';
import 'package:paper_tracker/screens/onboarding/onboarding_screen.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  // Cache onboarding flag in memory to avoid SharedPreferences disk reads on every redirect
  bool? onboardingCached;
  Future<bool> getOnboardingCached() async {
    if (onboardingCached != null) return onboardingCached!;
    final prefs = await SharedPreferences.getInstance();
    onboardingCached = prefs.getBool('onboarding_completed') ?? false;
    return onboardingCached!;
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) async {
      final onboardingCompleted = await getOnboardingCached();

      if (!onboardingCompleted) {
        if (state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }

      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute && state.matchedLocation != '/onboarding') {
        return '/login';
      }
      if (isAuthenticated && (isAuthRoute || state.matchedLocation == '/onboarding')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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
            builder: (context, state) => PapersListScreen(
              initialStatusFilter: state.extra as Set<PaperStatus>?,
            ),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatListScreen(),
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
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          return ChatDetailScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/tasks',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GlobalTasksScreen(),
      ),
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
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
