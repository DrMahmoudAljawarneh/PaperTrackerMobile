import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/widgets/status_badge.dart';

class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const CommandPaletteDialog(),
    );
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paperState = context.watch<PaperBloc>().state;
    final papers = paperState is PapersLoaded ? paperState.papers : <Paper>[];

    final filteredPapers = _query.isEmpty
        ? papers.take(5).toList()
        : papers.where((p) {
            return p.title.toLowerCase().contains(_query) ||
                p.targetVenue.toLowerCase().contains(_query) ||
                p.tags.any((t) => t.toLowerCase().contains(_query)) ||
                p.status.label.toLowerCase().contains(_query);
          }).take(8).toList();

    final actions = [
      _QuickAction(
        title: 'New Paper',
        subtitle: 'Create a new research paper entry',
        icon: Icons.add_circle_outline_rounded,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/papers/add');
        },
      ),
      _QuickAction(
        title: 'Kanban Board',
        subtitle: 'View workflow stages & drag cards',
        icon: Icons.view_kanban_outlined,
        onTap: () {
          Navigator.of(context).pop();
          context.go('/papers');
        },
      ),
      _QuickAction(
        title: 'Calendar & Deadlines',
        subtitle: 'View upcoming paper submission dates',
        icon: Icons.calendar_month_outlined,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/dashboard/calendar');
        },
      ),
      _QuickAction(
        title: 'Global Tasks',
        subtitle: 'Inspect all open tasks across papers',
        icon: Icons.checklist_rtl_rounded,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/tasks');
        },
      ),
    ].where((a) => _query.isEmpty || a.title.toLowerCase().contains(_query) || a.subtitle.toLowerCase().contains(_query)).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search papers, actions, or shortcuts...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text(
                      'ESC',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),

            // Results List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (filteredPapers.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'PAPERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    ...filteredPapers.map((paper) => ListTile(
                          leading: StatusBadge(status: paper.status),
                          title: Text(
                            paper.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            paper.targetVenue.isNotEmpty ? paper.targetVenue : 'No venue assigned',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            context.push('/papers/${paper.id}');
                          },
                        )),
                  ],
                  if (actions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'QUICK ACTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    ...actions.map((act) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                            radius: 16,
                            child: Icon(act.icon, size: 18, color: AppTheme.primaryColor),
                          ),
                          title: Text(
                            act.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            act.subtitle,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          trailing: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textMuted),
                          onTap: act.onTap,
                        )),
                  ],
                  if (filteredPapers.isEmpty && actions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No matching papers or actions',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
