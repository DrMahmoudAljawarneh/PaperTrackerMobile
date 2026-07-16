import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_state.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/models/orcid/orcid_work.dart';

class PublicationsScreen extends StatefulWidget {
  const PublicationsScreen({super.key});

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  String _searchQuery = '';
  String _sortBy = 'year';
  String? _typeFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publications')),
      body: BlocBuilder<AcademicProfileBloc, AcademicProfileState>(
        builder: (context, state) {
          if (state is! AcademicProfileLoaded) {
            return const Center(child: Text('No data'));
          }

          var works = List<OrcidWork>.from(state.record.works);

          // Filter by type
          if (_typeFilter != null) {
            works = works.where((w) => w.type == _typeFilter).toList();
          }

          // Search
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            works = works
                .where((w) =>
                    w.title.toLowerCase().contains(q) ||
                    w.journalTitle.toLowerCase().contains(q))
                .toList();
          }

          // Sort
          if (_sortBy == 'year') {
            works.sort((a, b) => b.publicationYear.compareTo(a.publicationYear));
          } else if (_sortBy == 'title') {
            works.sort((a, b) => a.title.compareTo(b.title));
          }

          // Collect unique types for filter
          final allTypes = state.record.works.map((w) => w.type).toSet().toList()..sort();

          return Column(
            children: [
              // Search + Sort Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search publications...',
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
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All', null),
                    ...allTypes.map((t) => _buildFilterChip(t, t)),
                  ],
                ),
              ),
              // Sort toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${works.length} publication${works.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const Spacer(),
                    _buildSortButton(context, 'year', 'By Year'),
                    const SizedBox(width: 8),
                    _buildSortButton(context, 'title', 'A-Z'),
                  ],
                ),
              ),
              // List
              Expanded(
                child: works.isEmpty
                    ? Center(
                        child: Text(
                          'No publications found',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: works.length,
                        itemBuilder: (context, index) {
                          return _buildWorkCard(context, works[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => setState(() => _typeFilter = value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, String value, String label) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkCard(BuildContext context, OrcidWork work) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            work.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (work.journalTitle.isNotEmpty)
            Text(
              work.journalTitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (work.publicationYear > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${work.publicationYear}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (work.type.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    work.type.replaceAll('-', ' '),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (work.doi.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    launchUrl(
                      Uri.parse('https://doi.org/${work.doi}'),
                      mode: LaunchMode.inAppWebView,
                    );
                  },
                  tooltip: 'Open DOI',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
