import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/repositories/paper_repository.dart';

class AddEditPaperScreen extends StatefulWidget {
  final String? paperId;

  const AddEditPaperScreen({super.key, this.paperId});

  bool get isEditing => paperId != null;

  @override
  State<AddEditPaperScreen> createState() => _AddEditPaperScreenState();
}

class _AddEditPaperScreenState extends State<AddEditPaperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _abstractController = TextEditingController();
  final _venueController = TextEditingController();
  final _tagController = TextEditingController();
  final _authorController = TextEditingController();
  final _collaboratorController = TextEditingController();
  final _currentlyWithController = TextEditingController();

  PaperStatus _status = PaperStatus.idea;
  PaperPriority _priority = PaperPriority.medium;
  DateTime? _deadline;
  List<String> _tags = [];
  List<String> _authors = [];
  List<UserModel> _collaborators = [];
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  Paper? _existingPaper;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadPaper();
    }
  }

  Future<void> _loadPaper() async {
    setState(() => _isLoading = true);
    final paper = await context
        .read<PaperRepository>()
        .getPaperById(widget.paperId!);
    if (paper != null && mounted) {
      // Load collaborator profiles from authorIds (excluding lead author)
      final authRepo = context.read<AuthRepository>();
      final collabs = <UserModel>[];
      for (final uid in paper.authorIds) {
        if (uid != paper.leadAuthorId) {
          final user = await authRepo.getUserById(uid);
          if (user != null) collabs.add(user);
        }
      }
      if (!mounted) return;
      setState(() {
        _existingPaper = paper;
        _titleController.text = paper.title;
        _abstractController.text = paper.abstract_;
        _venueController.text = paper.targetVenue;
        _status = paper.status;
        _priority = paper.priority;
        _deadline = paper.deadline;
        _tags = List.from(paper.tags);
        _authors = List.from(paper.authors);
        _collaborators = collabs;
        _currentlyWithController.text = paper.currentlyWith;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _abstractController.dispose();
    _venueController.dispose();
    _tagController.dispose();
    _authorController.dispose();
    _collaboratorController.dispose();
    _currentlyWithController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Paper' : 'New Paper'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _savePaper,
            child: Text(
              widget.isEditing ? 'Save' : 'Create',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Paper Title *',
                      hintText: 'Enter the title of your paper',
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Abstract
                  TextFormField(
                    controller: _abstractController,
                    decoration: const InputDecoration(
                      labelText: 'Abstract',
                      hintText: 'Brief summary of your paper',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  // Authors
                  _buildAuthorsSection(),
                  const SizedBox(height: 20),

                  // Collaborators
                  _buildCollaboratorsSection(),
                  const SizedBox(height: 20),

                  // Status
                  _buildDropdown<PaperStatus>(
                    label: 'Status',
                    value: _status,
                    items: PaperStatus.values,
                    itemLabel: (s) => '${s.emoji} ${s.label}',
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 20),

                  // Priority
                  _buildDropdown<PaperPriority>(
                    label: 'Priority',
                    value: _priority,
                    items: PaperPriority.values,
                    itemLabel: (p) => p.label,
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 20),

                  // Target Venue
                  TextFormField(
                    controller: _venueController,
                    decoration: const InputDecoration(
                      labelText: 'Target Venue',
                      hintText: 'Conference or journal name',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Deadline
                  _buildDeadlinePicker(),
                  const SizedBox(height: 20),

                  // Tags
                  _buildTagsSection(),
                  const SizedBox(height: 20),

                  // Currently With
                  TextFormField(
                    controller: _currentlyWithController,
                    decoration: const InputDecoration(
                      labelText: 'Currently With',
                      hintText: 'e.g. Dr. Smith, IEEE Reviewers',
                      prefixIcon: Icon(Icons.person_pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Delete button (edit mode only)
                  if (widget.isEditing) ...[
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.errorColor),
                      label: const Text('Delete Paper',
                          style: TextStyle(color: AppTheme.errorColor)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(itemLabel(item)),
              ))
          .toList(),
      onChanged: onChanged,
      dropdownColor: AppTheme.cardColorLight,
    );
  }

  Widget _buildDeadlinePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.primaryColor,
                  surface: AppTheme.surfaceColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _deadline = picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Deadline',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _deadline != null
                  ? DateFormat('MMMM d, yyyy').format(_deadline!)
                  : 'No deadline set',
              style: TextStyle(
                color: _deadline != null
                    ? AppTheme.textPrimary
                    : AppTheme.textMuted,
              ),
            ),
            if (_deadline != null)
              GestureDetector(
                onTap: () => setState(() => _deadline = null),
                child: const Icon(Icons.clear, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Add a tag',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addTag(_tagController.text),
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setState(() => _tags.remove(tag)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  Widget _buildCollaboratorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _collaboratorController,
          decoration: InputDecoration(
            labelText: 'Collaborators',
            hintText: 'Search by email',
            prefixIcon: const Icon(Icons.group_add_outlined),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _searchCollaborators,
        ),
        // Search results
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      (user.displayName.isNotEmpty
                              ? user.displayName[0]
                              : user.email[0])
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    user.displayName.isNotEmpty ? user.displayName : user.email,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: user.displayName.isNotEmpty
                      ? Text(user.email, style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () => _addCollaborator(user),
                );
              },
            ),
          ),
        // Selected collaborators
        if (_collaborators.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _collaborators
                .map((user) => Chip(
                      avatar: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                        child: Text(
                          (user.displayName.isNotEmpty
                                  ? user.displayName[0]
                                  : user.email[0])
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      label: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName
                            : user.email,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setState(() => _collaborators.remove(user)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _searchCollaborators(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final authState = context.read<AuthBloc>().state;
      final currentUid =
          authState is AuthAuthenticated ? authState.user.uid : '';
      final results =
          await context.read<AuthRepository>().searchUsers(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results
            .where((u) =>
                u.uid != currentUid &&
                !_collaborators.any((c) => c.uid == u.uid))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Collaborator search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addCollaborator(UserModel user) {
    setState(() {
      _collaborators.add(user);
      _searchResults = [];
      _collaboratorController.clear();
    });
  }

  Widget _buildAuthorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Authors',
                  hintText: 'Add an author name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onSubmitted: _addAuthor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addAuthor(_authorController.text),
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        if (_authors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _authors
                .map((author) => Chip(
                      avatar: const Icon(Icons.person, size: 16),
                      label: Text(author),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setState(() => _authors.remove(author)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  void _addAuthor(String author) {
    final trimmed = author.trim();
    if (trimmed.isNotEmpty && !_authors.contains(trimmed)) {
      setState(() {
        _authors.add(trimmed);
        _authorController.clear();
      });
    }
  }

  void _savePaper() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final userId = authState.user.uid;
    final now = DateTime.now();

    final collaboratorIds = _collaborators.map((u) => u.uid).toList();
    final allAuthorIds = [userId, ...collaboratorIds];

    if (widget.isEditing && _existingPaper != null) {
      final updated = _existingPaper!.copyWith(
        title: _titleController.text.trim(),
        abstract_: _abstractController.text.trim(),
        status: _status,
        priority: _priority,
        authorIds: allAuthorIds,
        targetVenue: _venueController.text.trim(),
        deadline: _deadline,
        tags: _tags,
        authors: _authors,
        currentlyWith: _currentlyWithController.text.trim(),
        updatedAt: now,
      );
      context.read<PaperBloc>().add(PaperUpdateRequested(
            updated,
            currentUserId: userId,
            currentUserName: authState.user.displayName ?? '',
          ));
    } else {
      final paper = Paper(
        id: '',
        title: _titleController.text.trim(),
        abstract_: _abstractController.text.trim(),
        status: _status,
        priority: _priority,
        authorIds: allAuthorIds,
        authors: _authors,
        leadAuthorId: userId,
        targetVenue: _venueController.text.trim(),
        deadline: _deadline,
        tags: _tags,
        currentlyWith: _currentlyWithController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      context.read<PaperBloc>().add(PaperCreateRequested(paper));
    }
    context.pop();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Paper'),
        content: const Text(
            'Are you sure you want to delete this paper? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<PaperBloc>()
                  .add(PaperDeleteRequested(widget.paperId!));
              context.pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
