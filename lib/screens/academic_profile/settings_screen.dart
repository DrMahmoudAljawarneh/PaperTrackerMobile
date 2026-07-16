import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_bloc.dart';
import 'package:paper_tracker/blocs/academic_profile/academic_profile_event.dart';
import 'package:paper_tracker/screens/academic_profile/orcid_auth_webview.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

class AcademicSettingsScreen extends StatefulWidget {
  final String currentOrcidId;

  const AcademicSettingsScreen({super.key, required this.currentOrcidId});

  @override
  State<AcademicSettingsScreen> createState() => _AcademicSettingsScreenState();
}

class _AcademicSettingsScreenState extends State<AcademicSettingsScreen> {
  late TextEditingController _orcidController;
  bool _isAuthorized = false;
  String? _orcidName;

  @override
  void initState() {
    super.initState();
    _orcidController = TextEditingController(text: widget.currentOrcidId);
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    final token = await OrcidAuthService.getStoredToken();
    if (mounted) {
      setState(() {
        _isAuthorized = token != null && !token.isExpired;
        _orcidName = token?.name;
      });
    }
  }

  @override
  void dispose() {
    _orcidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Profile Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Authorization Status
          Text(
            'ORCID Authorization',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                _isAuthorized ? Icons.link : Icons.link_off,
                color: _isAuthorized ? Colors.green : Colors.grey,
              ),
              title: Text(
                _isAuthorized ? 'ORCID Connected' : 'Not Connected',
              ),
              subtitle: Text(
                _isAuthorized
                    ? (_orcidName ?? 'Authorized with ORCID')
                    : 'Authorize to view complete profile data',
              ),
              trailing: _isAuthorized
                  ? TextButton(
                      onPressed: _confirmDisconnect,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout, size: 16),
                          SizedBox(width: 4),
                          Text('Disconnect', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          if (!_isAuthorized) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _startAuth(),
              icon: const Icon(Icons.link),
              label: const Text('Authorize with ORCID'),
            ),
          ],
          const SizedBox(height: 24),

          // ORCID ID
          Text(
            'ORCID iD',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _orcidController,
            decoration: const InputDecoration(
              hintText: '0000-0002-1825-0097',
              prefixIcon: Icon(Icons.fingerprint),
              border: OutlineInputBorder(),
              helperText: 'Format: 0000-0000-0000-0000',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saveOrcidId,
            icon: const Icon(Icons.check),
            label: const Text('Save & Reload'),
          ),
          const SizedBox(height: 32),

          // Cache
          Text(
            'Cache',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Cache'),
              subtitle: const Text('Remove cached ORCID data'),
              onTap: () {
                context.read<AcademicProfileBloc>().add(const AcademicProfileClearCache());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Now'),
              subtitle: const Text('Fetch latest data from ORCID'),
              onTap: () {
                context.read<AcademicProfileBloc>().add(
                      AcademicProfileRefreshRequested(_orcidController.text.trim()),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing...')),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Info
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAuthorized
                        ? 'Data is fetched from the ORCID Member API using your authorized access token, showing both public and private entries.'
                        : 'Data is fetched from the ORCID Public API and shows only public entries. Authorize to see complete details.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Citations and author metrics are sourced from OpenAlex and Semantic Scholar where available.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startAuth() async {
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
      await OrcidAuthService.disconnect();
      await OrcidAuthService.saveToken(result.token!);
      setState(() {
        _isAuthorized = true;
        _orcidName = result.token!.name;
      });
      context.read<AcademicProfileBloc>().add(
            AcademicProfileLoadRequested(
              result.token!.orcidId,
              forceRefresh: true,
            ),
          );
      Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Authorization failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveOrcidId() async {
    final orcidId = _orcidController.text.trim();
    if (orcidId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('academic_orcid_id', orcidId);

    context.read<AcademicProfileBloc>().add(
          AcademicProfileLoadRequested(orcidId, forceRefresh: true),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ORCID iD saved. Loading profile...')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect ORCID?'),
        content: const Text(
          'This will remove your ORCID authorization token. '
          'You can reconnect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await OrcidAuthService.disconnect();
      context.read<AcademicProfileBloc>().add(const OrcidDisconnectRequested());
      setState(() {
        _isAuthorized = false;
        _orcidName = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ORCID disconnected')),
        );
        Navigator.pop(context);
      }
    }
  }
}
