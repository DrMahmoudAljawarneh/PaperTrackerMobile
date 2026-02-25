import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/widgets/status_badge.dart';

class PaperCard extends StatelessWidget {
  final Paper paper;
  final VoidCallback? onTap;

  const PaperCard({
    super.key,
    required this.paper,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDeadline = paper.deadline != null
        ? paper.deadline!.difference(DateTime.now()).inDays
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: AppTheme.glassmorphismDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status badge + priority
              Row(
                children: [
                  StatusBadge(status: paper.status),
                  const Spacer(),
                  _buildPriorityIndicator(),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                paper.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Target venue
              if (paper.targetVenue.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        paper.targetVenue,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Bottom row: deadline + authors count
              Row(
                children: [
                  if (paper.deadline != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: daysUntilDeadline != null && daysUntilDeadline <= 3
                          ? AppTheme.errorColor
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(paper.deadline!),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            daysUntilDeadline != null && daysUntilDeadline <= 3
                                ? AppTheme.errorColor
                                : AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (daysUntilDeadline != null && daysUntilDeadline >= 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: daysUntilDeadline <= 3
                              ? AppTheme.errorColor.withOpacity(0.15)
                              : AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          daysUntilDeadline == 0
                              ? 'Today'
                              : '${daysUntilDeadline}d left',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: daysUntilDeadline <= 3
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const Spacer(),
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${paper.authorIds.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),

              // Tags
              if (paper.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: paper.tags
                      .take(3)
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    final color = AppTheme.priorityColor(paper.priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          paper.priority.label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
