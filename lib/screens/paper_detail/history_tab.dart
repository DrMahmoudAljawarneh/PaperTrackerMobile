import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/status_history_entry.dart';
import 'package:paper_tracker/repositories/status_history_repository.dart';
import 'package:paper_tracker/widgets/empty_state.dart';

class HistoryTab extends StatelessWidget {
  final String paperId;

  const HistoryTab({super.key, required this.paperId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<StatusHistoryRepository>();

    return StreamBuilder<List<StatusHistoryEntry>>(
      stream: repo.getHistory(paperId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: 'No history yet',
            subtitle: 'Status changes will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isLast = index == entries.length - 1;

            return _buildTimelineItem(context, entry, isLast);
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, StatusHistoryEntry entry, bool isLast) {
    final fromColor = AppTheme.statusColor(entry.oldStatus);
    final toColor = AppTheme.statusColor(entry.newStatus);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: toColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: toColor.withValues(alpha: 0.3), width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: '${entry.oldStatus.emoji} ${entry.oldStatus.label}',
                          style: TextStyle(color: fromColor, fontWeight: FontWeight.w500),
                        ),
                        const TextSpan(text: '  →  '),
                        TextSpan(
                          text: '${entry.newStatus.emoji} ${entry.newStatus.label}',
                          style: TextStyle(color: toColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy  h:mm a').format(entry.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  if (entry.changedByUserName.isNotEmpty)
                    Text(
                      'by ${entry.changedByUserName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
