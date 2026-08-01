import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

/// Handles the ORCID OAuth redirect back to the web app.
///
/// ORCID redirects the browser to
/// `https://papercheck-2026.web.app/callback?code=...&state=...`. This screen
/// exchanges the code for a token and then navigates to the academic profile
/// once the user's sign-in session has been restored.
class OrcidCallbackScreen extends StatefulWidget {
  const OrcidCallbackScreen({super.key});

  @override
  State<OrcidCallbackScreen> createState() => _OrcidCallbackScreenState();
}

class _OrcidCallbackScreenState extends State<OrcidCallbackScreen> {
  String? _orcidId;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      final uri = Uri.base;
      debugPrint('ORCID callback URL: ${uri.toString()}');
      // Implicit flow delivers the token in the URL fragment; keep query-param
      // handling too in case ORCID ever switches the delivery style.
      final fragment = uri.fragment.isNotEmpty
          ? Uri.splitQueryString(uri.fragment)
          : const <String, String>{};
      final query = uri.queryParameters;

      final hasToken = fragment['access_token'] != null ||
          query['access_token'] != null;
      final hasCode = fragment['code'] != null || query['code'] != null;
      final hasError = fragment['error'] != null || query['error'] != null;

      if (!hasToken && !hasCode && !hasError) {
        // Not a real callback (e.g. user opened /callback directly).
        if (!mounted) return;
        context.go('/academic-profile');
        return;
      }

      final result = await OrcidAuthService.completeWebCallback(uri.toString());
      if (!mounted) return;
      _onResult(result);
    } catch (e) {
      debugPrint('ORCID callback error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Authorization failed: $e';
      });
    }
  }

  void _onResult(OrcidAuthResult result) {
    if (result.isSuccess && result.token != null) {
      _orcidId = result.token!.orcidId;
      if (context.read<AuthBloc>().state is AuthAuthenticated) {
        context.go('/academic-profile', extra: _orcidId);
        return;
      }
      // Wait for AuthCheckRequested to restore the session before navigating.
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = false;
      _error = result.error ?? 'Authorization failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_orcidId != null && state is AuthAuthenticated) {
          context.go('/academic-profile', extra: _orcidId);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('ORCID Authorization')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _isLoading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Completing authorization...'),
                    ],
                  )
                : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () =>
                                context.go('/academic-profile'),
                            child:
                                const Text('Back to Academic Profile'),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Restoring your session...'),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
