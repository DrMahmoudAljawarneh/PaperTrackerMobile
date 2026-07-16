import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/notification/notification_bloc.dart';
import 'package:paper_tracker/blocs/notification/notification_event.dart';
import 'package:paper_tracker/blocs/notification/notification_state.dart';
import 'package:paper_tracker/services/notification_service.dart';
import 'package:paper_tracker/widgets/connectivity_banner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_event.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_state.dart';
import 'package:paper_tracker/repositories/academic_profile_repository.dart';
import 'package:paper_tracker/utils/back_handler.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  bool _notificationsStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPublications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPublications();
    }
  }

  void _checkPublications() {
    AcademicProfileRepository().checkForNewPublications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start listening for notifications once authenticated
    if (!_notificationsStarted) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context
            .read<NotificationBloc>()
            .add(NotificationsLoadRequested(authState.user.uid));
        _notificationsStarted = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(context)),
        actions: [
          // Export CSV icon (Only visible on Papers tab)
          if (GoRouterState.of(context).matchedLocation.startsWith('/papers'))
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export papers as CSV',
              onPressed: () => _exportPapers(context),
            ),
          // Refresh & Settings icons (Only visible on Academic Profile tab)
          if (GoRouterState.of(context).matchedLocation.startsWith('/academic-profile')) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Profile',
              onPressed: () {
                final state = context.read<AcademicProfileBloc>().state;
                String orcidId = '';
                if (state is AcademicProfileLoaded) {
                  orcidId = state.record.orcidId;
                } else if (state is AcademicProfileNotAuthorized) {
                  orcidId = state.orcidId ?? '';
                }
                context.read<AcademicProfileBloc>().add(AcademicProfileRefreshRequested(orcidId));
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Academic Settings',
              onPressed: () {
                final state = context.read<AcademicProfileBloc>().state;
                String orcidId = '';
                if (state is AcademicProfileLoaded) {
                  orcidId = state.record.orcidId;
                } else if (state is AcademicProfileNotAuthorized) {
                  orcidId = state.orcidId ?? '';
                }
                context.push('/academic-profile/settings', extra: orcidId);
              },
            ),
          ],
          // Profile icon
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
          // Notification bell with badge
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unreadCount =
                  state is NotificationsLoaded ? state.unreadCount : 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () {
                  NotificationService().initialize();
                  context.push('/notifications');
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: DoubleBackExit(
              message: 'Tap again to exit Paper Tracker',
              child: widget.child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article_rounded),
              label: 'Papers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Academic',
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/papers')) return 'Papers';
    if (location.startsWith('/chats') || location.startsWith('/chat')) {
      return 'Chats';
    }
    if (location.startsWith('/academic-profile')) return 'Academic Profile';
    return 'Dashboard';
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/papers')) return 1;
    if (location.startsWith('/chats') || location.startsWith('/chat')) return 2;
    if (location.startsWith('/academic-profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/papers');
        break;
      case 2:
        context.go('/chats');
        break;
      case 3:
        context.go('/academic-profile');
        break;
    }
  }

  void _exportPapers(BuildContext context) async {
    final paperState = context.read<PaperBloc>().state;
    if (paperState is! PapersLoaded || paperState.papers.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No papers available to export',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final papers = paperState.papers;
    final csvData = StringBuffer();
    // Headers
    csvData.writeln('ID,Title,Abstract,Status,Priority,Lead Author ID,Authors,Target Venue,Deadline,Tags,Currently With,Created At,Updated At');

    for (final paper in papers) {
      final title = paper.title.replaceAll('"', '""');
      final abstractText = paper.abstract_.replaceAll('"', '""');
      final status = paper.status.label;
      final priority = paper.priority.label;
      final leadAuthorId = paper.leadAuthorId;
      final authors = paper.authors.join('; ').replaceAll('"', '""');
      final venue = paper.targetVenue.replaceAll('"', '""');
      final deadline = paper.deadline != null ? paper.deadline!.toIso8601String() : 'N/A';
      final tags = paper.tags.join('; ').replaceAll('"', '""');
      final currentlyWith = paper.currentlyWith.replaceAll('"', '""');
      final createdAt = paper.createdAt.toIso8601String();
      final updatedAt = paper.updatedAt.toIso8601String();

      csvData.writeln('"${paper.id}","$title","$abstractText","$status","$priority","$leadAuthorId","$authors","$venue","$deadline","$tags","$currentlyWith","$createdAt","$updatedAt"');
    }

    final csvString = csvData.toString();

    if (kIsWeb) {
      try {
        final bytes = Uri.encodeComponent(csvString);
        final url = 'data:text/csv;charset=utf-8,$bytes';
        await launchUrl(Uri.parse(url));
        Fluttertoast.showToast(
          msg: 'CSV export downloaded',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Web export failed: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/papers_export.csv';
        final file = File(path);
        await file.writeAsString(csvString);
        Fluttertoast.showToast(
          msg: 'Exported successfully to Documents',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Failed to write CSV: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }
}


