import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_event.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/orcid/orcid_record.dart';
import 'package:paper_tracker/models/orcid/orcid_work.dart';
import 'package:paper_tracker/screens/academic_profile/orcid_auth_webview.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';
import 'package:paper_tracker/widgets/academic/stat_card.dart';
import 'package:paper_tracker/widgets/academic/interest_chip.dart';
import 'package:paper_tracker/widgets/academic/external_profile_button.dart';
import 'package:paper_tracker/widgets/academic/shimmer_loading.dart';

class AcademicProfileScreen extends StatefulWidget {
  final String orcidId;
  final bool initialRefresh;

  const AcademicProfileScreen({
    super.key,
    required this.orcidId,
    this.initialRefresh = false,
  });

  @override
  State<AcademicProfileScreen> createState() => _AcademicProfileScreenState();
}

class _AcademicProfileScreenState extends State<AcademicProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AcademicProfileBloc>().add(
          AcademicProfileLoadRequested(
            widget.orcidId,
            forceRefresh: widget.initialRefresh,
          ),
        );
  }

  Future<void> _startAuth([String? orcidId]) async {
    final authRequest = OrcidAuthService.prepareAuthorization();
    if (!mounted) return;
    final result = await Navigator.push<OrcidAuthResult>(
      context,
      MaterialPageRoute(
        builder: (_) => OrcidAuthWebView(authRequest: authRequest),
      ),
    );
    if (result == null || !mounted) return;
    if (result.isSuccess && result.token != null) {
      context.read<AcademicProfileBloc>().add(
            AcademicProfileLoadRequested(
              result.token!.orcidId,
              forceRefresh: true,
            ),
          );
    } else {
      context.read<AcademicProfileBloc>().add(
            CheckOrcidAuthorization(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Authorization failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AcademicProfileBloc, AcademicProfileState>(
        builder: (context, state) {
          if (state is AcademicProfileLoading) {
            return const ProfileShimmer();
          }
          if (state is AcademicProfileAuthorizing) {
            return _buildAuthorizing(context);
          }
          if (state is AcademicProfileError) {
            return _buildError(context, state);
          }
          if (state is AcademicProfileAuthorizationError) {
            return _buildAuthError(context, state);
          }
          if (state is AcademicProfileNotAuthorized) {
            return _buildNotAuthorized(context, state);
          }
          if (state is AcademicProfileLoaded) {
            return _buildProfile(context, state);
          }
          return _buildEmpty(context);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, AcademicProfileError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context
                  .read<AcademicProfileBloc>()
                  .add(AcademicProfileLoadRequested(widget.orcidId, forceRefresh: true)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizing(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            'Authorizing with ORCID...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A browser window will open for you to sign in.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthorized(BuildContext context, AcademicProfileNotAuthorized state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'ORCID account not connected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            if (state.orcidId != null) ...[
              FilledButton.icon(
                onPressed: () => _startAuth(state.orcidId!),
                icon: const Icon(Icons.link),
                label: const Text('Connect ORCID'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthError(BuildContext context, AcademicProfileAuthorizationError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _startAuth(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(height: 16),
          Text(
            'Enter an ORCID iD to get started',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AcademicProfileLoaded state) {
    final record = state.record;
    final person = record.person;

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<AcademicProfileBloc>()
            .add(AcademicProfileRefreshRequested(widget.orcidId));
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + Name Header
          _buildHeader(context, record),
          const SizedBox(height: 24),

          // Stats Grid
          _buildStatsGrid(context, record),
          const SizedBox(height: 24),

          // Publication Distribution Chart
          _buildPublicationChart(context, record),
          const SizedBox(height: 24),

          // Biography
          if (person.biography.isNotEmpty) ...[
            _buildSectionTitle(context, 'Biography'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).cardColor.withValues(alpha: 0.85),
                    Theme.of(context).cardColor.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Text(
                person.biography,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Recent Publications Preview
          if (record.works.isNotEmpty) ...[
            _buildRecentPublications(context, record),
            const SizedBox(height: 24),
          ],

          // Research Interests
          if (person.keywords.isNotEmpty) ...[
            _buildSectionTitle(context, 'Research Interests'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: person.keywords.map((k) {
                final colors = [
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                  AppTheme.warningColor,
                  AppTheme.successColor,
                  const Color(0xFF7C4DFF),
                  const Color(0xFFFF6D00),
                ];
                final idx = person.keywords.indexOf(k) % colors.length;
                return InterestChip(label: k, color: colors[idx]);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // External Profiles
          _buildSectionTitle(context, 'External Profiles'),
          const SizedBox(height: 12),
          ExternalProfileButton(
            label: 'ORCID Profile',
            icon: Icons.fingerprint,
            url: 'https://orcid.org/${record.orcidId}',
            color: const Color(0xFFA6CE39),
          ),
          if (person.websites.isNotEmpty || person.externalIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...person.websites.map((w) => ExternalProfileButton(
                  label: w,
                  icon: Icons.language,
                  url: w,
                  color: AppTheme.primaryColor,
                )),
            if (person.externalIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...person.externalIds.map((id) => ExternalProfileButton(
                    label: 'Researcher ID: $id',
                    icon: Icons.badge_outlined,
                    url: 'https://orcid.org/${record.orcidId}', // link back to ORCID profile for verification
                    color: Theme.of(context).colorScheme.secondary,
                  )),
            ],
          ],
          const SizedBox(height: 24),

          // Quick links to sections
          _buildQuickLinks(context, record),
          const SizedBox(height: 24),

          // Recently updated
          Text(
            'Last updated: ${_formatDate(state.lastUpdated)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OrcidRecord record) {
    final person = record.person;
    final initials = person.name.givenNames.isNotEmpty
        ? '${person.name.givenNames[0]}${person.name.familyName.isNotEmpty ? person.name.familyName[0] : ''}'
        : '?';

    return Column(
      children: [
        Hero(
          tag: 'academic-avatar',
          child: CircleAvatar(
            radius: 44,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              initials.toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          person.name.displayName.isNotEmpty
              ? person.name.displayName
              : '${person.name.givenNames} ${person.name.familyName}'.trim(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFA6CE39).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 14, color: Color(0xFFA6CE39)),
              const SizedBox(width: 4),
              Text(
                'ORCID iD: ${record.orcidId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA6CE39),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (person.country.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(
                person.country,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, OrcidRecord record) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final crossAxisCount = isMobile ? 2 : 4;
    final aspectRatio = isMobile ? 1.25 : 1.4;
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        StatCard(
          label: 'Publications',
          value: '${record.publicationCount}',
          icon: Icons.article,
          color: AppTheme.primaryColor,
        ),
        StatCard(
          label: 'Employment',
          value: '${record.employmentCount}',
          icon: Icons.work,
          color: AppTheme.accentColor,
        ),
        StatCard(
          label: 'Education',
          value: '${record.educationCount}',
          icon: Icons.school,
          color: AppTheme.warningColor,
        ),
        StatCard(
          label: 'Funding',
          value: '${record.fundingCount}',
          icon: Icons.account_balance,
          color: AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildQuickLinks(BuildContext context, OrcidRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Sections'),
        const SizedBox(height: 12),
        if (record.works.isNotEmpty)
          _buildQuickLink(
            context,
            icon: Icons.article,
            label: 'Publications (${record.works.length})',
            onTap: () => context.push('/academic-profile/publications'),
          ),
        if (record.employments.isNotEmpty)
          _buildQuickLink(
            context,
            icon: Icons.work,
            label: 'Employment (${record.employments.length})',
            onTap: () => context.push('/academic-profile/employment'),
          ),
        if (record.educations.isNotEmpty)
          _buildQuickLink(
            context,
            icon: Icons.school,
            label: 'Education (${record.educations.length})',
            onTap: () => context.push('/academic-profile/education'),
          ),
        if (record.fundings.isNotEmpty)
          _buildQuickLink(
            context,
            icon: Icons.account_balance,
            label: 'Funding (${record.fundings.length})',
            onTap: () => context.push('/academic-profile/funding'),
          ),
      ],
    );
  }

  Widget _buildQuickLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(label, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPublicationChart(BuildContext context, OrcidRecord record) {
    if (record.works.isEmpty) return const SizedBox.shrink();

    final typeCounts = <String, int>{};
    for (final work in record.works) {
      final type = work.type.replaceAll('-', ' ').toLowerCase();
      final formattedType = type.split(' ').map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.substring(1)}';
      }).join(' ');
      typeCounts[formattedType] = (typeCounts[formattedType] ?? 0) + 1;
    }

    final total = record.works.length;
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.85),
            cardColor.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insert_chart_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              _buildSectionTitle(context, 'Publication Distribution'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: List.generate(sortedTypes.length, (index) {
                  final entry = sortedTypes[index];
                  final percentage = entry.value / total;
                  final color = colors[index % colors.length];
                  final flexValue = (percentage * 100).round();
                  return Expanded(
                    flex: flexValue > 0 ? flexValue : 1,
                    child: Container(
                      color: color,
                      height: 12,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(sortedTypes.length, (index) {
            final entry = sortedTypes[index];
            final count = entry.value;
            final percentage = (count / total * 100).toStringAsFixed(0);
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '$count ($percentage%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentPublications(BuildContext context, OrcidRecord record) {
    if (record.works.isEmpty) return const SizedBox.shrink();

    final sortedWorks = List<OrcidWork>.from(record.works)
      ..sort((a, b) => b.publicationYear.compareTo(a.publicationYear));

    final recentWorks = sortedWorks.take(3).toList();
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_edu, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            _buildSectionTitle(context, 'Recent Publications'),
          ],
        ),
        const SizedBox(height: 12),
        ...recentWorks.map((work) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor.withValues(alpha: 0.85),
                  cardColor.withValues(alpha: 0.4),
                ],
              ),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
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
                const SizedBox(height: 6),
                if (work.journalTitle.isNotEmpty)
                  Text(
                    work.journalTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (work.publicationYear > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${work.publicationYear}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (work.type.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          work.type.replaceAll('-', ' '),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.secondary,
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
                          color: theme.colorScheme.primary,
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
        }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
