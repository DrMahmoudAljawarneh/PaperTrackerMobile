import 'package:flutter/material.dart';
import 'package:paper_tracker/config/theme.dart';

class DeadlineCountdown extends StatelessWidget {
  final DateTime deadline;
  final bool compact;

  const DeadlineCountdown({
    super.key,
    required this.deadline,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    final days = diff.inDays;
    final isPast = diff.isNegative;

    final Color color;
    final String text;

    if (isPast) {
      color = AppTheme.errorColor;
      text = 'Overdue by ${-days} day${-days == 1 ? '' : 's'}';
    } else if (days == 0) {
      color = AppTheme.errorColor;
      text = 'Due today';
    } else if (days <= 3) {
      color = AppTheme.warningColor;
      text = '$days day${days == 1 ? '' : 's'} left';
    } else if (days <= 7) {
      color = AppTheme.accentColor;
      text = '$days days left';
    } else {
      color = AppTheme.textMuted;
      text = '$days days left';
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPast ? Icons.warning_amber_rounded : Icons.schedule,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
