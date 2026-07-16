import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/task/task_bloc.dart';
import 'package:paper_tracker/blocs/task/task_event.dart';
import 'package:paper_tracker/blocs/task/task_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper_task.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/widgets/empty_state.dart';

class TasksTab extends StatefulWidget {
  final String paperId;

  const TasksTab({super.key, required this.paperId});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(TasksLoadRequested(widget.paperId));
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add task input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    hintText: 'Add a new task...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: _addTask,
                ),
              ),
              IconButton(
                onPressed: () => _addTask(_taskController.text),
                icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),

        // Tasks list
        Expanded(
          child: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TaskLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is TasksLoaded) {
                if (state.tasks.isEmpty) {
                  return const EmptyState(
                    icon: Icons.task_alt,
                    title: 'No tasks yet',
                    subtitle: 'Add tasks to track your progress',
                  );
                }

                final pending = state.tasks.where((t) => !t.completed).toList();
                final completed =
                    state.tasks.where((t) => t.completed).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _buildSectionLabel(
                          'To Do (${pending.length})', Theme.of(context).colorScheme.primary),
                      ...pending.map(_buildTaskTile),
                    ],
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionLabel(
                          'Completed (${completed.length})',
                          AppTheme.successColor),
                      ...completed.map(_buildTaskTile),
                    ],
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTaskTile(PaperTask task) {
    final priorityColor = switch (task.priority) {
      TaskPriority.high => AppTheme.errorColor,
      TaskPriority.medium => AppTheme.warningColor,
      TaskPriority.low => AppTheme.accentColor,
    };

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
      ),
      onDismissed: (_) {
        context.read<TaskBloc>().add(TaskDeleteRequested(task.id));
      },
      child: ListTile(
        onTap: () => _showEditTaskDialog(task),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Checkbox(
          value: task.completed,
          onChanged: (value) {
            context.read<TaskBloc>().add(TaskToggleRequested(
                  taskId: task.id,
                  completed: value ?? false,
                ));
          },
          activeColor: AppTheme.successColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: task.completed ? TextDecoration.lineThrough : null,
                  color: task.completed ? Theme.of(context).textTheme.bodySmall?.color : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: priorityColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.dueDate != null)
                  Text(
                    'Due ${DateFormat('MMM d').format(task.dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.dueDate!.isBefore(DateTime.now()) && !task.completed
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                if (task.progress > 0 && !task.completed) ...[
                  if (task.dueDate != null) const SizedBox(width: 12),
                  Text(
                    '${task.progress}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            if (task.progress > 0 && !task.completed) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: task.progress / 100,
                  minHeight: 3,
                  backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(PaperTask task) {
    final titleController = TextEditingController(text: task.title);
    DateTime? selectedDate = task.dueDate;
    UserModel? selectedAssignee;
    List<UserModel> searchResults = [];
    bool isSearching = false;
    Timer? searchDebounce;
    TaskPriority selectedPriority = task.priority;
    double _progress = task.progress.toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void searchUsers(String query) {
              searchDebounce?.cancel();
              if (query.length < 2) {
                setSheetState(() => searchResults = []);
                return;
              }
              searchDebounce = Timer(
                const Duration(milliseconds: 300),
                () async {
                  final currentQuery = query;
                  if (currentQuery.length < 2) return;
                  setSheetState(() => isSearching = true);
                  try {
                    final results = await context
                        .read<AuthRepository>()
                        .searchUsers(currentQuery);
                    setSheetState(() {
                      searchResults = results
                          .where((u) =>
                              selectedAssignee == null ||
                              u.uid != selectedAssignee!.uid)
                          .toList();
                      isSearching = false;
                    });
                  } catch (e) {
                    setSheetState(() => isSearching = false);
                  }
                },
              );
            }

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
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Task',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setSheetState(() => selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDate != null
                            ? DateFormat('MMM d, yyyy').format(selectedDate!)
                            : 'No due date',
                      ),
                    ),
                  ),
                  if (selectedDate != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setSheetState(() => selectedDate = null),
                        child: const Text('Clear date'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Assignee',
                      hintText: 'Search by email',
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: searchUsers,
                  ),
                  if (searchResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Material(
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final user = searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    (user.displayName.isNotEmpty
                                            ? user.displayName[0]
                                            : user.email[0])
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName
                                      : user.email,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: user.displayName.isNotEmpty
                                    ? Text(user.email,
                                        style: const TextStyle(fontSize: 12))
                                    : null,
                                onTap: () {
                                  setSheetState(() {
                                    selectedAssignee = user;
                                    searchResults = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  if (selectedAssignee != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      avatar: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.2),
                        child: Text(
                          (selectedAssignee!.displayName.isNotEmpty
                                  ? selectedAssignee!.displayName[0]
                                  : selectedAssignee!.email[0])
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      label: Text(
                        selectedAssignee!.displayName.isNotEmpty
                            ? selectedAssignee!.displayName
                            : selectedAssignee!.email,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setSheetState(() => selectedAssignee = null),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskPriority.values.map((p) => DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Icon(
                            switch (p) {
                              TaskPriority.high => Icons.arrow_upward,
                              TaskPriority.medium => Icons.remove,
                              TaskPriority.low => Icons.arrow_downward,
                            },
                            size: 16,
                            color: switch (p) {
                              TaskPriority.high => AppTheme.errorColor,
                              TaskPriority.medium => AppTheme.warningColor,
                              TaskPriority.low => AppTheme.accentColor,
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(p.name.toUpperCase()),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedPriority = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Progress', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _progress,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${_progress.round()}%',
                          onChanged: (v) => setSheetState(() => _progress = v),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${_progress.round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          titleController.dispose();
                          searchDebounce?.cancel();
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          final trimmed = titleController.text.trim();
                          if (trimmed.isEmpty) return;
                          context.read<TaskBloc>().add(TaskEditRequested(
                                taskId: task.id,
                                title: trimmed,
                                dueDate: selectedDate,
                                assigneeId:
                                    selectedAssignee?.uid ?? task.assigneeId,
                                priority: selectedPriority.name,
                                progress: _progress.round(),
                              ));
                          titleController.dispose();
                          searchDebounce?.cancel();
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Save'),
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
  }

  void _addTask(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final task = PaperTask(
      id: '',
      paperId: widget.paperId,
      title: trimmed,
      assigneeId: authState.user.uid,
      createdAt: DateTime.now(),
    );
    context.read<TaskBloc>().add(TaskCreateRequested(task));
    _taskController.clear();
  }
}

