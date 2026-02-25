import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/task/task_bloc.dart';
import 'package:paper_tracker/config/router.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/repositories/comment_repository.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/repositories/task_repository.dart';

class PaperTrackerApp extends StatelessWidget {
  const PaperTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create repositories
    final authRepository = AuthRepository();
    final paperRepository = PaperRepository();
    final taskRepository = TaskRepository();
    final commentRepository = CommentRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: paperRepository),
        RepositoryProvider.value(value: taskRepository),
        RepositoryProvider.value(value: commentRepository),
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
            create: (_) => DashboardBloc(paperRepository: paperRepository),
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
