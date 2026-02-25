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

class PapersListScreen extends StatefulWidget {
  const PapersListScreen({super.key});

  @override
  State<PapersListScreen> createState() => _PapersListScreenState();
}

class _PapersListScreenState extends State<PapersListScreen> {
  PaperStatus? _selectedStatus;
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

  List<Paper> _filterPapers(List<Paper> papers) {
    var filtered = papers;
    if (_selectedStatus != null) {
      filtered =
          filtered.where((p) => p.status == _selectedStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.targetVenue
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Papers'),
      ),
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
                hintText: 'Search papers...',
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
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', null),
                ...PaperStatus.values.map(
                  (status) => _buildFilterChip(
                    '${status.emoji} ${status.label}',
                    status,
                  ),
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
                  final filtered = _filterPapers(state.papers);
                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.article_outlined,
                      title: state.papers.isEmpty
                          ? 'No papers yet'
                          : 'No matching papers',
                      subtitle: state.papers.isEmpty
                          ? 'Tap + to add your first paper'
                          : 'Try a different filter',
                      action: state.papers.isEmpty
                          ? ElevatedButton.icon(
                              onPressed: () => context.push('/papers/add'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Paper'),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _loadPapers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final paper = filtered[index];
                        return PaperCard(
                          paper: paper,
                          onTap: () => context.push('/papers/${paper.id}'),
                        );
                      },
                    ),
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

  Widget _buildFilterChip(String label, PaperStatus? status) {
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
      ),
    );
  }
}
