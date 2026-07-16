import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/blocs/task/task_bloc.dart';
import 'package:paper_tracker/blocs/task/task_event.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/models/paper_task.dart';
import 'package:paper_tracker/repositories/task_repository.dart';
import 'package:paper_tracker/widgets/empty_state.dart';
import 'package:paper_tracker/widgets/shimmer_loading.dart';

enum _TaskFilter { all, pending, completed, overdue }

class GlobalTasksScreen extends StatefulWidget {
  const GlobalTasksScreen({super.key});

  @override
  State<GlobalTasksScreen> createState() => _GlobalTasksScreenState();
}

class _GlobalTasksScreenState extends State<GlobalTasksScreen> {
  List<PaperTask> _allTasks = [];
  List<Paper> _papers = [];
  bool _loading = true;
  _TaskFilter _selectedFilter = _TaskFilter.all;
  bool _sortByDueDate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final paperState = context.read<PaperBloc>().state;
    if (paperState is! PapersLoaded) {
      setState(() => _loading = false);
      return;
    }

    final papers = paperState.papers;
    final paperIds = papers.map((p) => p.id).toList();

    try {
      final repo = context.read<TaskRepository>();
      final tasks = await repo.getTasksForPapers(paperIds);
      if (!mounted) return;
      setState(() {
        _papers = papers;
        _allTasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _paperTitle(String paperId) {
    return _papers
        .where((p) => p.id == paperId)
        .map((p) => p.title)
        .firstOrNull ?? 'Unknown Paper';
  }

  Paper? _paperById(String paperId) {
    return _papers.where((p) => p.id == paperId).firstOrNull;
  }

  List<PaperTask> get _filteredTasks {
    var tasks = List<PaperTask>.from(_allTasks);

    switch (_selectedFilter) {
      case _TaskFilter.pending:
        tasks = tasks.where((t) => !t.completed).toList();
        break;
      case _TaskFilter.completed:
        tasks = tasks.where((t) => t.completed).toList();
        break;
      case _TaskFilter.overdue:
        final now = DateTime.now();
        tasks = tasks
            .where((t) => !t.completed && t.dueDate != null && t.dueDate!.isBefore(now))
            .toList();
        break;
      case _TaskFilter.all:
        break;
    }

    if (_sortByDueDate) {
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          IconButton(
            icon: Icon(_sortByDueDate ? Icons.calendar_view_day : Icons.access_time),
            tooltip: _sortByDueDate ? 'Sort by created date' : 'Sort by due date',
            onPressed: () => setState(() => _sortByDueDate = !_sortByDueDate),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: _TaskFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          String label;
          switch (filter) {
            case _TaskFilter.all:
              label = 'All';
              break;
            case _TaskFilter.pending:
              label = 'Pending';
              break;
            case _TaskFilter.completed:
              label = 'Completed';
              break;
            case _TaskFilter.overdue:
              label = 'Overdue';
              break;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoading(width: double.infinity, height: 72, borderRadius: 12),
        ),
      );
    }

    final tasks = _filteredTasks;

    if (tasks.isEmpty) {
      return EmptyState(
        icon: Icons.checklist_rounded,
        title: 'No tasks found',
        subtitle: _allTasks.isEmpty
            ? 'Create tasks on your papers to see them here'
            : 'Try a different filter',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskItem(task);
        },
      ),
    );
  }

  Widget _buildTaskItem(PaperTask task) {
    final paper = _paperById(task.paperId);
    final isOverdue = !task.completed && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/papers/${task.paperId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue
              ? Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                final authState = context.read<AuthBloc>().state;
                final userId = authState is AuthAuthenticated ? authState.user.uid : '';
                final userName = authState is AuthAuthenticated
                    ? (authState.user.displayName ?? '')
                    : '';
                final paperTitle = _paperTitle(task.paperId);
                context.read<TaskBloc>().add(TaskToggleRequested(
                      taskId: task.id,
                      completed: !task.completed,
                      currentUserId: userId,
                      currentUserName: userName,
                      paperTitle: paperTitle,
                      paperId: task.paperId,
                      taskTitle: task.title,
                      assigneeId: task.assigneeId,
                    ));
                setState(() {
                  final idx = _allTasks.indexWhere((t) => t.id == task.id);
                  if (idx != -1) {
                    _allTasks[idx] = task.copyWith(completed: !task.completed);
                  }
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.completed
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.completed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _paperTitle(task.paperId),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: isOverdue ? AppTheme.errorColor : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          DateFormat('MMM d').format(task.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? AppTheme.errorColor : Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (paper != null)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.priorityColor(paper.priority),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
