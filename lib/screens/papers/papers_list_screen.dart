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
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Sharing filter chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._SharingFilter.values.map((filter) => _buildSharingChip(filter)),
                if (_collaborators.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Container(
                        width: 1,
                        height: 20,
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  _buildColleagueDropdownChip(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Status filter chips
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
          const SizedBox(height: 6),

          // Priority filter + Sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Priority chips
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPriorityChip('Any', null),
                        _buildPriorityChip('🔴 High', PaperPriority.high),
                        _buildPriorityChip('🟡 Medium', PaperPriority.medium),
                        _buildPriorityChip('🟢 Low', PaperPriority.low),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort dropdown
                PopupMenuButton<_SortOption>(
                  initialValue: _sortOption,
                  onSelected: (v) => setState(() => _sortOption = v),
                  tooltip: 'Sort by',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_sortOption.icon,
                            size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down,
                            size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
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
          const SizedBox(height: 8),

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
                                child: ListView.builder(
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

  Widget _buildSharingChip(_SharingFilter filter) {
    final isSelected = _selectedSharing == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter.label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          HapticFeedback.lightImpact();
          setState(() {
            if (selected) {
              _selectedSharing = filter;
            }
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

  Widget _buildColleagueDropdownChip() {
    final isSelected = _selectedCollaboratorId != null;
    final selectedColleague = _selectedCollaboratorId != null
        ? _collaborators.firstWhere(
            (c) => c.uid == _selectedCollaboratorId,
            orElse: () => UserModel(
              uid: '',
              email: '',
              displayName: 'Unknown',
              photoUrl: '',
              createdAt: DateTime.now(),
            ),
          )
        : null;

    final labelText = selectedColleague != null
        ? (selectedColleague.displayName.isNotEmpty
            ? selectedColleague.displayName
            : selectedColleague.email)
        : 'Any Colleague';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String?>(
        initialValue: _selectedCollaboratorId,
        onSelected: (colleagueId) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedCollaboratorId = colleagueId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Colleague: $labelText',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
        itemBuilder: (context) {
          return [
            PopupMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Text('Any Colleague', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
            ..._collaborators.map((c) {
              final name = c.displayName.isNotEmpty ? c.displayName : c.email;
              final isThisSelected = c.uid == _selectedCollaboratorId;
              return PopupMenuItem<String?>(
                value: c.uid,
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: isThisSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isThisSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isThisSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );
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

  Widget _buildPriorityChip(String label, PaperPriority? priority) {
    final isSelected = _selectedPriority == priority;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedPriority = isSelected ? null : priority);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
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

