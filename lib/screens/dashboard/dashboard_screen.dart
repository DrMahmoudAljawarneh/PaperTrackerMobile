import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_bloc.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_event.dart';
import 'package:paper_tracker/blocs/dashboard/dashboard_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/widgets/author_avatar_stack.dart';
import 'package:paper_tracker/widgets/deadline_countdown.dart';
import 'package:paper_tracker/widgets/empty_state.dart';
import 'package:paper_tracker/widgets/status_badge.dart';
import 'package:paper_tracker/services/update_service.dart';
import 'package:paper_tracker/utils/time_utils.dart';
import 'package:paper_tracker/widgets/shimmer_loading.dart';

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
            return _buildDashboardShimmer();
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
          return _buildDashboardShimmer();
        },
      ),
    );
  }

  Widget _buildDashboardShimmer() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        // Greeting shimmer
        const ShimmerLoading(width: 140, height: 20, borderRadius: 4),
        const SizedBox(height: 8),
        const ShimmerLoading(width: 220, height: 28, borderRadius: 4),
        const SizedBox(height: 24),

        // Grid of 4 stats cards shimmer
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            4,
            (index) => const ShimmerLoading(width: double.infinity, height: double.infinity, borderRadius: 16),
          ),
        ),
        const SizedBox(height: 32),

        // Section header shimmer
        const ShimmerLoading(width: 120, height: 20, borderRadius: 4),
        const SizedBox(height: 16),

        // Distribution bar shimmer
        const ShimmerLoading(width: double.infinity, height: 24, borderRadius: 12),
        const SizedBox(height: 32),

        // Section header shimmer
        const ShimmerLoading(width: 150, height: 20, borderRadius: 4),
        const SizedBox(height: 16),

        // Attention item list shimmer
        Column(
          children: List.generate(
            2,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerLoading(width: double.infinity, height: 72, borderRadius: 12),
            ),
          ),
        ),
      ],
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

          // My Assigned Focus Spotlight Section
          if (state.myAssignedPapers.isNotEmpty) ...[
            _buildSectionHeader('My Assigned Focus', Icons.stars_rounded),
            const SizedBox(height: 12),
            _buildAssignedFocusSection(state.myAssignedPapers),
            const SizedBox(height: 24),
          ],

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
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
                    ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
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
          GestureDetector(
            onTap: () => context.push('/papers'),
            child: _buildStatCard(
              'Total Papers',
              '${state.totalPapers}',
              Icons.article_rounded,
              AppTheme.primaryColor,
              const Color(0xFF1A237E),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(
              '/papers',
              extra: {
                PaperStatus.drafting,
                PaperStatus.writing,
                PaperStatus.internalReview,
                PaperStatus.revision,
              },
            ),
            child: _buildStatCard(
              'In Progress',
              '${state.inProgressPapers}',
              Icons.edit_note_rounded,
              AppTheme.accentColor,
              const Color(0xFF004D40),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(
              '/papers',
              extra: {PaperStatus.submitted, PaperStatus.underReview},
            ),
            child: _buildStatCard(
              'Submitted',
              '${state.submittedPapers}',
              Icons.send_rounded,
              AppTheme.warningColor,
              const Color(0xFF4A2800),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(
              '/papers',
              extra: {PaperStatus.published},
            ),
            child: _buildStatCard(
              'Published',
              '${state.publishedPapers}',
              Icons.celebration_rounded,
              AppTheme.successColor,
              const Color(0xFF1B5E20),
            ),
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
            bgTint.withValues(alpha: 0.6),
            Theme.of(context).cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
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
                  color: color.withValues(alpha: 0.15),
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
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedFocusSection(List<Paper> papers) {
    return Column(
      children: papers.map((paper) {
        Color priorityColor;
        switch (paper.priority) {
          case PaperPriority.high:
            priorityColor = AppTheme.errorColor;
            break;
          case PaperPriority.medium:
            priorityColor = AppTheme.warningColor;
            break;
          case PaperPriority.low:
            priorityColor = AppTheme.successColor;
            break;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: priorityColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: priorityColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, size: 12, color: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          '${paper.priority.label} Priority',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: paper.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                paper.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (paper.currentlyWith.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, size: 14, color: AppTheme.accentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Assigned Focus: ${paper.currentlyWith}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AuthorAvatarStack(
                      authors: paper.authors.isNotEmpty ? paper.authors : paper.authorIds,
                      activeTurnAuthor: paper.currentlyWith,
                      avatarSize: 26,
                    ),
                  ],
                ),
              ],
              if (paper.nextStep.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Next Action: ${paper.nextStep}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (paper.turnDueDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.hourglass_bottom_rounded, size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 4),
                    Text(
                      'Turn Due: ${DateFormat('MMM d, yyyy').format(paper.turnDueDate!)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.warningColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              if (paper.deadline != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.alarm_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Deadline: ${DateFormat('MMM d, yyyy').format(paper.deadline!)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/papers/${paper.id}'),
                      icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                      label: const Text('Focus Mode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showDelegateTurnDialog(context, paper),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Pass Turn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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
                    style: const TextStyle(
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.checklist_rounded,
                  label: 'All Tasks',
                  color: AppTheme.warningColor,
                  onTap: () => context.push('/tasks'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  color: AppTheme.successColor,
                  onTap: () => context.push('/calendar'),
                ),
              ),
            ],
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
          color: Theme.of(context).cardColor,
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
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
          color: Theme.of(context).cardColor,
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
                      color: Theme.of(context).textTheme.bodySmall?.color,
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

  String _timeAgo(DateTime dateTime) => timeAgo(dateTime);

  void _showDelegateTurnDialog(BuildContext context, Paper paper) {
    final authors = paper.authors.isNotEmpty ? paper.authors : paper.authorIds;
    String selectedAuthor = authors.isNotEmpty ? authors.first : '';
    final nextStepController = TextEditingController(text: paper.nextStep);
    DateTime? selectedTurnDueDate = paper.turnDueDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Pass Paper Turn'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transfer active writing/review turn for "${paper.title}":',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAuthor.isNotEmpty ? selectedAuthor : null,
                    decoration: InputDecoration(
                      labelText: 'Assigned Co-author',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: authors.map((author) {
                      return DropdownMenuItem(
                        value: author,
                        child: Text(author),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedAuthor = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nextStepController,
                    decoration: InputDecoration(
                      labelText: 'Next Action / Milestone',
                      hintText: 'e.g. Finish Section 4.2 tables in Overleaf',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedTurnDueDate ?? DateTime.now().add(const Duration(days: 3)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setDialogState(() => selectedTurnDueDate = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Turn Target Due Date (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(selectedTurnDueDate != null
                          ? DateFormat('MMM d, yyyy').format(selectedTurnDueDate!)
                          : 'No target date'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      final updatedPaper = paper.copyWith(
                        currentlyWith: selectedAuthor,
                        nextStep: nextStepController.text.trim(),
                        turnDueDate: selectedTurnDueDate,
                        updatedAt: DateTime.now(),
                      );
                      context.read<PaperBloc>().add(PaperUpdateRequested(
                        updatedPaper,
                        currentUserId: authState.user.uid,
                        currentUserName: authState.user.displayName,
                      ));
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Paper turn passed to $selectedAuthor 🎉'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  child: const Text('Transfer Turn'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

