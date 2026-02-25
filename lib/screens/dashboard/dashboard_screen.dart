import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_bloc.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/widgets/deadline_countdown.dart';
import 'package:paper_tracker/widgets/empty_state.dart';
import 'package:paper_tracker/widgets/status_badge.dart';
import 'package:paper_tracker/services/update_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboard();
    // Check for app updates after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  void _loadDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<DashboardBloc>()
          .add(DashboardLoadRequested(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/papers/add'),
        child: const Icon(Icons.add_rounded),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: state.message,
            );
          }
          if (state is DashboardLoaded) {
            return _buildDashboard(state);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDashboard(DashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => _loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final name = authState is AuthAuthenticated
                    ? authState.user.displayName ?? 'Researcher'
                    : 'Researcher';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name 👋',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s your research overview',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          _buildStatsGrid(state),
          const SizedBox(height: 28),

          // Upcoming Deadlines
          _buildSectionHeader('Upcoming Deadlines', Icons.schedule),
          const SizedBox(height: 12),
          if (state.upcomingDeadlines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No upcoming deadlines 🎉',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...state.upcomingDeadlines.map(_buildDeadlineItem),
          const SizedBox(height: 28),

          // Recent Papers
          _buildSectionHeader('Recent Activity', Icons.history),
          const SizedBox(height: 12),
          if (state.recentPapers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No papers yet. Create your first one!',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...state.recentPapers.map(_buildRecentPaperItem),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _buildStatCard(
            'Total Papers',
            '${state.totalPapers}',
            Icons.article_rounded,
            AppTheme.primaryColor,
          ),
          _buildStatCard(
            'In Progress',
            '${state.inProgressPapers}',
            Icons.edit_note_rounded,
            AppTheme.accentColor,
          ),
          _buildStatCard(
            'Submitted',
            '${state.submittedPapers}',
            Icons.send_rounded,
            AppTheme.warningColor,
          ),
          _buildStatCard(
            'Published',
            '${state.publishedPapers}',
            Icons.celebration_rounded,
            AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(Paper paper) {
    return GestureDetector(
      onTap: () => context.push('/papers/${paper.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(paper.deadline!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DeadlineCountdown(deadline: paper.deadline!, compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPaperItem(Paper paper) {
    return GestureDetector(
      onTap: () => context.push('/papers/${paper.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated ${_timeAgo(paper.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: paper.status),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
