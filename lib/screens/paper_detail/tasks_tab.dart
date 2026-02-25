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
            color: AppTheme.surfaceColor,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.dividerColor.withOpacity(0.3),
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
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
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
                          'To Do (${pending.length})', AppTheme.primaryColor),
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
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor.withOpacity(0.2),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      onDismissed: (_) {
        context.read<TaskBloc>().add(TaskDeleteRequested(task.id));
      },
      child: ListTile(
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
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? AppTheme.textMuted : AppTheme.textPrimary,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text(
                'Due ${DateFormat('MMM d').format(task.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: task.dueDate!.isBefore(DateTime.now()) && !task.completed
                      ? AppTheme.errorColor
                      : AppTheme.textMuted,
                ),
              )
            : null,
      ),
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
