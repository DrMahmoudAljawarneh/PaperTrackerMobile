import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:paper_tracker/config/orcid_config.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

/// Starts the ORCID authorization flow.
///
/// On mobile/desktop the flow runs inside an embedded [OrcidAuthWebView] and
/// returns the [OrcidAuthResult] (or null if the user cancelled).
///
/// On web the current tab is redirected to ORCID; the result is delivered
/// later via [OrcidCallbackScreen] after the redirect back, so this returns
/// null immediately.
Future<OrcidAuthResult?> startOrcidAuth(BuildContext context) async {
  if (kIsWeb) {
    // ORCID blocks browser-side code exchange (CORS), so web uses the
    // implicit flow: the token is returned in the redirect URL fragment and
    // handled by OrcidCallbackScreen after the redirect back.
    final url = await OrcidAuthService.buildWebAuthorizationUrl();
    await launchUrl(
      Uri.parse(url),
      webOnlyWindowName: '_self',
    );
    return null;
  }

  final authRequest = OrcidAuthService.prepareAuthorization();

  return Navigator.push<OrcidAuthResult>(
    context,
    MaterialPageRoute(
      builder: (_) => OrcidAuthWebView(authRequest: authRequest),
    ),
  );
}

class OrcidAuthWebView extends StatefulWidget {
  final AuthorizationRequest authRequest;

  const OrcidAuthWebView({super.key, required this.authRequest});

  @override
  State<OrcidAuthWebView> createState() => _OrcidAuthWebViewState();
}

class _OrcidAuthWebViewState extends State<OrcidAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted && !_isDone) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted && !_isDone) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            if (_isDone) return NavigationDecision.prevent;

            if (request.url.startsWith(OrcidConfig.redirectUri)) {
              _isDone = true;
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (!mounted || _isDone) return;
            if (error.isForMainFrame == true) {
              setState(() {
                _error = error.description.isNotEmpty
                    ? error.description
                    : 'Failed to load authorization page.';
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authRequest.url));
  }

  Future<void> _handleRedirect(String redirectUrl) async {
    final result = await OrcidAuthService.completeAuthorization(
      redirectUrl,
      widget.authRequest,
    );

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORCID Authorization'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(
            context,
            OrcidAuthResult(error: 'Authorization cancelled.'),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _controller.loadRequest(
                            Uri.parse(widget.authRequest.url));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                if (_isLoading)
                  const LinearProgressIndicator(),
                Expanded(
                  child: WebViewWidget(controller: _controller),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
