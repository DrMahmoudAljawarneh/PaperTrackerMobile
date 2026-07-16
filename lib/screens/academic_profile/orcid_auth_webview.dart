import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:paper_tracker/config/orcid_config.dart';
import 'package:paper_tracker/services/orcid_auth_service.dart';

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
