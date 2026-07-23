import 'package:flutter/material.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/reviewer_comment.dart';

class RevisionsTab extends StatefulWidget {
  final String paperId;

  const RevisionsTab({super.key, required this.paperId});

  @override
  State<RevisionsTab> createState() => _RevisionsTabState();
}

class _RevisionsTabState extends State<RevisionsTab> {
  // In-memory demo list for Reviewer Comments / Rebuttal items
  late List<ReviewerComment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [
      ReviewerComment(
        id: 'rev-1',
        paperId: widget.paperId,
        reviewerName: 'Reviewer 1',
        commentText: 'The methodology section lacks comparison with state-of-the-art Baseline X.',
        responseText: 'Added Section 4.3 comparing accuracy metrics with Baseline X (+4.2% gain).',
        status: ReviewItemStatus.addressed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ReviewerComment(
        id: 'rev-2',
        paperId: widget.paperId,
        reviewerName: 'Reviewer 2',
        commentText: 'Clarify the time complexity analysis in Theorem 1.',
        responseText: 'Proof updated in Appendix B.',
        status: ReviewItemStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  void _showAddCommentDialog() {
    final reviewerController = TextEditingController(text: 'Reviewer 1');
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Reviewer Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reviewerController,
              decoration: const InputDecoration(labelText: 'Reviewer / Editor'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reviewer Comment / Feedback'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.trim().isNotEmpty) {
                setState(() {
                  _comments.add(
                    ReviewerComment(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      paperId: widget.paperId,
                      reviewerName: reviewerController.text.trim(),
                      commentText: commentController.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _showResponseDialog(ReviewerComment item) {
    final responseController = TextEditingController(text: item.responseText);
    ReviewItemStatus selectedStatus = item.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Response to ${item.reviewerName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comment: "${item.commentText}"',
                style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Author Rebuttal / Response Text',
                  hintText: 'Describe changes made in manuscript...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReviewItemStatus>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Action Status'),
                items: ReviewItemStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final idx = _comments.indexWhere((c) => c.id == item.id);
                  if (idx != -1) {
                    _comments[idx] = item.copyWith(
                      responseText: responseController.text.trim(),
                      status: selectedStatus,
                    );
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save Response'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressedCount = _comments.where((c) => c.status == ReviewItemStatus.addressed).length;
    final totalCount = _comments.length;
    final progress = totalCount > 0 ? addressedCount / totalCount : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rebuttal Progress Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rate_review_rounded, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Peer Review Action Plan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '$addressedCount / $totalCount Addressed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.accentColor.withValues(alpha: 0.15),
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            const Text(
              'Reviewer Feedback & Rebuttal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddCommentDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Review Item'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No reviewer items added yet.\nTap "+ Add Review Item" to break down review feedback.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
          )
        else
          ..._comments.map((item) {
            Color statusColor;
            String statusText;
            switch (item.status) {
              case ReviewItemStatus.addressed:
                statusColor = AppTheme.successColor;
                statusText = 'ADDRESSED';
                break;
              case ReviewItemStatus.inProgress:
                statusColor = AppTheme.warningColor;
                statusText = 'IN PROGRESS';
                break;
              case ReviewItemStatus.unaddressed:
                statusColor = AppTheme.errorColor;
                statusText = 'UNADDRESSED';
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        onPressed: () => _showResponseDialog(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💬 "${item.commentText}"',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (item.responseText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.successColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rebuttal: ${item.responseText}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.successColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
