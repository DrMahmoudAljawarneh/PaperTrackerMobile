import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';
import 'package:paper_tracker/screens/paper_detail/tasks_tab.dart';
import 'package:paper_tracker/screens/paper_detail/comments_tab.dart';
import 'package:paper_tracker/widgets/deadline_countdown.dart';
import 'package:paper_tracker/widgets/status_badge.dart';

class PaperDetailScreen extends StatefulWidget {
  final String paperId;

  const PaperDetailScreen({super.key, required this.paperId});

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Paper?>(
      stream: context.read<PaperRepository>().streamPaper(widget.paperId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final paper = snapshot.data;
        if (paper == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Paper not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Paper Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/papers/edit/${paper.id}'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Paper header
              _buildHeader(paper),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Tasks'),
                    Tab(text: 'Comments'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(paper),
                    TasksTab(paperId: widget.paperId),
                    CommentsTab(paperId: widget.paperId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Paper paper) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Priority row
          Row(
            children: [
              StatusBadge(status: paper.status, large: true),
              const Spacer(),
              _buildPriorityChip(paper.priority),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            paper.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          // Venue
          if (paper.targetVenue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  paper.targetVenue,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],

          // Authors
          if (paper.authors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    paper.authors.join(', '),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Deadline
          if (paper.deadline != null) ...[
            const SizedBox(height: 10),
            DeadlineCountdown(deadline: paper.deadline!),
          ],

          // Status transition
          const SizedBox(height: 16),
          _buildStatusTransition(paper),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(PaperPriority priority) {
    final color = AppTheme.priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusTransition(Paper paper) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PaperStatus.values.map((status) {
          final isActive = status == paper.status;
          final color = AppTheme.statusColor(status);
          return GestureDetector(
            onTap: isActive
                ? null
                : () {
                    context.read<PaperBloc>().add(PaperStatusChanged(
                          paperId: paper.id,
                          newStatus: status,
                        ));
                  },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? color : AppTheme.dividerColor,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Text(
                '${status.emoji} ${status.label}',
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? color : AppTheme.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab(Paper paper) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Abstract
        if (paper.abstract_.isNotEmpty) ...[
          _buildSectionTitle('Abstract'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paper.abstract_,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Tags
        if (paper.tags.isNotEmpty) ...[
          _buildSectionTitle('Tags'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: paper.tags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Collaborators
        if (paper.authorIds.length > 1) ...[
          _buildSectionTitle('Collaborators'),
          const SizedBox(height: 8),
          _buildCollaboratorsList(paper),
          const SizedBox(height: 24),
        ],

        // Details
        _buildSectionTitle('Details'),
        const SizedBox(height: 8),
        _buildDetailRow(
            'Authors',
            paper.authors.isNotEmpty
                ? paper.authors.join(', ')
                : '${paper.authorIds.length} contributor(s)'),
        _buildDetailRow(
            'Created', DateFormat('MMM d, yyyy').format(paper.createdAt)),
        _buildDetailRow(
            'Updated', DateFormat('MMM d, yyyy').format(paper.updatedAt)),
        if (paper.deadline != null)
          _buildDetailRow(
              'Deadline', DateFormat('MMM d, yyyy').format(paper.deadline!)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorsList(Paper paper) {
    final authRepo = context.read<AuthRepository>();
    // Exclude the lead author, show only collaborators
    final collabIds =
        paper.authorIds.where((id) => id != paper.leadAuthorId).toList();

    return FutureBuilder<List<UserModel?>>(
      future: Future.wait(collabIds.map((id) => authRepo.getUserById(id))),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final users =
            (snapshot.data ?? []).whereType<UserModel>().toList();

        if (users.isEmpty) {
          return Text(
            'No collaborators',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          );
        }

        return Column(
          children: users
              .map((user) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppTheme.accentColor.withValues(alpha: 0.2),
                          child: Text(
                            (user.displayName.isNotEmpty
                                    ? user.displayName[0]
                                    : user.email[0])
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName
                                    : user.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (user.displayName.isNotEmpty)
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
