import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/task/task_bloc.dart';
import 'package:paper_tracker/config/router.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/repositories/comment_repository.dart';
import 'package:paper_tracker/repositories/notification_repository.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/task_repository.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';
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
            create: (_) => AuthBloc(authRepository: authRepository)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) => PaperBloc(paperRepository: paperRepository),
          ),
          BlocProvider(
            create: (_) => TaskBloc(taskRepository: taskRepository),
          ),
          BlocProvider(
            create: (_) => DashboardBloc(
              paperRepository: paperRepository,
              taskRepository: taskRepository,
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
        ],
        child: Builder(
          builder: (context) {
            final authBloc = context.read<AuthBloc>();
            final router = createRouter(authBloc);

            return MaterialApp.router(
              title: 'Paper Tracker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
