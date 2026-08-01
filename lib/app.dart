import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_bloc.dart';
import 'package:paper_tracker/blocs/theme/theme_cubit.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/task/task_bloc.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_bloc.dart';
import 'package:paper_tracker/blocs/chat_detail/chat_detail_bloc.dart';
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

class PaperTrackerApp extends StatelessWidget {
  const PaperTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => NotificationRepository()),
        RepositoryProvider(create: (context) => PaperRepository(
              notificationRepository: context.read<NotificationRepository>(),
            )),
        RepositoryProvider(create: (context) => TaskRepository(
              notificationRepository: context.read<NotificationRepository>(),
            )),
        RepositoryProvider(create: (context) => CommentRepository(
              notificationRepository: context.read<NotificationRepository>(),
            )),
        RepositoryProvider(create: (context) => ChatRepository()),
        RepositoryProvider(create: (context) => StatusHistoryRepository()),
        RepositoryProvider(create: (context) => AcademicProfileRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ThemeCubit()..load(),
          ),
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              paperRepository: context.read<PaperRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => NotificationBloc(
              notificationRepository:
                  context.read<NotificationRepository>(),
              notificationService: NotificationService(),
            ),
          ),
          BlocProvider(
            create: (context) => AcademicProfileBloc(
              repository: context.read<AcademicProfileRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => PaperBloc(
              paperRepository: context.read<PaperRepository>(),
              statusHistoryRepository:
                  context.read<StatusHistoryRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => TaskBloc(
              taskRepository: context.read<TaskRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ChatListBloc(
              chatRepository: context.read<ChatRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ChatDetailBloc(
              chatRepository: context.read<ChatRepository>(),
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
