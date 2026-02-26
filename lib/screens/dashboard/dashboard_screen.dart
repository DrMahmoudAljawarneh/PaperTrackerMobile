import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
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
          _buildGreeting(),
          const SizedBox(height: 24),

          // Stats Cards with gradient
          _buildStatsGrid(state),
          const SizedBox(height: 24),

          // Status Distribution Bar
          if (state.statusDistribution.isNotEmpty) ...[
            _buildSectionHeader('Paper Pipeline', Icons.analytics_outlined),
            const SizedBox(height: 12),
            _buildStatusDistribution(state),
            const SizedBox(height: 24),
          ],

          // Needs Attention
          if (state.papersNeedingAttention.isNotEmpty) ...[
            _buildSectionHeader('Needs Attention', Icons.warning_amber_rounded),
            const SizedBox(height: 12),
            ...state.papersNeedingAttention.take(3).map(_buildAttentionItem),
            const SizedBox(height: 24),
          ],

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),

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
          const SizedBox(height: 24),

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

  Widget _buildGreeting() {
    return Padding(
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
            const Color(0xFF1A237E),
          ),
          _buildStatCard(
            'In Progress',
            '${state.inProgressPapers}',
            Icons.edit_note_rounded,
            AppTheme.accentColor,
            const Color(0xFF004D40),
          ),
          _buildStatCard(
            'Submitted',
            '${state.submittedPapers}',
            Icons.send_rounded,
            AppTheme.warningColor,
            const Color(0xFF4A2800),
          ),
          _buildStatCard(
            'Published',
            '${state.publishedPapers}',
            Icons.celebration_rounded,
            AppTheme.successColor,
            const Color(0xFF1B5E20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, Color bgTint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bgTint.withOpacity(0.6),
            AppTheme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
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

  Widget _buildStatusDistribution(DashboardLoaded state) {
    final total = state.totalPapers;
    if (total == 0) return const SizedBox.shrink();

    final statusColors = <PaperStatus, Color>{
      PaperStatus.idea: const Color(0xFF90CAF9),
      PaperStatus.drafting: const Color(0xFF64B5F6),
      PaperStatus.writing: AppTheme.primaryColor,
      PaperStatus.internalReview: AppTheme.accentColor,
      PaperStatus.submitted: AppTheme.warningColor,
      PaperStatus.underReview: const Color(0xFFFFA726),
      PaperStatus.revision: const Color(0xFFFF7043),
      PaperStatus.published: AppTheme.successColor,
      PaperStatus.rejected: AppTheme.errorColor,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: state.statusDistribution.entries.map((entry) {
                  final fraction = entry.value / total;
                  return Expanded(
                    flex: (fraction * 1000).round().clamp(1, 1000),
                    child: Container(
                      color: statusColors[entry.key] ?? AppTheme.textMuted,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: state.statusDistribution.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColors[entry.key] ?? AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key.label} (${entry.value})',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionItem(Paper paper) {
    String reason;
    Color color;
    IconData icon;

    if (paper.status == PaperStatus.rejected) {
      reason = 'Rejected';
      color = AppTheme.errorColor;
      icon = Icons.cancel_outlined;
    } else if (paper.status == PaperStatus.revision) {
      reason = 'Needs Revision';
      color = const Color(0xFFFF7043);
      icon = Icons.edit_outlined;
    } else {
      reason = 'Overdue';
      color = AppTheme.warningColor;
      icon = Icons.timer_off_outlined;
    }

    return GestureDetector(
      onTap: () => context.push('/papers/${paper.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_rounded,
              label: 'New Paper',
              color: AppTheme.primaryColor,
              onTap: () => context.push('/papers/add'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.article_outlined,
              label: 'View All',
              color: AppTheme.accentColor,
              onTap: () => context.go('/papers'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
