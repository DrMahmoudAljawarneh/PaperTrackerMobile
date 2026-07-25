import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';
import 'package:paper_tracker/widgets/live_sync_badge.dart';

class FocusModeScreen extends StatefulWidget {
  final String paperId;

  const FocusModeScreen({super.key, required this.paperId});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  final TextEditingController _sessionNotesController = TextEditingController();

  @override
  void dispose() {
    _sessionNotesController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.trim().isEmpty) return;
    final uri = Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  void _toggleManualFocus(Paper paper, String userId, String userName) {
    final newFocus = !paper.isFocused;
    context.read<PaperBloc>().add(
          PaperFocusToggled(
            paperId: paper.id,
            isFocused: newFocus,
            currentUserId: userId,
            currentUserName: userName,
            paperTitle: paper.title,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newFocus
              ? '🎯 Assigned "${paper.title}" to Team Focus Mode!'
              : 'Removed "${paper.title}" from Team Focus Mode.',
        ),
        backgroundColor: newFocus ? AppTheme.primaryColor : AppTheme.textMuted,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHandoffFocusDialog(Paper paper, String userId, String userName) async {
    List<String> registeredAccountNames = [];
    try {
      final chatRepo = context.read<ChatRepository>();
      final users = await chatRepo.getAllUsers();
      registeredAccountNames = users
          .map((u) => u.displayName.isNotEmpty ? u.displayName : u.email.split('@').first)
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {}

    // Use ONLY registered app accounts for focus handoff
    final authorsList = <String>{
      ...registeredAccountNames,
      if (userName.isNotEmpty) userName,
    }.toList();

    if (authorsList.isEmpty) {
      authorsList.add(userName.isNotEmpty ? userName : 'No registered users');
    }

    if (!mounted) return;

    String selectedAssignee = authorsList.firstWhere(
      (a) => a != userName && a != paper.currentlyWith,
      orElse: () => authorsList.first,
    );

    final nextStepController = TextEditingController(text: paper.nextStep);
    DateTime? selectedTurnDueDate = paper.turnDueDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hand Off Focus Task',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign the active Focus Task to a co-author so they can complete the next step:',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Text('Assign Focus To Author:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedAssignee,
                        dropdownColor: Theme.of(context).cardColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: authorsList.map((author) {
                          return DropdownMenuItem<String>(
                            value: author,
                          child: Text(author),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedAssignee = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Next Action Milestone:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nextStepController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., Revise methodology section and check equations',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selectedTurnDueDate != null
                                ? 'Turn Due: ${DateFormat('MMM d, yyyy').format(selectedTurnDueDate!)}'
                                : 'No turn due date set',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedTurnDueDate ?? DateTime.now().add(const Duration(days: 3)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => selectedTurnDueDate = picked);
                            }
                          },
                          child: const Text('Set Due Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final updatedPaper = paper.copyWith(
                      isFocused: true,
                      focusedAt: DateTime.now(),
                      focusedByUserId: userId,
                      currentlyWith: selectedAssignee,
                      nextStep: nextStepController.text.trim(),
                      turnDueDate: selectedTurnDueDate,
                      updatedAt: DateTime.now(),
                    );
                    context.read<PaperBloc>().add(
                          PaperUpdateRequested(
                            updatedPaper,
                            currentUserId: userId,
                            currentUserName: userName,
                          ),
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎯 Focus task assigned & turn passed to $selectedAssignee!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Hand Off Focus 🚀'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';
    final userName = authState is AuthAuthenticated ? (authState.user.displayName ?? 'Team Member') : 'Team Member';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.center_focus_strong_rounded, color: AppTheme.primaryColor, size: 24),
            SizedBox(width: 8),
            Text(
              'Focus Workspace',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Full Paper Details',
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () => context.push('/papers/${widget.paperId}'),
          ),
        ],
      ),
      body: BlocBuilder<PaperBloc, PaperState>(
        builder: (context, state) {
          if (state is PaperLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          Paper? paper;
          if (state is PapersLoaded) {
            paper = state.papers.where((p) => p.id == widget.paperId).firstOrNull;
          }

          if (paper == null) {
            return const Center(
              child: Text(
                'Paper not found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Focus Banner Card
                _buildTeamFocusBanner(paper, userId, userName),
                const SizedBox(height: 20),

                // Quick Action Hub (Overleaf / PDF / Next Step)
                _buildQuickActionsRow(paper),
                const SizedBox(height: 20),

                // Next Step & Key Focus Checklist
                _buildFocusChecklistSection(paper, userId, userName),
                const SizedBox(height: 20),

                // Session Notes Pad
                _buildSessionNotesPad(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamFocusBanner(Paper paper, String userId, String userName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: paper.isFocused
              ? [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.accentColor.withValues(alpha: 0.6)]
              : [Theme.of(context).cardColor, Theme.of(context).cardColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: paper.isFocused ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.black26,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      paper.isFocused ? Icons.stars_rounded : Icons.outlined_flag_rounded,
                      color: Colors.amberAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      paper.isFocused ? 'TEAM FOCUS ACTIVE' : 'STANDARD PAPER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _toggleManualFocus(paper, userId, userName),
                icon: Icon(
                  paper.isFocused ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 18,
                  color: paper.isFocused ? Colors.amber : Colors.white,
                ),
                label: Text(
                  paper.isFocused ? 'Assigned to Focus' : 'Set as Team Focus',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: paper.isFocused ? Colors.white24 : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            paper.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (paper.targetVenue.isNotEmpty || paper.deadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (paper.targetVenue.isNotEmpty) ...[
                  const Icon(Icons.school_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    paper.targetVenue,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                ],
                if (paper.deadline != null) ...[
                  const Icon(Icons.event_rounded, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM d, yyyy').format(paper.deadline!)}',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildQuickActionsRow(Paper paper) {
    return Row(
      children: [
        if (paper.overleafUrl.isNotEmpty) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl(paper.overleafUrl),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Open Overleaf'),
                  SizedBox(width: 6),
                  LiveSyncBadge(),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF47A141), // Overleaf green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (paper.pdfUrl.isNotEmpty) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl(paper.pdfUrl),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('View PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFocusChecklistSection(Paper paper, String userId, String userName) {
    final currentlyWith = paper.currentlyWith.isNotEmpty ? paper.currentlyWith : 'Unassigned';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Active Focus Milestone',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          currentlyWith,
                          style: const TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              paper.nextStep.isNotEmpty ? paper.nextStep : 'No specific next step set for this paper yet.',
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showHandoffFocusDialog(paper, userId, userName),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Finish Task & Hand Off Focus to Co-Author'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionNotesPad() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                'Focus Scratchpad',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sessionNotesController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Jot down quick thoughts, draft sentences, or findings during this session...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
