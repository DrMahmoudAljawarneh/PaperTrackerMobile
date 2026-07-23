import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/models/submission_entry.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/screens/paper_detail/comments_tab.dart';
import 'package:paper_tracker/screens/paper_detail/history_tab.dart';
import 'package:paper_tracker/screens/paper_detail/revisions_tab.dart';
import 'package:paper_tracker/screens/paper_detail/tasks_tab.dart';
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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDeletePaper(BuildContext context, String paperId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Paper'),
        content: const Text(
            'Are you sure you want to delete this paper? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<PaperBloc>().add(PaperDeleteRequested(paperId));
              context.pop();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperBloc, PaperState>(
      builder: (context, state) {
        final paper = state is PapersLoaded
            ? state.papers.where((p) => p.id == widget.paperId).firstOrNull
            : null;

        if (state is PaperInitial || (state is PaperLoading && paper == null)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
              IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                onPressed: () => _confirmDeletePaper(context, paper.id),
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
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Revisions'),
                    Tab(text: 'Tasks'),
                    Tab(text: 'Comments'),
                    Tab(text: 'History'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(paper),
                    RevisionsTab(paperId: widget.paperId),
                    TasksTab(paperId: widget.paperId),
                    CommentsTab(paperId: widget.paperId),
                    HistoryTab(paperId: widget.paperId),
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
    return Hero(
      tag: 'paper-card-${paper.id}',
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        return Material(
          color: Colors.transparent,
          child: toHeroContext.widget,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
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
                Icon(Icons.school_outlined,
                    size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    paper.targetVenue,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
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
                Icon(Icons.people_outline,
                    size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    paper.authors.join(', '),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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

          // Currently With & Turn Due Date
          if (paper.currentlyWith.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_pin_outlined,
                    size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Currently with: ${paper.currentlyWith}${paper.turnDueDate != null ? ' (Due: ${DateFormat('MMM d').format(paper.turnDueDate!)})' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Next Action Milestone
          if (paper.nextStep.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 16, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next Action: ${paper.nextStep}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Overleaf & PDF Action Row
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open Overleaf Link or show dialog to set link
                    if (paper.overleafUrl.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening Overleaf project: ${paper.overleafUrl}')),
                      );
                    } else {
                      _showEditOverleafDialog(paper);
                    }
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(paper.overleafUrl.isNotEmpty ? 'Open in Overleaf' : 'Link Overleaf Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080), // Overleaf Teal Accent
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),

          // Status transition
          const SizedBox(height: 16),
          _buildStatusTransition(paper),
        ],
      ),
    ),
  ),
);
}

  Widget _buildPriorityChip(PaperPriority priority) {
    final color = AppTheme.priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      context.read<PaperBloc>().add(PaperStatusChanged(
                            paperId: paper.id,
                            newStatus: status,
                            currentUserId: authState.user.uid,
                            currentUserName:
                                authState.user.displayName ?? '',
                            paperTitle: paper.title,
                          ));
                    }
                  },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? color : Theme.of(context).dividerColor,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Text(
                '${status.emoji} ${status.label}',
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? color : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmissionEntry(SubmissionEntry entry) {
    final outcomeColor = switch (entry.outcome) {
      SubmissionOutcome.accepted => AppTheme.successColor,
      SubmissionOutcome.rejected => AppTheme.errorColor,
      SubmissionOutcome.revision => const Color(0xFFFF7043),
      SubmissionOutcome.underReview => AppTheme.warningColor,
      SubmissionOutcome.withdrawn => AppTheme.textMuted,
      SubmissionOutcome.other => AppTheme.primaryColor,
    };
    final outcomeIcon = switch (entry.outcome) {
      SubmissionOutcome.accepted => Icons.check_circle,
      SubmissionOutcome.rejected => Icons.cancel,
      SubmissionOutcome.revision => Icons.edit_note,
      SubmissionOutcome.underReview => Icons.schedule,
      SubmissionOutcome.withdrawn => Icons.remove_circle_outline,
      SubmissionOutcome.other => Icons.help_outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outcomeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(outcomeIcon, size: 20, color: outcomeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.venueName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('MMM d, yyyy').format(entry.submissionDate)}  •  ${entry.outcome.name.toUpperCase()}',
                  style: TextStyle(fontSize: 12, color: outcomeColor),
                ),
                if (entry.reviewScores.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '⭐ Scores: ${entry.reviewScores}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry.notes!,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSubmissionDialog(Paper paper) async {
    final venueController = TextEditingController();
    final scoresController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    SubmissionOutcome selectedOutcome = SubmissionOutcome.underReview;
    final notesController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32, height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Add Submission', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: venueController,
                    decoration: const InputDecoration(
                      labelText: 'Venue Name',
                      hintText: 'e.g. NeurIPS 2025',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) setSheetState(() => selectedDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Submission Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SubmissionOutcome>(
                    value: selectedOutcome,
                    decoration: const InputDecoration(
                      labelText: 'Outcome',
                      border: OutlineInputBorder(),
                    ),
                    items: SubmissionOutcome.values.map((o) {
                      return DropdownMenuItem(
                        value: o,
                        child: Text(o.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedOutcome = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scoresController,
                    decoration: const InputDecoration(
                      labelText: 'Review Scores (Optional)',
                      hintText: 'e.g. 7/10, 6/10, Accept',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          if (venueController.text.trim().isEmpty) return;
                          Navigator.pop(sheetContext, true);
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      final newSubmission = SubmissionEntry(
        venueName: venueController.text.trim(),
        submissionDate: selectedDate,
        outcome: selectedOutcome,
        reviewScores: scoresController.text.trim(),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final updated = paper.copyWith(
          submissions: [...paper.submissions, newSubmission],
          updatedAt: DateTime.now(),
        );
        context.read<PaperBloc>().add(PaperUpdateRequested(
          updated,
          currentUserId: authState.user.uid,
          currentUserName: authState.user.displayName,
        ));
      }
    }

    venueController.dispose();
    scoresController.dispose();
    notesController.dispose();
  }

  Widget _buildOverviewTab(Paper paper) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Submission Log
        _buildSectionTitle('Submission Log'),
        const SizedBox(height: 8),
        ...paper.submissions.map((s) => _buildSubmissionEntry(s)),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: () => _showAddSubmissionDialog(paper),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Submission'),
          ),
        ),
        // Pre-Submission Co-Author Sign-off Checklist
        _buildSectionTitle('Pre-Submission Co-Author Sign-Off'),
        const SizedBox(height: 8),
        _buildSignoffChecklist(paper),
        const SizedBox(height: 24),

        // Private Notes
        _buildSectionTitle('Private Notes'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            key: ValueKey('notes_${paper.id}'),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: paper.notes,
                selection: TextSelection.collapsed(offset: paper.notes.length),
              ),
            ),
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add private notes about this paper...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onChanged: (value) {
              if (value != paper.notes) {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  context.read<PaperBloc>().add(PaperUpdateRequested(
                        paper.copyWith(
                          notes: value,
                          updatedAt: DateTime.now(),
                        ),
                        currentUserId: authState.user.uid,
                        currentUserName: authState.user.displayName,
                      ));
                }
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        // Abstract
        if (paper.abstract_.isNotEmpty) ...[
          _buildSectionTitle('Abstract'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paper.abstract_,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
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
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).colorScheme.onSurface,
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
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
          );
        }

        return Column(
          children: users
              .map((user) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                          child: Text(
                            (user.displayName.isNotEmpty
                                    ? user.displayName[0]
                                    : user.email[0])
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.secondary,
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
                                    color: Theme.of(context).textTheme.bodySmall?.color,
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

  Widget _buildSignoffChecklist(Paper paper) {
    final authors = paper.authors.isNotEmpty ? paper.authors : paper.authorIds;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: authors.map((author) {
          final isApproved = paper.authorApprovals[author] ?? false;

          return CheckboxListTile(
            title: Text(
              author,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isApproved ? FontWeight.bold : FontWeight.normal,
                color: isApproved ? AppTheme.successColor : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              isApproved ? 'Approved final Overleaf draft' : 'Pending review',
              style: TextStyle(fontSize: 11, color: isApproved ? AppTheme.successColor : AppTheme.warningColor),
            ),
            value: isApproved,
            activeColor: AppTheme.successColor,
            dense: true,
            onChanged: (val) {
              final newApprovals = Map<String, bool>.from(paper.authorApprovals);
              newApprovals[author] = val ?? false;

              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<PaperBloc>().add(PaperUpdateRequested(
                  paper.copyWith(
                    authorApprovals: newApprovals,
                    updatedAt: DateTime.now(),
                  ),
                  currentUserId: authState.user.uid,
                  currentUserName: authState.user.displayName,
                ));
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showEditOverleafDialog(Paper paper) {
    final urlController = TextEditingController(text: paper.overleafUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Overleaf Project'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Overleaf Project URL',
            hintText: 'https://www.overleaf.com/project/...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<PaperBloc>().add(PaperUpdateRequested(
                  paper.copyWith(
                    overleafUrl: urlController.text.trim(),
                    updatedAt: DateTime.now(),
                  ),
                  currentUserId: authState.user.uid,
                  currentUserName: authState.user.displayName,
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Link'),
          ),
        ],
      ),
    );
  }
}

