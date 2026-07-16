import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_state.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/models/orcid/orcid_funding.dart';

class FundingScreen extends StatelessWidget {
  const FundingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Funding')),
      body: BlocBuilder<AcademicProfileBloc, AcademicProfileState>(
        builder: (context, state) {
          if (state is! AcademicProfileLoaded) {
            return const Center(child: Text('No data'));
          }

          final fundings = state.record.fundings;
          if (fundings.isEmpty) {
            return Center(
              child: Text(
                'No funding records',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: fundings.length,
            itemBuilder: (context, index) {
              return _FundingCard(funding: fundings[index]);
            },
          );
        },
      ),
    );
  }
}

class _FundingCard extends StatefulWidget {
  final OrcidFunding funding;

  const _FundingCard({required this.funding});

  @override
  State<_FundingCard> createState() => _FundingCardState();
}

class _FundingCardState extends State<_FundingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.funding;
    final dateFormat = DateFormat('MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance, size: 20, color: Color(0xFF2E7D32)),
            ),
            title: Text(
              f.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              f.organizationName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more, size: 20),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  _buildDetailRow(context, 'Type', f.type),
                  if (f.startDate != null)
                    _buildDetailRow(
                      context,
                      'Period',
                      '${dateFormat.format(f.startDate!)} - ${f.endDate != null ? dateFormat.format(f.endDate!) : 'Present'}',
                    ),
                  if (f.amount.isNotEmpty)
                    _buildDetailRow(context, 'Amount', f.amount),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
