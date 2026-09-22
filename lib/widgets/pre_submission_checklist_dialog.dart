import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';

class PreSubmissionChecklistDialog extends StatefulWidget {
  final Paper paper;
  final VoidCallback onProceedToSubmit;

  const PreSubmissionChecklistDialog({
    super.key,
    required this.paper,
    required this.onProceedToSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required Paper paper,
    required VoidCallback onProceedToSubmit,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => PreSubmissionChecklistDialog(
        paper: paper,
        onProceedToSubmit: onProceedToSubmit,
      ),
    );
  }

  @override
  State<PreSubmissionChecklistDialog> createState() =>
      _PreSubmissionChecklistDialogState();
}

class _PreSubmissionChecklistDialogState
    extends State<PreSubmissionChecklistDialog> {
  final Map<String, bool> _checks = {
    'Author approval: All co-authors have signed off on the draft': false,
    'Formatting & Page Limit: Adheres to target venue guidelines': false,
    'Anonymization / Blind Review: Identifiers removed if double-blind': false,
    'Supplementary Material: Code, data, and appendices packaged': false,
    'Figures & Tables: High-resolution & legible in print/PDF': false,
    'Conflict of Interest & Declarations: Completed in submission system': false,
  };

  @override
  void initState() {
    super.initState();
    // Auto-check co-author approval if already signed off in paper model
    final approvals = widget.paper.authorApprovals;
    if (approvals.isNotEmpty && approvals.values.every((v) => v)) {
      _checks['Author approval: All co-authors have signed off on the draft'] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allChecked = _checks.values.every((checked) => checked);
    final checkedCount = _checks.values.where((c) => c).length;

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_outlined, color: AppTheme.warningColor, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pre-Submission Checklist',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete all pre-flight items before advancing "${widget.paper.title}" to Submitted status ($checkedCount/${_checks.length}):',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: checkedCount / _checks.length,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allChecked ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              ..._checks.entries.map((entry) {
                final isChecked = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked
                          ? AppTheme.successColor.withValues(alpha: 0.3)
                          : theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                        color: isChecked ? AppTheme.successColor : null,
                      ),
                    ),
                    value: isChecked,
                    activeColor: AppTheme.successColor,
                    dense: true,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _checks[entry.key] = val ?? false);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: allChecked
              ? () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  widget.onProceedToSubmit();
                }
              : null,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Confirm & Mark Submitted'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
