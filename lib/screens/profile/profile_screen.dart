import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_event.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/paper/paper_bloc.dart';
import 'package:paper_tracker/blocs/paper/paper_event.dart';
import 'package:paper_tracker/blocs/paper/paper_state.dart';
import 'package:paper_tracker/blocs/theme/theme_cubit.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/config/theme_preset.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_event.dart';
import 'package:paper_tracker/screens/academic_profile/orcid_auth_webview.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';
import 'package:paper_tracker/utils/notification_prefs.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSaving = false;
  String _appVersion = '1.0.0';
  String _orcidId = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadOrcid();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.displayName ?? '';
      
      final paperState = context.read<PaperBloc>().state;
      if (paperState is! PapersLoaded) {
        context.read<PaperBloc>().add(PapersLoadRequested(authState.user.uid));
      }
    }
  }

  Future<void> _loadOrcid() async {
    final authRepo = context.read<AuthRepository>();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = await authRepo.getUserById(authState.user.uid);
      if (mounted) {
        setState(() => _orcidId = user?.orcidId ?? '');
      }
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error loading app version: $e');
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
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                        Icon(Icons.edit_outlined,
                            size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
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
                     color: Theme.of(context).textTheme.bodySmall?.color,
                     fontSize: 14,
                   ),
                ),
              ),
              const SizedBox(height: 32),

              // Stats row
              _buildStatsRow(),
              const SizedBox(height: 32),

              // Appearance section
              _buildSectionTitle('Appearance'),
              const SizedBox(height: 12),
              _buildThemeSelector(),
              const SizedBox(height: 32),

              // Accent Color section
              _buildSectionTitle('Accent Color'),
              const SizedBox(height: 12),
              _buildAccentColorPicker(),
              const SizedBox(height: 32),

              // Notification Preferences section
              _buildSectionTitle('Notification Preferences'),
              const SizedBox(height: 12),
              _buildNotificationPrefs(),
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
              _buildOrcidTile(displayName),
              const SizedBox(height: 32),

              // About section
              _buildSectionTitle('About'),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: _appVersion,
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
               color: Theme.of(context).textTheme.bodySmall?.color,
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
       color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
       style: TextStyle(
         fontSize: 13,
         fontWeight: FontWeight.w600,
         color: Theme.of(context).textTheme.bodySmall?.color,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        trailing: onTap != null
            ? Icon(Icons.chevron_right, size: 20, color: Theme.of(context).textTheme.bodySmall?.color)
            : null,
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildOrcidTile(String displayName) {
    final orcidId = _orcidId;
    final isConnected = orcidId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.badge_outlined,
                color: isConnected
                    ? AppTheme.successColor
                    : Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              title: Text(
                isConnected ? 'ORCID Connected' : 'Connect ORCID',
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                isConnected ? orcidId : 'Link your ORCID iD',
                style: TextStyle(
                  fontSize: 12,
                  color: isConnected
                      ? AppTheme.successColor
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  isConnected ? Icons.link_off : Icons.add_link,
                  size: 20,
                ),
                color: isConnected
                    ? AppTheme.errorColor
                    : Theme.of(context).colorScheme.primary,
                onPressed: () => _handleOrcid(isConnected, displayName),
              ),
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (isConnected)
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 8, bottom: 8),
              child: TextButton.icon(
                onPressed: () => context.push('/academic-profile', extra: orcidId),
                icon: const Icon(Icons.school, size: 16),
                label: const Text('Open Academic Profile', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleOrcid(bool isConnected, String displayName) async {
    final authRepo = context.read<AuthRepository>();
    if (isConnected) {
      await OrcidAuthService.disconnect();
      await authRepo.updateOrcidId('');
      context.read<AcademicProfileBloc>().add(const OrcidDisconnectRequested());
      setState(() => _orcidId = '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ORCID disconnected'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await _authorizeOrcid();
    }
  }

  Future<void> _authorizeOrcid() async {
    final authRepo = context.read<AuthRepository>();
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
      final orcidId = result.token!.orcidId;
      await authRepo.updateOrcidId(orcidId);
      setState(() => _orcidId = orcidId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ORCID authorized — ${result.token!.name ?? orcidId}'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        final msg = result.error ?? 'ORCID authorization failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildAccentColorPicker() {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final currentAccent = state.customAccentValue;
        final defaultAccent = state.preset.accentColor;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in _accentColors)
                    GestureDetector(
                      onTap: () => context
                          .read<ThemeCubit>()
                          .updateAccentColor(color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentAccent == color.toARGB32()
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: currentAccent == color.toARGB32()
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: currentAccent == color.toARGB32()
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (currentAccent != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => context
                        .read<ThemeCubit>()
                        .updateAccentColor(null),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset to theme default'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else
                Text(
                  'Using default: ${_colorName(defaultAccent)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _colorName(Color c) {
    final i = _accentColors.indexWhere(
        (e) => e.toARGB32() == c.toARGB32());
    return i >= 0 ? _accentColorNames[i] : 'custom';
  }

  Widget _buildNotificationPrefs() {
    return FutureBuilder<Map<NotificationType, bool>>(
      future: NotificationPrefs.getAll(),
      builder: (context, snapshot) {
        final prefs = snapshot.data ?? {};
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: NotificationType.values.map((type) {
              final enabled = prefs[type] ?? true;
              final iconData = _notificationIcon(type);
              final color = _notificationColor(type);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        type.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: enabled,
                      activeColor: color,
                      onChanged: (value) {
                        NotificationPrefs.setEnabled(type, value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _notificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.collaboratorAdded:
        return Icons.person_add_rounded;
      case NotificationType.commentAdded:
        return Icons.chat_bubble_rounded;
      case NotificationType.taskAssigned:
        return Icons.assignment_ind_rounded;
      case NotificationType.taskCompleted:
        return Icons.task_alt_rounded;
      case NotificationType.statusChanged:
        return Icons.swap_horiz_rounded;
      case NotificationType.paperCreated:
        return Icons.note_add_rounded;
      case NotificationType.paperModified:
        return Icons.edit_note_rounded;
    }
  }

  Color _notificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.collaboratorAdded:
        return AppTheme.accentColor;
      case NotificationType.commentAdded:
        return AppTheme.primaryColor;
      case NotificationType.taskAssigned:
        return AppTheme.warningColor;
      case NotificationType.taskCompleted:
        return AppTheme.successColor;
      case NotificationType.statusChanged:
        return const Color(0xFFF97316);
      case NotificationType.paperCreated:
        return AppTheme.successColor;
      case NotificationType.paperModified:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildThemeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final primaryColor = Theme.of(context).colorScheme.primary;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, color: primaryColor, size: 22),
                  const SizedBox(width: 16),
                  const Text('Color Theme', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ThemePreset.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final preset = ThemePreset.values[index];
                    final isSelected = state.preset == preset;
                    return GestureDetector(
                      onTap: () => context
                          .read<ThemeCubit>()
                          .updateThemePreset(preset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? preset.primaryColor.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? preset.primaryColor
                                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: preset.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: preset.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preset.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? preset.primaryColor
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.brightness_6_outlined,
                      color: primaryColor, size: 22),
                  const SizedBox(width: 16),
                  const Text('Brightness', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                ],
                selected: {state.mode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  context
                      .read<ThemeCubit>()
                      .updateThemeMode(newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return primaryColor.withValues(alpha: 0.2);
                      }
                      return Colors.transparent;
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const List<Color> _accentColors = [
  Color(0xFF00D9FF),
  Color(0xFF6EE7B7),
  Color(0xFFFBBF24),
  Color(0xFF38BDF8),
  Color(0xFFF472B6),
  Color(0xFFA78BFA),
  Color(0xFF34D399),
  Color(0xFFFB923C),
  Color(0xFFF87171),
  Color(0xFF818CF8),
];

const List<String> _accentColorNames = [
  'Cyan',
  'Emerald',
  'Amber',
  'Sky Blue',
  'Pink',
  'Violet',
  'Green',
  'Orange',
  'Red',
  'Indigo',
];

