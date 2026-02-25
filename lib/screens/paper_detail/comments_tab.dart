import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/comment.dart';
import 'package:paper_tracker/repositories/comment_repository.dart';
import 'package:paper_tracker/widgets/empty_state.dart';

class CommentsTab extends StatefulWidget {
  final String paperId;

  const CommentsTab({super.key, required this.paperId});

  @override
  State<CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<CommentsTab> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comments list
        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: context
                .read<CommentRepository>()
                .getCommentsForPaper(widget.paperId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No comments yet',
                  subtitle: 'Start a discussion about this paper',
                );
              }

              return ListView.builder(
                reverse: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  // Reverse the order so newest is at bottom
                  final comment = comments[comments.length - 1 - index];
                  return _buildCommentBubble(comment);
                },
              );
            },
          ),
        ),

        // Comment input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(
              top: BorderSide(
                color: AppTheme.dividerColor.withOpacity(0.5),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: AppTheme.primaryColor,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBubble(Comment comment) {
    final authState = context.read<AuthBloc>().state;
    final isMe = authState is AuthAuthenticated &&
        authState.user.uid == comment.authorId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName
                        : 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              Text(
                comment.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(comment.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(dt);
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSending = true);

    final comment = Comment(
      id: '',
      paperId: widget.paperId,
      authorId: authState.user.uid,
      authorName: authState.user.displayName ?? 'Unknown',
      text: text,
      createdAt: DateTime.now(),
    );

    await context.read<CommentRepository>().addComment(comment);
    _commentController.clear();
    setState(() => _isSending = false);
  }
}
