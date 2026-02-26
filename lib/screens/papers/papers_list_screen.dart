import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/widgets/empty_state.dart';
import 'package:paper_tracker/widgets/paper_card.dart';

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

class PapersListScreen extends StatefulWidget {
  const PapersListScreen({super.key});

  @override
  State<PapersListScreen> createState() => _PapersListScreenState();
}

class _PapersListScreenState extends State<PapersListScreen> {
  PaperStatus? _selectedStatus;
  PaperPriority? _selectedPriority;
  _SortOption _sortOption = _SortOption.updated;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPapers();
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
    if (_selectedStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }

    // Priority filter
    if (_selectedPriority != null) {
      filtered =
          filtered.where((p) => p.priority == _selectedPriority).toList();
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
        onPressed: () => context.push('/papers/add'),
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
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.dividerColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_sortOption.icon,
                            size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            size: 16, color: AppTheme.textMuted),
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
                                        ? AppTheme.primaryColor
                                        : AppTheme.textMuted),
                                const SizedBox(width: 8),
                                Text(opt.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: opt == _sortOption
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
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
            child: BlocBuilder<PaperBloc, PaperState>(
              builder: (context, state) {
                if (state is PaperLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_selectedStatus != null ||
                                  _selectedPriority != null ||
                                  _searchQuery.isNotEmpty) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStatus = null;
                                      _selectedPriority = null;
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                  child: Text(
                                    'Clear filters',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
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
                                    return PaperCard(
                                      paper: paper,
                                      onTap: () => context
                                          .push('/papers/${paper.id}'),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
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
          setState(() => _selectedStatus = selected ? status : null);
        },
        backgroundColor: AppTheme.cardColor,
        selectedColor: AppTheme.primaryColor.withOpacity(0.25),
        checkmarkColor: AppTheme.primaryColor,
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.5)
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
        onTap: () =>
            setState(() => _selectedPriority = isSelected ? null : priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentColor.withOpacity(0.2)
                : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentColor.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
