import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await context.read<AuthRepository>().updateDisplayName(newName);
      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Display name updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authState.user;
          final displayName = user.displayName ?? 'Researcher';
          final email = user.email ?? '';
          final initial =
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'R';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 16),

              // Avatar
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Display name (editable)
              if (_isEditingName)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'Enter your name',
                        ),
                        onSubmitted: (_) => _saveDisplayName(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isSaving)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      IconButton(
                        onPressed: _saveDisplayName,
                        icon: const Icon(Icons.check,
                            color: AppTheme.successColor),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditingName = false;
                            _nameController.text = displayName;
                          });
                        },
                        icon: const Icon(Icons.close,
                            color: AppTheme.errorColor),
                      ),
                    ],
                  ],
                )
              else
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isEditingName = true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            size: 16, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),

              // Email
              Center(
                child: Text(
                  email,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Stats row
              _buildStatsRow(),
              const SizedBox(height: 32),

              // Account section
              _buildSectionTitle('Account'),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Display Name',
                subtitle: displayName,
                onTap: () => setState(() => _isEditingName = true),
              ),
              _buildSettingsTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: email,
              ),
              _buildSettingsTile(
                icon: Icons.calendar_today_outlined,
                title: 'Member Since',
                subtitle: user.metadata.creationTime != null
                    ? DateFormat('MMMM yyyy')
                        .format(user.metadata.creationTime!)
                    : 'Unknown',
              ),
              const SizedBox(height: 32),

              // About section
              _buildSectionTitle('About'),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              const SizedBox(height: 40),

              // Sign out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                            'Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context
                                  .read<AuthBloc>()
                                  .add(AuthLogoutRequested());
                            },
                            child: const Text('Sign Out',
                                style: TextStyle(color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.errorColor),
                  label: const Text('Sign Out',
                      style: TextStyle(color: AppTheme.errorColor)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return BlocBuilder<PaperBloc, PaperState>(
      builder: (context, state) {
        int totalPapers = 0;
        int totalInProgress = 0;
        int totalPublished = 0;

        if (state is PapersLoaded) {
          totalPapers = state.papers.length;
          totalInProgress = state.papers
              .where((p) =>
                  p.status == PaperStatus.drafting ||
                  p.status == PaperStatus.writing ||
                  p.status == PaperStatus.internalReview ||
                  p.status == PaperStatus.revision)
              .length;
          totalPublished = state.papers
              .where((p) => p.status == PaperStatus.published)
              .length;
        }

        return Row(
          children: [
            _buildStatItem('Papers', '$totalPapers', AppTheme.primaryColor),
            _buildStatDivider(),
            _buildStatItem(
                'In Progress', '$totalInProgress', AppTheme.accentColor),
            _buildStatDivider(),
            _buildStatItem(
                'Published', '$totalPublished', AppTheme.successColor),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.dividerColor.withOpacity(0.3),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted)
            : null,
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
