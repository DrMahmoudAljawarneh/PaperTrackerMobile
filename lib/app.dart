import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/task/task_bloc.dart';
import 'package:paper_tracker/blocs/theme/theme_cubit.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/config/router.dart';
import 'package:paper_tracker/config/theme.dart';

import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/repositories/comment_repository.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/status_history_repository.dart';
import 'package:paper_tracker/repositories/task_repository.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';
import 'package:paper_tracker/repositories/academic_profile_repository.dart';
import 'package:paper_tracker/services/notification_service.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_bloc.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_bloc.dart';

class PaperTrackerApp extends StatelessWidget {
  const PaperTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create repositories
    final authRepository = AuthRepository();
    final notificationRepository = NotificationRepository();
    final paperRepository = PaperRepository(
      notificationRepository: notificationRepository,
    );
    final taskRepository = TaskRepository(
      notificationRepository: notificationRepository,
    );
    final commentRepository = CommentRepository(
      notificationRepository: notificationRepository,
    );
    final chatRepository = ChatRepository();
    final statusHistoryRepository = StatusHistoryRepository();
    final academicProfileRepository = AcademicProfileRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: paperRepository),
        RepositoryProvider.value(value: taskRepository),
        RepositoryProvider.value(value: commentRepository),
        RepositoryProvider.value(value: chatRepository),
        RepositoryProvider.value(value: notificationRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ThemeCubit()..load(),
          ),
          BlocProvider(
            create: (_) => AuthBloc(authRepository: authRepository)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) => PaperBloc(
              paperRepository: paperRepository,
              statusHistoryRepository: statusHistoryRepository,
            ),
          ),
          BlocProvider(
            create: (_) => TaskBloc(taskRepository: taskRepository),
          ),
          BlocProvider(
            create: (_) => DashboardBloc(
              paperRepository: paperRepository,
            ),
          ),
          BlocProvider(
            create: (_) => ChatListBloc(chatRepository: chatRepository),
          ),
          BlocProvider(
            create: (_) => ChatDetailBloc(chatRepository: chatRepository),
          ),
          BlocProvider(
            create: (_) => NotificationBloc(
              notificationRepository: notificationRepository,
              notificationService: NotificationService(),
            ),
          ),
          BlocProvider(
            create: (_) => AcademicProfileBloc(
              repository: academicProfileRepository,
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            final authBloc = context.read<AuthBloc>();
            final router = createRouter(authBloc);

            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                final accent = themeState.customAccentValue != null
                    ? Color(themeState.customAccentValue!)
                    : null;
                return MaterialApp.router(
                  title: 'Paper Tracker',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.getTheme(themeState.preset, Brightness.light,
                      customAccent: accent),
                  darkTheme: AppTheme.getTheme(themeState.preset, Brightness.dark,
                      customAccent: accent),
                  themeMode: themeState.mode,
                  routerConfig: router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
