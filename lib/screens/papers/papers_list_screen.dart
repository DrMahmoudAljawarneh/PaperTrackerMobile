import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/widgets/empty_state.dart';
import 'package:paper_tracker/widgets/paper_card.dart';
import 'package:paper_tracker/widgets/shimmer_loading.dart';

enum _SortOption {
  updated('Recently Updated', Icons.update),
  created('Date Created', Icons.calendar_today),
  title('Title A–Z', Icons.sort_by_alpha),
  priority('Priority', Icons.flag),
  deadline('Deadline', Icons.schedule);

  final String label;
  final IconData icon;
  const _SortOption(this.label, this.icon);
}

enum _SharingFilter {
  all('All Papers'),
  sharedByMe('Shared by me'),
  sharedWithMe('Shared with me'),
  private('Private');

  final String label;
  const _SharingFilter(this.label);
}

class PapersListScreen extends StatefulWidget {
  final Set<PaperStatus>? initialStatusFilter;
  const PapersListScreen({super.key, this.initialStatusFilter});

  @override
  State<PapersListScreen> createState() => _PapersListScreenState();
}

class _PapersListScreenState extends State<PapersListScreen> {
  bool _isKanbanView = false;
  PaperStatus? _selectedStatus;
  Set<PaperStatus>? _selectedStatusSet;
  PaperPriority? _selectedPriority;
  _SortOption _sortOption = _SortOption.updated;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  _SharingFilter _selectedSharing = _SharingFilter.all;
  List<UserModel> _collaborators = <UserModel>[];
  String? _selectedCollaboratorId;
  List<String> _lastCheckedPaperIds = <String>[];

  @override
  void initState() {
    super.initState();
    _selectedStatusSet = widget.initialStatusFilter;
    _loadPapers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paperState = context.read<PaperBloc>().state;
      if (paperState is PapersLoaded) {
        _updateCollaboratorList(paperState.papers);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPapers() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<PaperBloc>()
          .add(PapersLoadRequested(authState.user.uid));
    }
  }

  List<Paper> _filterAndSort(List<Paper> papers) {
    var filtered = papers.toList();

    // Status filter
    if (_selectedStatusSet != null) {
      filtered =
          filtered.where((p) => _selectedStatusSet!.contains(p.status)).toList();
    } else if (_selectedStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }

    // Priority filter
    if (_selectedPriority != null) {
      filtered =
          filtered.where((p) => p.priority == _selectedPriority).toList();
    }

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.uid : '';

    // Sharing filter
    if (currentUserId.isNotEmpty) {
      switch (_selectedSharing) {
        case _SharingFilter.all:
          break;
        case _SharingFilter.sharedByMe:
          filtered = filtered
              .where((p) => p.leadAuthorId == currentUserId && p.authorIds.length > 1)
              .toList();
          break;
        case _SharingFilter.sharedWithMe:
          filtered = filtered
              .where((p) => p.leadAuthorId != currentUserId)
              .toList();
          break;
        case _SharingFilter.private:
          filtered = filtered
              .where((p) => p.leadAuthorId == currentUserId && p.authorIds.length <= 1)
              .toList();
          break;
      }
    }

    // Colleague filter
    if (_selectedCollaboratorId != null) {
      filtered = filtered
          .where((p) => p.authorIds.contains(_selectedCollaboratorId))
          .toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.targetVenue.toLowerCase().contains(q) ||
              p.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    // Sort
    switch (_sortOption) {
      case _SortOption.updated:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case _SortOption.created:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.title:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _SortOption.priority:
        filtered.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case _SortOption.deadline:
        filtered.sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
        break;
    }

    return filtered;
  }

  Widget _buildFilterButton() {
    final theme = Theme.of(context);
    final count = _activeAdvancedFiltersCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          icon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showFilterBottomSheet(context);
          },
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/papers/add');
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search & Filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search papers, venues, tags...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(),
              ],
            ),
          ),

          // Status segmented tabs
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusChip('All', null),
                ...PaperStatus.values.map(
                  (status) => _buildStatusChip(
                    '${status.emoji} ${status.label}',
                    status,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Active filter badges (Priority, Sharing, Collaborators)
          _buildActiveFiltersBadges(),

          // Sort option selection & View Toggle (List vs Kanban)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // List vs Kanban Toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.view_list_rounded, size: 16),
                      label: Text('List', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.view_kanban_rounded, size: 16),
                      label: Text('Kanban', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_isKanbanView},
                  onSelectionChanged: (set) {
                    HapticFeedback.selectionClick();
                    setState(() => _isKanbanView = set.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<_SortOption>(
                  initialValue: _sortOption,
                  onSelected: (v) => setState(() => _sortOption = v),
                  tooltip: 'Sort by',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_sortOption.icon, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => _SortOption.values
                      .map((opt) => PopupMenuItem(
                            value: opt,
                            child: Row(
                              children: [
                                Icon(opt.icon,
                                    size: 16,
                                    color: opt == _sortOption
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(width: 8),
                                Text(opt.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: opt == _sortOption
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                    )),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Papers list
          Expanded(
            child: BlocConsumer<PaperBloc, PaperState>(
              listener: (context, state) {
                if (state is PapersLoaded) {
                  _updateCollaboratorList(state.papers);
                }
              },
              builder: (context, state) {
                if (state is PaperLoading) {
                  return _buildPapersShimmer();
                }
                if (state is PapersLoaded) {
                  final filtered = _filterAndSort(state.papers);

                  // Result count
                  return Column(
                    children: [
                      if (state.papers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Text(
                                '${filtered.length} paper${filtered.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_selectedStatus != null ||
                                  _selectedPriority != null ||
                                  _selectedSharing != _SharingFilter.all ||
                                  _selectedCollaboratorId != null ||
                                  _searchQuery.isNotEmpty) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStatusSet = null;
                                      _selectedStatus = null;
                                      _selectedPriority = null;
                                      _selectedSharing = _SharingFilter.all;
                                      _selectedCollaboratorId = null;
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                  child: Text(
                                    'Clear filters',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: filtered.isEmpty
                            ? EmptyState(
                                icon: Icons.article_outlined,
                                title: state.papers.isEmpty
                                    ? 'No papers yet'
                                    : 'No matching papers',
                                subtitle: state.papers.isEmpty
                                    ? 'Tap + to add your first paper'
                                    : 'Try a different filter or search term',
                                action: state.papers.isEmpty
                                    ? ElevatedButton.icon(
                                        onPressed: () =>
                                            context.push('/papers/add'),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Paper'),
                                      )
                                    : null,
                              )
                            : RefreshIndicator(
                                onRefresh: () async => _loadPapers(),
                                child: _isKanbanView
                                    ? _buildKanbanBoard(filtered)
                                    : ListView.builder(
                                        padding: const EdgeInsets.only(bottom: 80),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          final paper = filtered[index];
                                          return _AnimatedPaperCard(
                                            index: index,
                                            child: PaperCard(
                                              paper: paper,
                                              onTap: () => context
                                                  .push('/papers/${paper.id}'),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                      ),
                    ],
                  );
                }
                return _buildPapersShimmer();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPapersShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: 4,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top tags / status line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoading(width: 80, height: 16, borderRadius: 4),
                  ShimmerLoading(width: 60, height: 16, borderRadius: 4),
                ],
              ),
              SizedBox(height: 12),
              // Title
              ShimmerLoading(width: double.infinity, height: 20, borderRadius: 4),
              SizedBox(height: 8),
              ShimmerLoading(width: 180, height: 18, borderRadius: 4),
              SizedBox(height: 16),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoading(width: 100, height: 14, borderRadius: 4),
                  ShimmerLoading(width: 40, height: 14, borderRadius: 4),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateCollaboratorList(List<Paper> papers) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final currentUserId = authState.user.uid;

    final paperIds = papers.map((p) => p.id).toList()..sort();
    final bool paperIdsChanged = _lastCheckedPaperIds.length != paperIds.length ||
        !_lastCheckedPaperIds.asMap().entries.every((e) => paperIds[e.key] == e.value);

    if (!paperIdsChanged) return;
    _lastCheckedPaperIds = paperIds;

    final collaboratorIds = papers
        .expand((p) => p.authorIds)
        .where((id) => id != currentUserId)
        .toSet()
        .toList();

    if (collaboratorIds.isEmpty) {
      if (!mounted) return;
      setState(() {
        _collaborators = [];
        _selectedCollaboratorId = null;
      });
      return;
    }

    final authRepository = context.read<AuthRepository>();
    final fetchedCollaborators = <UserModel>[];

    for (final id in collaboratorIds) {
      try {
        final user = await authRepository.getUserById(id);
        if (user != null) {
          fetchedCollaborators.add(user);
        }
      } catch (e) {
        debugPrint('Error fetching collaborator $id: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _collaborators = fetchedCollaborators;
      if (_selectedCollaboratorId != null &&
          !collaboratorIds.contains(_selectedCollaboratorId)) {
        _selectedCollaboratorId = null;
      }
    });
  }



  Widget _buildStatusChip(String label, PaperStatus? status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedStatusSet = null;
            _selectedStatus = selected ? status : null;
          });
        },
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }



  int get _activeAdvancedFiltersCount {
    var count = 0;
    if (_selectedPriority != null) count++;
    if (_selectedSharing != _SharingFilter.all) count++;
    if (_selectedCollaboratorId != null) count++;
    return count;
  }

  Widget _buildActiveFiltersBadges() {
    final activePriority = _selectedPriority;
    final activeSharing = _selectedSharing;
    final activeColleagueId = _selectedCollaboratorId;

    if (activePriority == null &&
        activeSharing == _SharingFilter.all &&
        activeColleagueId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (activePriority != null)
            _buildDismissibleBadge(
              label: 'Priority: ${activePriority.name.toUpperCase()}',
              onDismiss: () => setState(() => _selectedPriority = null),
            ),
          if (activeSharing != _SharingFilter.all)
            _buildDismissibleBadge(
              label: 'Sharing: ${activeSharing.label}',
              onDismiss: () => setState(() => _selectedSharing = _SharingFilter.all),
            ),
          if (activeColleagueId != null)
            _buildDismissibleBadge(
              label: 'Colleague: ${_getColleagueName(activeColleagueId)}',
              onDismiss: () => setState(() => _selectedCollaboratorId = null),
            ),
        ],
      ),
    );
  }

  String _getColleagueName(String id) {
    final c = _collaborators.firstWhere((col) => col.uid == id, orElse: () => UserModel(uid: '', email: '', displayName: 'Unknown', photoUrl: '', createdAt: DateTime.now()));
    return c.displayName.isNotEmpty ? c.displayName : c.email;
  }

  Widget _buildDismissibleBadge({required String label, required VoidCallback onDismiss}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onDismiss();
            },
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter Papers',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedPriority = null;
                                _selectedSharing = _SharingFilter.all;
                                _selectedCollaboratorId = null;
                              });
                              setState(() {});
                            },
                            child: const Text('Reset All'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      const Text(
                        'Priority',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildSheetPriorityChip(setSheetState, '🔴 High', PaperPriority.high),
                          _buildSheetPriorityChip(setSheetState, '🟡 Medium', PaperPriority.medium),
                          _buildSheetPriorityChip(setSheetState, '🟢 Low', PaperPriority.low),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Sharing Status',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _SharingFilter.values.map((filter) {
                          final isSelected = _selectedSharing == filter;
                          return ChoiceChip(
                            label: Text(filter.label, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) _selectedSharing = filter;
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      if (_collaborators.isNotEmpty) ...[
                        const Text(
                          'Collaborator',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String?>(
                          initialValue: _selectedCollaboratorId,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Any Colleague', style: TextStyle(fontSize: 13)),
                            ),
                            ..._collaborators.map((c) {
                              final name = c.displayName.isNotEmpty ? c.displayName : c.email;
                              return DropdownMenuItem<String?>(
                                value: c.uid,
                                child: Text(name, style: const TextStyle(fontSize: 13)),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setSheetState(() {
                              _selectedCollaboratorId = val;
                            });
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 30),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSheetPriorityChip(StateSetter setSheetState, String label, PaperPriority priority) {
    final isSelected = _selectedPriority == priority;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setSheetState(() {
          _selectedPriority = selected ? priority : null;
        });
        setState(() {});
      },
    );
  }

  Widget _buildKanbanBoard(List<Paper> papers) {
    // Group papers by key status groups
    final kanbanColumns = <String, List<PaperStatus>>{
      '💡 Ideas & Drafting': [PaperStatus.idea, PaperStatus.drafting],
      '✍️ Writing & Review': [PaperStatus.writing, PaperStatus.internalReview],
      '📤 Submitted': [PaperStatus.submitted, PaperStatus.underReview],
      '📝 Revisions': [PaperStatus.revision],
      '🏆 Published': [PaperStatus.published, PaperStatus.accepted],
    };

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: kanbanColumns.entries.map((col) {
        final title = col.key;
        final statuses = col.value;
        final colPapers = papers.where((p) => statuses.contains(p.status)).toList();

        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${colPapers.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Paper cards in column
              Expanded(
                child: colPapers.isEmpty
                    ? Center(
                        child: Text(
                          'No papers in stage',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: colPapers.length,
                        itemBuilder: (context, idx) {
                          final paper = colPapers[idx];
                          return PaperCard(
                            paper: paper,
                            onTap: () => context.push('/papers/${paper.id}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AnimatedPaperCard extends StatelessWidget {
  final Widget child;
  final int index;

  const _AnimatedPaperCard({
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Use TweenAnimationBuilder instead of AnimationController per item.
    // Stagger is achieved by increasing duration with index.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 375 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

